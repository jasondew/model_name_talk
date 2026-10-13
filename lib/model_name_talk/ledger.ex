defmodule ModelNameTalk.Ledger do
  @moduledoc """
  What the room has answered, and what it was worth.

  A round's scores are written twice: into an ETS table the leaderboard folds
  over, and onto the end of a file. The file is the reason a crash in the
  middle of a talk is survivable. Thirty people over seven rounds is a couple
  of hundred rows, so there is no reason to keep a running total, and a
  leaderboard derived from the answers cannot drift away from them.

  Recording a round that has already been recorded replaces it. Walking back
  through the deck re-opens a round, and asking it again should correct the
  record rather than pay for it twice. Each block in the log opens with a line
  naming its round, which is how a replay knows to clear that round before
  reading the block rather than merging it with an earlier attempt.

  The file is also worth reading after the talk. It says exactly which idea
  the room got wrong, which is feedback a speaker almost never gets.
  """

  use GenServer

  @table :model_name_talk_ledger

  ## CLIENT

  def start_link(options) do
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  @doc "Writes what one round paid, replacing any earlier record of it."
  @spec record(atom(), %{String.t() => map()}) :: :ok
  def record(round, scored), do: GenServer.call(__MODULE__, {:record, round, scored})

  @doc "Where the log is being written."
  @spec path() :: String.t()
  def path, do: GenServer.call(__MODULE__, :path)

  @doc "Forgets every score, and empties the log. For rehearsals and tests."
  @spec forget() :: :ok
  def forget, do: GenServer.call(__MODULE__, :forget)

  @doc "How many distinct rounds have been recorded."
  @spec rounds_asked() :: non_neg_integer()
  def rounds_asked do
    @table |> :ets.match({{:_, :"$1"}, :_}) |> List.flatten() |> Enum.uniq() |> length()
  end

  @doc """
  Everyone who has answered anything, best first, with the place they hold.
  Ties on points are broken by handle so the board does not shuffle itself
  between renders.
  """
  @spec standings(%{String.t() => String.t()}) :: [map()]
  def standings(handles) do
    @table
    |> :ets.tab2list()
    |> Enum.group_by(fn {{token, _round}, _points} -> token end)
    |> Enum.map(fn {token, rows} ->
      %{
        token: token,
        handle: Map.get(handles, token, token),
        points: rows |> Enum.map(fn {_key, points} -> points end) |> Enum.sum(),
        rounds: length(rows)
      }
    end)
    |> Enum.sort_by(&{-&1.points, &1.handle})
    |> Enum.with_index(1)
    |> Enum.map(fn {standing, place} -> Map.put(standing, :place, place) end)
  end

  ## SERVER

  @impl GenServer
  def init(options) do
    path = Keyword.get_lazy(options, :path, &default_path/0)
    File.mkdir_p!(Path.dirname(path))

    case :ets.whereis(@table) do
      :undefined -> :ets.new(@table, [:named_table, :public, :set])
      _existing -> :ok
    end

    replay(path)

    {:ok, %{path: path}}
  end

  @impl GenServer
  def handle_call({:record, round, scored}, _from, state) do
    write(state.path, round, scored)
    remember(round, scored)

    {:reply, :ok, state}
  end

  def handle_call(:path, _from, state), do: {:reply, state.path, state}

  def handle_call(:forget, _from, state) do
    :ets.delete_all_objects(@table)
    File.write!(state.path, "")

    {:reply, :ok, state}
  end

  ## PRIVATE FUNCTIONS

  defp default_path do
    Application.get_env(:model_name_talk, :ledger_path) ||
      Path.join([
        Application.app_dir(:model_name_talk, "priv"),
        "rounds",
        "#{Date.utc_today()}.log"
      ])
  end

  # A line naming the round, then one line for each participant. Plain text,
  # because the thing most likely to read this after the talk is a person.
  defp write(path, round, scored) do
    rows =
      Enum.map(scored, fn {token, result} ->
        "#{round}\t#{token}\t#{result.points}\n"
      end)

    File.write!(path, ["# #{round}\n" | rows], [:append])
  end

  defp remember(round, scored) do
    :ets.match_delete(@table, {{:_, round}, :_})

    Enum.each(scored, fn {token, result} ->
      :ets.insert(@table, {{token, round}, result.points})
    end)
  end

  defp replay(path) do
    case File.read(path) do
      {:ok, contents} -> contents |> String.split("\n", trim: true) |> Enum.each(&replay_line/1)
      {:error, :enoent} -> :ok
    end
  end

  # A round's block opens by clearing that round, so a round recorded twice
  # replays as its later answer rather than as both merged together.
  defp replay_line("# " <> round) do
    :ets.match_delete(@table, {{:_, String.to_atom(round)}, :_})
  end

  defp replay_line(line) do
    case String.split(line, "\t") do
      [round, token, points] ->
        :ets.insert(@table, {{token, String.to_atom(round)}, String.to_integer(points)})

      _other ->
        :ok
    end
  end
end
