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

  alias Phoenix.PubSub

  @topic "room"

  defstruct round: nil,
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

  @doc "How many people are playing, connected or not."
  @spec participant_count(t()) :: non_neg_integer()
  def participant_count(%__MODULE__{participants: participants}), do: map_size(participants)

  @doc "How many browser tabs are open right now."
  @spec connected_count(t()) :: non_neg_integer()
  def connected_count(%__MODULE__{connections: connections}), do: map_size(connections)

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

  def handle_call(:reset, _from, _room), do: {:reply, :ok, announce(%__MODULE__{})}

  @impl GenServer
  def handle_info({:DOWN, _reference, :process, pid, _reason}, room) do
    {:noreply, room |> Map.update!(:connections, &Map.delete(&1, pid)) |> announce()}
  end

  ## PRIVATE FUNCTIONS

  defp announce(room) do
    PubSub.broadcast(ModelNameTalk.PubSub, @topic, {:room, room})

    room
  end
end
