defmodule ModelNameTalk.Room do
  @moduledoc """
  Who is here, what is open, and what has been answered.

  One round is open at a time and which one is decided by the slide on screen,
  so there is no second thing to remember while presenting. A round moves
  through three phases: open while answers are accepted, locked once the timer
  runs out or the speaker ends it early, and revealed once the answer is on the
  big screen.

  A participant is a token, not a process. The token lives in the phone's local
  storage, so a locked phone, a discarded background tab and a browser crash
  all come back as the same player with the same score. Processes are tracked
  underneath the token and only answer the question of how many people are
  connected right now.

  The room is allowed to be empty. Every figure that reads it renders correctly
  with no participants at all, because a talk where the network failed still
  has to be a talk.
  """

  use GenServer

  alias ModelNameTalk.{Ledger, Round, Scoring}
  alias Phoenix.PubSub

  @topic "room"

  defstruct position: {0, 1},
            round: nil,
            phase: :open,
            opened_at: nil,
            answers: %{},
            participants: %{},
            connections: %{}

  @type t :: %__MODULE__{}

  ## CLIENT

  def start_link(_options), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @spec subscribe() :: :ok
  def subscribe, do: PubSub.subscribe(ModelNameTalk.PubSub, @topic)

  @doc """
  Registers a phone under its token. The process is monitored, so closing a tab
  drops a connection, but the participant and their score stay.
  """
  @spec join(String.t(), String.t(), pid()) :: :ok
  def join(token, handle, pid), do: GenServer.call(__MODULE__, {:join, token, handle, pid})

  @spec state() :: t()
  def state, do: GenServer.call(__MODULE__, :state)

  @doc "Forgets everything, including who is here. For rehearsals and tests."
  @spec reset() :: :ok
  def reset, do: GenServer.call(__MODULE__, :reset)

  @doc """
  Remembers where the deck is.

  A window that arrives in the middle of a talk, or one the speaker reloads
  because something looks stuck, has to come back where the room already is.
  Broadcasting a move is not enough on its own: nobody is listening yet.
  """
  @spec move({non_neg_integer(), pos_integer()}) :: :ok
  def move(position), do: GenServer.call(__MODULE__, {:move, position})

  @doc "Where the deck is."
  @spec position() :: {non_neg_integer(), pos_integer()}
  def position, do: state().position

  @doc "How many people are playing, connected or not."
  @spec participant_count(t()) :: non_neg_integer()
  def participant_count(%__MODULE__{participants: participants}), do: map_size(participants)

  @doc "How many browser tabs are open right now."
  @spec connected_count(t()) :: non_neg_integer()
  def connected_count(%__MODULE__{connections: connections}), do: map_size(connections)

  @doc "Opens a round, or closes whatever is open when given nil."
  @spec open(atom() | nil) :: :ok
  def open(identifier), do: GenServer.call(__MODULE__, {:open, identifier})

  @doc """
  Asks a round, clearing it first even when it is the round already open.

  This is what walking back to a question does. `open/1` leaves a round it is
  already showing alone, which is right when the deck merely re-renders, but
  wrong when the speaker has come back to ask again: the answer would still be
  on screen and the old answers would still be counted.
  """
  @spec ask(atom()) :: :ok
  def ask(identifier), do: GenServer.call(__MODULE__, {:ask, identifier})

  @doc "Stops accepting answers. The timer does this, and so can the speaker."
  @spec lock() :: :ok
  def lock, do: GenServer.call(__MODULE__, :lock)

  @doc "Puts the answer on the big screen."
  @spec reveal() :: :ok
  def reveal, do: GenServer.call(__MODULE__, :reveal)

  @spec answer(String.t(), String.t()) :: :ok
  def answer(token, value), do: GenServer.call(__MODULE__, {:answer, token, value})

  @doc "Everyone's handle, keyed by token, for naming people on the board."
  @spec handles(t()) :: %{String.t() => String.t()}
  def handles(%__MODULE__{participants: participants}) do
    Map.new(participants, fn {token, participant} -> {token, participant.handle} end)
  end

  @doc "The leaderboard, best first."
  @spec standings() :: [map()]
  def standings, do: state() |> handles() |> Ledger.standings()

  @doc "How many people have answered the open round."
  @spec answered_count(t()) :: non_neg_integer()
  def answered_count(%__MODULE__{answers: answers}), do: map_size(answers)

  @doc """
  The answers so far as `{option, count}`, in the order the round lists its
  options, so a bar chart cannot reorder itself while the audience watches.
  A numeric round has no options and tallies to an empty list.
  """
  @spec tally(t()) :: [{String.t(), non_neg_integer()}]
  def tally(%__MODULE__{round: nil}), do: []

  def tally(%__MODULE__{round: identifier, answers: answers}) do
    counts = answers |> Map.values() |> Enum.frequencies_by(& &1.value)

    identifier
    |> Round.fetch()
    |> Map.fetch!(:options)
    |> Enum.map(fn option -> {option, Map.get(counts, option, 0)} end)
  end

  ## SERVER

  @impl GenServer
  def init(:ok), do: {:ok, %__MODULE__{}}

  @impl GenServer
  def handle_call({:join, token, handle, pid}, _from, room) do
    Process.monitor(pid)

    room =
      room
      |> put_in([Access.key!(:participants), token], %{handle: handle})
      |> put_in([Access.key!(:connections), pid], token)
      |> announce()

    {:reply, :ok, room}
  end

  def handle_call(:state, _from, room), do: {:reply, room, room}

  def handle_call({:move, position}, _from, room),
    do: {:reply, :ok, %{room | position: position}}

  def handle_call(:reset, _from, _room), do: {:reply, :ok, announce(%__MODULE__{})}

  def handle_call({:open, identifier}, _from, %__MODULE__{round: identifier} = room),
    do: {:reply, :ok, room}

  def handle_call({:ask, identifier}, _from, room),
    do: {:reply, :ok, opened(room, identifier)}

  def handle_call({:open, nil}, _from, room) do
    {:reply, :ok, announce(%{room | round: nil, phase: :open, opened_at: nil, answers: %{}})}
  end

  def handle_call({:open, identifier}, _from, room),
    do: {:reply, :ok, opened(room, identifier)}

  def handle_call(:lock, _from, %__MODULE__{round: nil} = room), do: {:reply, :ok, room}
  def handle_call(:lock, _from, room), do: {:reply, :ok, announce(%{room | phase: :locked})}

  def handle_call(:reveal, _from, %__MODULE__{round: nil} = room), do: {:reply, :ok, room}

  def handle_call(:reveal, _from, %__MODULE__{phase: :revealed} = room),
    do: {:reply, :ok, room}

  # Scoring waits for the reveal because the bonus depends on the order people
  # came in, and until the answers stop changing that order can still change.
  def handle_call(:reveal, _from, room) do
    room.round
    |> Round.fetch()
    |> Scoring.score(room.opened_at, room.answers)
    |> then(&Ledger.record(room.round, &1))

    {:reply, :ok, announce(%{room | phase: :revealed})}
  end

  def handle_call({:answer, _token, _value}, _from, %__MODULE__{round: nil} = room),
    do: {:reply, :ok, room}

  def handle_call({:answer, _token, _value}, _from, %__MODULE__{phase: phase} = room)
      when phase != :open,
      do: {:reply, :ok, room}

  def handle_call({:answer, token, value}, _from, room) do
    round = Round.fetch(room.round)

    if acceptable?(round, value) do
      recorded = %{
        value: value,
        correct?: Round.correct?(round, value),
        at: System.monotonic_time(:millisecond)
      }

      {:reply, :ok, announce(put_in(room.answers[token], recorded))}
    else
      {:reply, :ok, room}
    end
  end

  @impl GenServer
  # An expiry that names a round the deck has already moved on from is stale,
  # and locking on it would close a question the speaker has only just asked.
  def handle_info(
        {:expire, identifier, opened_at},
        %__MODULE__{round: identifier, opened_at: opened_at, phase: :open} = room
      ) do
    {:noreply, announce(%{room | phase: :locked})}
  end

  def handle_info({:expire, _identifier, _opened_at}, room), do: {:noreply, room}

  def handle_info({:DOWN, _reference, :process, pid, _reason}, room) do
    {:noreply, room |> Map.update!(:connections, &Map.delete(&1, pid)) |> announce()}
  end

  ## PRIVATE FUNCTIONS

  defp opened(room, identifier) do
    round = Round.fetch(identifier)
    opened_at = System.monotonic_time(:millisecond)

    Process.send_after(self(), {:expire, identifier, opened_at}, round.seconds * 1000)

    announce(%{room | round: identifier, phase: :open, opened_at: opened_at, answers: %{}})
  end

  # A choice has to be one of the ones offered. A number only has to be typed;
  # whether it is right is the round's business, not this one's.
  defp acceptable?(%Round{type: :choice, options: options}, value), do: value in options
  defp acceptable?(%Round{type: :numeric}, value), do: String.trim(value) != ""

  defp announce(room) do
    PubSub.broadcast(ModelNameTalk.PubSub, @topic, {:room, room})

    room
  end
end
