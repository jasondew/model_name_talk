# Audience Game Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A working, rehearsable audience game: 30 people join on their phones, answer seven scored rounds, and watch a leaderboard, all driven by the slide on screen.

**Architecture:** One Phoenix application. A supervised `Room` GenServer holds who is here and what is open; which round is open is decided by the slide on screen, so there is no second thing to manage while presenting. Answers are appended to a log as they arrive and scored into ETS at reveal, so the leaderboard is a fold over data rather than a counter that can drift. Identity is a token in `localStorage`, not a pid, so a locked phone rejoins as the same player.

**Tech Stack:** Elixir 1.18.4, Erlang/OTP 27 (pinned via mise), Phoenix 1.8.9, Phoenix LiveView 1.2, `eqrcode` 0.2, Bandit. No Ecto, no database.

**Spec:** `docs/superpowers/specs/2026-09-21-model-name-talk-design.md`

**Prior art:** The deleted implementation lives in `~/src/tiny_llm_talk` at commit `410b11a^`. Recover files with `git -C ~/src/tiny_llm_talk show 410b11a^:<path>`. Relevant paths: `lib/tiny_llm_talk/room.ex`, `lib/tiny_llm_talk_web/live/join_live.ex`, `assets/css/join.css`, `test/tiny_llm_talk/room_test.exs`, `test/tiny_llm_talk_web/live/join_live_test.exs`.

## Global Constraints

- Elixir 1.18.4 / OTP 27.3.4.11, pinned in `mise.toml`, copied from `~/src/tiny_llm_talk/mise.toml`.
- No Ecto and no database. State is a GenServer, ETS and an append only file.
- No em-dashes or dashes in prose, in code comments, in speaker notes or in commit messages.
- Descriptive names only. No single letter variables, no abbreviations. Use `participant` not `p`, `round_identifier` not `rid`.
- Public and private functions separated by a `## PRIVATE FUNCTIONS` comment.
- `@callback` definitions go in the module itself, never a separate Behaviour module.
- Prefer pattern matching over conditionals.
- Every round must render and every page must work with zero participants. A talk where the network failed is still a talk.
- Run `mix format` before every commit. Run `mix test` before every commit.
- Commit messages explain why, not what.

---

### Task 1: Scaffold the application

**Files:**
- Create: the Phoenix application at the repository root
- Create: `mise.toml`
- Modify: `mix.exs`
- Test: `test/model_name_talk_web/live/page_live_test.exs` (generated, then deleted)

**Interfaces:**
- Consumes: nothing
- Produces: an OTP application named `:model_name_talk`, module prefix `ModelNameTalk`, web prefix `ModelNameTalkWeb`, a running `Phoenix.PubSub` named `ModelNameTalk.PubSub`, and a supervision tree in `lib/model_name_talk/application.ex`.

- [ ] **Step 1: Generate the application into the existing repository**

The repository already has `docs/` and a git history, so generate into a
temporary directory and move the files in, rather than letting the generator
refuse or clobber.

```bash
cd /tmp && rm -rf mnt_scaffold
mix phx.new mnt_scaffold --module ModelNameTalk --app model_name_talk \
  --no-ecto --no-mailer --no-gettext --install
cd /Users/jasondew/src/model_name_talk
rsync -a --exclude .git --exclude .gitignore /tmp/mnt_scaffold/ .
rm -rf /tmp/mnt_scaffold
```

- [ ] **Step 2: Pin the toolchain**

```bash
cp ~/src/tiny_llm_talk/mise.toml /Users/jasondew/src/model_name_talk/mise.toml
```

- [ ] **Step 3: Add the QR code dependency**

In `mix.exs`, inside `defp deps do`, add below the `phoenix_live_view` entry:

```elixir
      # The join URL, as something a phone can point a camera at. The audience
      # is remote and reads it off a shared screen, so it has to stay legible
      # after a video codec has been at it.
      {:eqrcode, "~> 0.2"},
```

- [ ] **Step 4: Fetch and compile**

Run: `mix deps.get && mix compile`
Expected: compiles with no errors.

- [ ] **Step 5: Verify the generated suite is green, then drop the placeholder page test**

Run: `mix test`
Expected: PASS.

```bash
rm -f test/model_name_talk_web/controllers/page_controller_test.exs
```

Run: `mix test`
Expected: PASS, with the placeholder gone.

- [ ] **Step 6: Commit**

```bash
mix format
git add -A
git commit -m "Scaffold the Phoenix application

A deck and an audience game, so LiveView and PubSub, and nothing else: no
Ecto, no mailer. What the room is doing fits in a GenServer and what it
answered fits in a file."
```

---

### Task 2: The round catalogue

**Files:**
- Create: `lib/model_name_talk/round.ex`
- Test: `test/model_name_talk/round_test.exs`

**Interfaces:**
- Consumes: nothing
- Produces:
  - `%ModelNameTalk.Round{id: atom(), question: String.t(), hint: String.t() | nil, type: :choice | :numeric, options: [String.t()], answer: String.t() | number() | nil, band: {number(), number()} | nil, seconds: pos_integer(), speed_bonus: boolean(), after_segment: String.t()}`
  - `ModelNameTalk.Round.all() :: [t()]` in talk order
  - `ModelNameTalk.Round.fetch(atom()) :: t() | nil`
  - `ModelNameTalk.Round.correct?(t(), String.t()) :: boolean()`

Numeric answers arrive from a phone as strings. `correct?/2` parses and
compares against the band, so a round is the single place that decides what
"right" means.

- [ ] **Step 1: Write the failing test**

Create `test/model_name_talk/round_test.exs`:

```elixir
defmodule ModelNameTalk.RoundTest do
  use ExUnit.Case, async: true

  alias ModelNameTalk.Round

  describe "the catalogue" do
    test "lists seven rounds in talk order" do
      identifiers = Enum.map(Round.all(), & &1.id)

      assert identifiers == [
               :open_weights,
               :how_many_gpt2s,
               :memory_versus_speed,
               :base_completion,
               :how_many_gigabytes,
               :which_is_two_bit,
               :does_it_fit
             ]
    end

    test "gives every round a question, a segment and a timer" do
      for round <- Round.all() do
        assert round.question != ""
        assert round.after_segment != ""
        assert round.seconds > 0
      end
    end

    test "gives every choice round at least two options and an answer among them" do
      for round <- Round.all(), round.type == :choice do
        assert length(round.options) >= 2
        assert round.answer in round.options
      end
    end

    test "gives every numeric round a band that contains its answer" do
      for round <- Round.all(), round.type == :numeric do
        {low, high} = round.band

        assert low <= round.answer and round.answer <= high
      end
    end

    test "exempts numeric rounds from the speed bonus" do
      for round <- Round.all(), round.type == :numeric do
        refute round.speed_bonus
      end
    end

    test "fetches a round by identifier, and nothing for an unknown one" do
      assert Round.fetch(:open_weights).type == :choice
      assert is_nil(Round.fetch(:not_a_round))
    end
  end

  describe "correct?/2" do
    test "compares a choice exactly" do
      round = Round.fetch(:open_weights)

      assert Round.correct?(round, round.answer)
      refute Round.correct?(round, "Claude")
    end

    test "accepts a number anywhere inside the band" do
      round = Round.fetch(:how_many_gigabytes)
      {low, high} = round.band

      assert Round.correct?(round, to_string(low))
      assert Round.correct?(round, to_string(high))
      assert Round.correct?(round, to_string(round.answer))
    end

    test "rejects a number outside the band" do
      round = Round.fetch(:how_many_gigabytes)
      {low, high} = round.band

      refute Round.correct?(round, to_string(low - 1))
      refute Round.correct?(round, to_string(high + 1))
    end

    test "accepts a decimal and a number wearing its unit" do
      round = Round.fetch(:how_many_gigabytes)

      assert Round.correct?(round, "74.4")
      assert Round.correct?(round, "74 GB")
    end

    test "rejects text that holds no number" do
      round = Round.fetch(:how_many_gigabytes)

      refute Round.correct?(round, "lots")
      refute Round.correct?(round, "")
    end
  end
end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `mix test test/model_name_talk/round_test.exs`
Expected: FAIL, `ModelNameTalk.Round.all/0 is undefined`.

- [ ] **Step 3: Write the implementation**

Create `lib/model_name_talk/round.ex`:

```elixir
defmodule ModelNameTalk.Round do
  @moduledoc """
  The questions the talk asks, in the order it asks them.

  One round closes each chapter, so a round knows which segment of the file
  name it comes after and the deck can light that segment as it asks.

  A round is also the only place that decides what "right" means. A phone
  sends a string either way, so a numeric round carries a tolerance band and
  parses what it is given: round five asks for gigabytes, and someone who used
  eight bits for each weight instead of eight and a half and landed on seventy
  has applied the formula correctly, which is the thing being tested.

  Numeric rounds carry no speed bonus. They are the only questions that ask
  for arithmetic rather than recognition, and a calculator race would punish
  exactly the careful reasoning the talk is trying to teach.
  """

  @enforce_keys [:id, :question, :type, :after_segment]
  defstruct [
    :id,
    :question,
    :hint,
    :type,
    :answer,
    :band,
    :after_segment,
    options: [],
    seconds: 20,
    speed_bonus: true
  ]

  @type t :: %__MODULE__{
          id: atom(),
          question: String.t(),
          hint: String.t() | nil,
          type: :choice | :numeric,
          answer: String.t() | number() | nil,
          band: {number(), number()} | nil,
          after_segment: String.t(),
          options: [String.t()],
          seconds: pos_integer(),
          speed_bonus: boolean()
        }

  @rounds [
    %__MODULE__{
      id: :open_weights,
      after_segment: "Qwen3",
      question: "Which of these can you actually download the weights for?",
      hint: "one of them ships you a file",
      type: :choice,
      options: ["Claude", "GPT-4", "Qwen3", "Gemini"],
      answer: "Qwen3",
      seconds: 20
    },
    %__MODULE__{
      id: :how_many_gpt2s,
      after_segment: "30B",
      question: "GPT-2 small was 124M. How many of it fit inside 30.5B?",
      hint: "B is billion, M is million",
      type: :choice,
      options: ["25", "246", "2,460", "24,600"],
      answer: "246",
      seconds: 20
    },
    %__MODULE__{
      id: :memory_versus_speed,
      after_segment: "A3B",
      question: "Llama-4-Scout-109B-A17B needs the memory of a ?B model and runs at the speed of a ?B model.",
      hint: "the A is the clue",
      type: :choice,
      options: [
        "109B memory, 109B speed",
        "17B memory, 17B speed",
        "109B memory, 17B speed",
        "17B memory, 109B speed"
      ],
      answer: "109B memory, 17B speed",
      seconds: 20
    },
    %__MODULE__{
      id: :base_completion,
      after_segment: "Instruct",
      question: ~s(You send "What is the capital of France?" to a base model. What comes back?),
      hint: "it has had no post-training",
      type: :choice,
      options: [
        "Paris.",
        "The capital of France is Paris, a city of 2.1 million people.",
        "What is the capital of Germany? What is the capital of Spain?",
        "I am a language model and cannot browse the web."
      ],
      answer: "What is the capital of Germany? What is the capital of Spain?",
      seconds: 20
    },
    %__MODULE__{
      id: :how_many_gigabytes,
      after_segment: "Q4_K_M",
      question: "Llama-3.3-70B-Instruct-Q8_0.gguf. How many gigabytes?",
      hint: "no rush on this one. parameters times bits over eight",
      type: :numeric,
      answer: 74,
      band: {68, 80},
      seconds: 45,
      speed_bonus: false
    },
    %__MODULE__{
      id: :which_is_two_bit,
      after_segment: "Q4_K_M",
      question: "Three samples from the toy model, quantised to 8, 4 and 2 bits. Which one is 2 bit?",
      hint: "below three bits it falls apart quickly",
      type: :choice,
      options: ["A", "B", "C"],
      answer: "C",
      seconds: 20
    },
    %__MODULE__{
      id: :does_it_fit,
      after_segment: ".gguf",
      question: "18.6 GB of model, a 12 GB card and 16 GB of system RAM. What do you do?",
      hint: "more than one of these works",
      type: :choice,
      options: [
        "Nothing. It cannot run.",
        "Offload part of it to system RAM",
        "Buy a second card",
        "Run it at BF16 instead"
      ],
      answer: "Offload part of it to system RAM",
      seconds: 20
    }
  ]

  @doc "Every round, in the order the talk asks them."
  @spec all() :: [t()]
  def all, do: @rounds

  @doc "One round by identifier, or nil when there is no such round."
  @spec fetch(atom() | nil) :: t() | nil
  def fetch(nil), do: nil
  def fetch(identifier), do: Enum.find(@rounds, &(&1.id == identifier))

  @doc """
  Whether an answer is right. A choice must match exactly. A number need only
  land inside the band, because the band is the width of a reasonable rounding.
  """
  @spec correct?(t(), String.t()) :: boolean()
  def correct?(%__MODULE__{type: :choice, answer: answer}, given), do: given == answer

  def correct?(%__MODULE__{type: :numeric, band: {low, high}}, given) do
    case number(given) do
      nil -> false
      number -> low <= number and number <= high
    end
  end

  ## PRIVATE FUNCTIONS

  # A phone sends a string, and somebody will type "74 GB" or "74.4". Take the
  # first number in what arrived and ignore the rest.
  defp number(given) when is_binary(given) do
    case Regex.run(~r/-?\d+(\.\d+)?/, given) do
      nil -> nil
      [matched | _rest] -> String.to_float(ensure_decimal(matched))
    end
  end

  defp number(_given), do: nil

  defp ensure_decimal(text) do
    if String.contains?(text, "."), do: text, else: text <> ".0"
  end
end
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `mix test test/model_name_talk/round_test.exs`
Expected: PASS, 11 tests.

- [ ] **Step 5: Commit**

```bash
mix format
git add lib/model_name_talk/round.ex test/model_name_talk/round_test.exs
git commit -m "Write the seven questions down as data

A round knows which segment it follows, so the deck can light that segment
as it asks, and it owns its own idea of a right answer. The numeric rounds
carry a band rather than a value because the thing being tested is whether
someone can apply the formula, not whether they remembered that Q8_0 costs
about eight and a half bits rather than eight."
```

---

### Task 3: Participants keyed by token

**Files:**
- Create: `lib/model_name_talk/room.ex`
- Modify: `lib/model_name_talk/application.ex`
- Test: `test/model_name_talk/room_test.exs`

**Interfaces:**
- Consumes: `ModelNameTalk.Round`
- Produces:
  - `ModelNameTalk.Room.join(token :: String.t(), handle :: String.t(), pid()) :: :ok`
  - `ModelNameTalk.Room.state() :: %ModelNameTalk.Room{round: atom() | nil, phase: :open | :locked | :revealed, opened_at: integer() | nil, answers: %{String.t() => map()}, participants: %{String.t() => map()}}`
  - `ModelNameTalk.Room.participant_count(t()) :: non_neg_integer()`
  - `ModelNameTalk.Room.connected_count(t()) :: non_neg_integer()`
  - `ModelNameTalk.Room.subscribe() :: :ok`, broadcasting `{:room, t()}` on topic `"room"`
  - `ModelNameTalk.Room.reset() :: :ok`

This is the one place the plan deliberately departs from the recovered code.
The old `join/1` took a pid and monitored it; identity was the pid. This one
takes a token and tracks pids underneath it.

- [ ] **Step 1: Write the failing test**

Create `test/model_name_talk/room_test.exs`:

```elixir
defmodule ModelNameTalk.RoomTest do
  use ExUnit.Case, async: false

  alias ModelNameTalk.Room

  setup do
    Room.reset()
    :ok
  end

  defp elsewhere do
    spawn(fn -> Process.sleep(:infinity) end)
  end

  describe "joining" do
    test "registers a participant under their token" do
      Room.join("token-one", "ada", self())

      room = Room.state()

      assert Room.participant_count(room) == 1
      assert room.participants["token-one"].handle == "ada"
    end

    test "counts one participant however many tabs they open" do
      Room.join("token-one", "ada", self())
      Room.join("token-one", "ada", elsewhere())

      room = Room.state()

      assert Room.participant_count(room) == 1
      assert Room.connected_count(room) == 2
    end

    test "keeps a participant when one of their tabs closes" do
      other_tab = elsewhere()
      Room.join("token-one", "ada", self())
      Room.join("token-one", "ada", other_tab)

      Process.exit(other_tab, :kill)
      Process.sleep(50)

      room = Room.state()

      assert Room.participant_count(room) == 1
      assert Room.connected_count(room) == 1
    end

    test "keeps a participant after their last tab closes, so a locked phone can come back" do
      only_tab = elsewhere()
      Room.join("token-one", "ada", only_tab)

      Process.exit(only_tab, :kill)
      Process.sleep(50)

      room = Room.state()

      assert Room.participant_count(room) == 1
      assert Room.connected_count(room) == 0
    end

    test "lets a participant change their handle" do
      Room.join("token-one", "ada", self())
      Room.join("token-one", "grace", self())

      assert Room.state().participants["token-one"].handle == "grace"
    end

    test "tells subscribers when somebody joins" do
      Room.subscribe()
      Room.join("token-one", "ada", self())

      assert_receive {:room, %Room{}}
    end
  end

  describe "an empty room" do
    test "counts nothing and answers every question a slide asks" do
      room = Room.state()

      assert Room.participant_count(room) == 0
      assert Room.connected_count(room) == 0
      assert room.answers == %{}
      assert is_nil(room.round)
    end
  end
end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `mix test test/model_name_talk/room_test.exs`
Expected: FAIL, `ModelNameTalk.Room.reset/0 is undefined`.

- [ ] **Step 3: Write the implementation**

Create `lib/model_name_talk/room.ex`:

```elixir
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

  alias ModelNameTalk.Round
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
```

In `lib/model_name_talk/application.ex`, add `ModelNameTalk.Room` to the
children list, directly after the `Phoenix.PubSub` entry:

```elixir
      ModelNameTalk.Room,
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `mix test test/model_name_talk/room_test.exs`
Expected: PASS, 7 tests.

- [ ] **Step 5: Commit**

```bash
mix format
git add lib/model_name_talk/room.ex lib/model_name_talk/application.ex test/model_name_talk/room_test.exs
git commit -m "Key a participant by a token rather than by their process

The deck this grew out of keyed the audience by LiveView pid, which was
invisible in a room: the activities were short and nobody locked their phone
in the middle of one. Over forty minutes of a remote talk, phones sleep and
background tabs get discarded, and every reconnect would have minted a new
player and quietly dropped the old one's score. The token lives in local
storage and the processes hang underneath it."
```

---

### Task 4: Opening, locking and revealing a round

**Files:**
- Modify: `lib/model_name_talk/room.ex`
- Test: `test/model_name_talk/room_test.exs`

**Interfaces:**
- Consumes: `ModelNameTalk.Room` from Task 3, `ModelNameTalk.Round.fetch/1`
- Produces:
  - `ModelNameTalk.Room.open(atom() | nil) :: :ok`
  - `ModelNameTalk.Room.lock() :: :ok`
  - `ModelNameTalk.Room.reveal() :: :ok`
  - `ModelNameTalk.Room.answer(token :: String.t(), value :: String.t()) :: :ok`
  - `ModelNameTalk.Room.answered_count(t()) :: non_neg_integer()`
  - `ModelNameTalk.Room.tally(t()) :: [{String.t(), non_neg_integer()}]`

`tally/1` returns counts in the order the round lists its options, so a bar
chart cannot reorder itself under the audience while they watch.

The timer lives here: opening a round schedules its own lock. The speaker can
lock early from the presenter view, which is what the `lock/0` call is for.

- [ ] **Step 1: Write the failing test**

Append to `test/model_name_talk/room_test.exs`, inside the module:

```elixir
  describe "opening a round" do
    test "opens it, notes the time, and accepts answers" do
      Room.open(:open_weights)

      room = Room.state()

      assert room.round == :open_weights
      assert room.phase == :open
      assert is_integer(room.opened_at)
    end

    test "clears the answers of the round before it" do
      Room.open(:open_weights)
      Room.join("token-one", "ada", self())
      Room.answer("token-one", "Qwen3")

      Room.open(:how_many_gpt2s)

      assert Room.state().answers == %{}
    end

    test "opening the round already open changes nothing" do
      Room.open(:open_weights)
      Room.join("token-one", "ada", self())
      Room.answer("token-one", "Qwen3")

      opened_at = Room.state().opened_at
      Room.open(:open_weights)

      assert Room.state().opened_at == opened_at
      assert map_size(Room.state().answers) == 1
    end

    test "closes whatever is open when given nil" do
      Room.open(:open_weights)
      Room.open(nil)

      assert is_nil(Room.state().round)
    end
  end

  describe "answering" do
    setup do
      Room.open(:open_weights)
      Room.join("token-one", "ada", self())
      :ok
    end

    test "records an answer against the token that gave it" do
      Room.answer("token-one", "Qwen3")

      assert Room.state().answers["token-one"].value == "Qwen3"
      assert Room.state().answers["token-one"].correct?
    end

    test "marks a wrong answer wrong" do
      Room.answer("token-one", "Claude")

      refute Room.state().answers["token-one"].correct?
    end

    test "lets a participant change their mind, and takes the newer time" do
      Room.answer("token-one", "Claude")
      first = Room.state().answers["token-one"].at

      Process.sleep(5)
      Room.answer("token-one", "Qwen3")
      second = Room.state().answers["token-one"]

      assert second.value == "Qwen3"
      assert second.at > first
      assert Room.answered_count(Room.state()) == 1
    end

    test "ignores an answer once the round is locked" do
      Room.lock()
      Room.answer("token-one", "Qwen3")

      assert Room.state().answers == %{}
    end

    test "ignores an answer when no round is open" do
      Room.open(nil)
      Room.answer("token-one", "Qwen3")

      assert Room.state().answers == %{}
    end

    test "ignores a choice the round does not offer" do
      Room.answer("token-one", "Mistral")

      assert Room.state().answers == %{}
    end

    test "counts answers in the order the round lists its options" do
      Room.join("token-two", "grace", elsewhere())
      Room.answer("token-one", "Qwen3")
      Room.answer("token-two", "Claude")

      assert Room.tally(Room.state()) == [
               {"Claude", 1},
               {"GPT-4", 0},
               {"Qwen3", 1},
               {"Gemini", 0}
             ]
    end
  end

  describe "locking and revealing" do
    setup do
      Room.open(:open_weights)
      :ok
    end

    test "locks when the speaker ends the round early" do
      Room.lock()

      assert Room.state().phase == :locked
    end

    test "locks on its own when the timer runs out" do
      Room.open(:fast_round_for_tests)

      assert Room.state().phase == :open

      Process.sleep(80)

      assert Room.state().phase == :locked
    end

    test "reveals, and reveals from open without a separate lock" do
      Room.reveal()

      assert Room.state().phase == :revealed
    end

    test "does not reveal when nothing is open" do
      Room.open(nil)
      Room.reveal()

      assert Room.state().phase != :revealed
    end
  end
```

The locking test needs a round that expires quickly. Add a test only round to
the catalogue in `lib/model_name_talk/round.ex`, at the end of `@rounds`:

```elixir
    %__MODULE__{
      id: :fast_round_for_tests,
      after_segment: "none",
      question: "A round whose timer runs out immediately, so the test does not sleep.",
      type: :choice,
      options: ["yes", "no"],
      answer: "yes",
      seconds: 0
    }
```

Because `all/0` now carries a round the talk never asks, change it to hide it,
and add `every/0` for the tests:

```elixir
  @doc "Every round the talk asks, in order."
  @spec all() :: [t()]
  def all, do: Enum.reject(@rounds, &(&1.id == :fast_round_for_tests))

  @doc "Every round including the one that exists only for tests."
  @spec every() :: [t()]
  def every, do: @rounds
```

and make `fetch/1` search `@rounds` (it already does).

- [ ] **Step 2: Run the test to verify it fails**

Run: `mix test test/model_name_talk/room_test.exs`
Expected: FAIL, `ModelNameTalk.Room.open/1 is undefined`.

- [ ] **Step 3: Write the implementation**

In `lib/model_name_talk/room.ex`, add to the client section:

```elixir
  @doc "Opens a round, or closes whatever is open when given nil."
  @spec open(atom() | nil) :: :ok
  def open(identifier), do: GenServer.call(__MODULE__, {:open, identifier})

  @doc "Stops accepting answers. The timer does this, and so can the speaker."
  @spec lock() :: :ok
  def lock, do: GenServer.call(__MODULE__, :lock)

  @doc "Puts the answer on the big screen."
  @spec reveal() :: :ok
  def reveal, do: GenServer.call(__MODULE__, :reveal)

  @spec answer(String.t(), String.t()) :: :ok
  def answer(token, value), do: GenServer.call(__MODULE__, {:answer, token, value})

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
```

and to the server section:

```elixir
  def handle_call({:open, identifier}, _from, %__MODULE__{round: identifier} = room),
    do: {:reply, :ok, room}

  def handle_call({:open, nil}, _from, room) do
    {:reply, :ok, announce(%{room | round: nil, phase: :open, opened_at: nil, answers: %{}})}
  end

  def handle_call({:open, identifier}, _from, room) do
    round = Round.fetch(identifier)
    opened_at = System.monotonic_time(:millisecond)

    Process.send_after(self(), {:expire, identifier, opened_at}, round.seconds * 1000)

    {:reply, :ok,
     announce(%{room | round: identifier, phase: :open, opened_at: opened_at, answers: %{}})}
  end

  def handle_call(:lock, _from, %__MODULE__{round: nil} = room), do: {:reply, :ok, room}
  def handle_call(:lock, _from, room), do: {:reply, :ok, announce(%{room | phase: :locked})}

  def handle_call(:reveal, _from, %__MODULE__{round: nil} = room), do: {:reply, :ok, room}
  def handle_call(:reveal, _from, room), do: {:reply, :ok, announce(%{room | phase: :revealed})}

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
```

and a matching `handle_info`, which ignores an expiry belonging to a round
that has already been replaced:

```elixir
  def handle_info({:expire, identifier, opened_at}, %__MODULE__{round: identifier, opened_at: opened_at, phase: :open} = room) do
    {:noreply, announce(%{room | phase: :locked})}
  end

  def handle_info({:expire, _identifier, _opened_at}, room), do: {:noreply, room}
```

and to the private section:

```elixir
  # A choice has to be one of the ones offered. A number only has to be typed;
  # whether it is right is the round's business, not this one's.
  defp acceptable?(%Round{type: :choice, options: options}, value), do: value in options
  defp acceptable?(%Round{type: :numeric}, value), do: String.trim(value) != ""
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `mix test test/model_name_talk/room_test.exs`
Expected: PASS, 20 tests.

- [ ] **Step 5: Commit**

```bash
mix format
git add lib/model_name_talk/room.ex lib/model_name_talk/round.ex test/model_name_talk/room_test.exs
git commit -m "Let a round open, lock and reveal

Which round is open is decided by the slide on screen, so walking backwards
re-opens what was there. The timer lives with the round and locks it, and the
speaker can lock early, because twenty seconds of silence on a video call is
long and there is no reason to spend the last eight of it once everyone has
answered.

The tally keeps the round's own option order. A bar chart that reorders
itself while the audience watches is worse than no bar chart."
```

---

### Task 5: Scoring a round

**Files:**
- Create: `lib/model_name_talk/scoring.ex`
- Test: `test/model_name_talk/scoring_test.exs`

**Interfaces:**
- Consumes: `ModelNameTalk.Round`
- Produces:
  - `ModelNameTalk.Scoring.score(round :: Round.t(), opened_at :: integer(), answers :: %{String.t() => map()}) :: %{String.t() => %{points: non_neg_integer(), correct?: boolean(), place: pos_integer() | nil}}`

`place` is where a correct answer came in, 1 for first, and nil for a wrong
answer. The deck uses it to name who was first.

A pure function over data, deliberately outside the GenServer, so the rules
can be tested without a process and changed without touching the room.

- [ ] **Step 1: Write the failing test**

Create `test/model_name_talk/scoring_test.exs`:

```elixir
defmodule ModelNameTalk.ScoringTest do
  use ExUnit.Case, async: true

  alias ModelNameTalk.{Round, Scoring}

  defp answers(list) do
    Map.new(list, fn {token, value, at} ->
      {token, %{value: value, at: at, correct?: Round.correct?(Round.fetch(:open_weights), value)}}
    end)
  end

  describe "a choice round" do
    setup do
      %{round: Round.fetch(:open_weights), opened_at: 0}
    end

    test "gives ten points for a right answer and nothing for a wrong one", context do
      scored =
        Scoring.score(
          context.round,
          context.opened_at,
          answers([{"right", "Qwen3", 100}, {"wrong", "Claude", 100}])
        )

      assert scored["right"].points == 15
      assert scored["wrong"].points == 0
      refute scored["wrong"].correct?
    end

    test "adds five, four and three to the first three right answers", context do
      scored =
        Scoring.score(
          context.round,
          context.opened_at,
          answers([
            {"first", "Qwen3", 100},
            {"second", "Qwen3", 200},
            {"third", "Qwen3", 300},
            {"fourth", "Qwen3", 400}
          ])
        )

      assert scored["first"].points == 15
      assert scored["second"].points == 14
      assert scored["third"].points == 13
      assert scored["fourth"].points == 11
    end

    test "names the place a right answer came in", context do
      scored =
        Scoring.score(
          context.round,
          context.opened_at,
          answers([{"first", "Qwen3", 100}, {"second", "Qwen3", 200}, {"wrong", "Claude", 50}])
        )

      assert scored["first"].place == 1
      assert scored["second"].place == 2
      assert is_nil(scored["wrong"].place)
    end

    test "gives no late bonus past the halfway mark", context do
      halfway = context.round.seconds * 1000 / 2

      scored =
        Scoring.score(
          context.round,
          context.opened_at,
          answers([
            {"first", "Qwen3", 1},
            {"second", "Qwen3", 2},
            {"third", "Qwen3", 3},
            {"early", "Qwen3", trunc(halfway) - 1},
            {"late", "Qwen3", trunc(halfway) + 1}
          ])
        )

      assert scored["early"].points == 11
      assert scored["late"].points == 10
    end

    test "scores an empty room without complaint", context do
      assert Scoring.score(context.round, context.opened_at, %{}) == %{}
    end
  end

  describe "a numeric round" do
    test "pays a flat ten, however fast, because it is the no rush round" do
      round = Round.fetch(:how_many_gigabytes)

      given =
        Map.new([{"first", "74", 10}, {"second", "70", 20}, {"wrong", "15", 30}], fn {token,
                                                                                      value, at} ->
          {token, %{value: value, at: at, correct?: Round.correct?(round, value)}}
        end)

      scored = Scoring.score(round, 0, given)

      assert scored["first"].points == 10
      assert scored["second"].points == 10
      assert scored["wrong"].points == 0
    end
  end
end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `mix test test/model_name_talk/scoring_test.exs`
Expected: FAIL, `ModelNameTalk.Scoring.score/3 is undefined`.

- [ ] **Step 3: Write the implementation**

Create `lib/model_name_talk/scoring.ex`:

```elixir
defmodule ModelNameTalk.Scoring do
  @moduledoc """
  What a round is worth.

  Ten points for a right answer. The first three right answers take five, four
  and three more, and anyone else right in the first half of the window takes
  one. A wrong answer is worth nothing.

  The bonus is small on purpose. The audience is remote and watching a shared
  screen, and a video call spreads the moment people see a question across a
  second or three depending on their connection. A bonus that decayed steeply
  from the moment a round opened would be scoring their internet. Capped at
  five, latency moves somebody between first and third place in a round and
  never between winning and losing the talk: six right answers slowly beats
  four right answers quickly.

  Numeric rounds pay a flat ten. They are the only questions asking for
  arithmetic rather than recognition, and a calculator race would punish
  exactly the careful reasoning the talk is trying to teach.
  """

  alias ModelNameTalk.Round

  @correct 10
  @podium [5, 4, 3]
  @early 1

  @type scored :: %{points: non_neg_integer(), correct?: boolean(), place: pos_integer() | nil}

  @doc "Every answer to one round, with what it earned and where it came in."
  @spec score(Round.t(), integer(), %{String.t() => map()}) :: %{String.t() => scored()}
  def score(%Round{} = round, opened_at, answers) do
    places =
      answers
      |> Enum.filter(fn {_token, answer} -> answer.correct? end)
      |> Enum.sort_by(fn {_token, answer} -> answer.at end)
      |> Enum.with_index(1)
      |> Map.new(fn {{token, _answer}, place} -> {token, place} end)

    Map.new(answers, fn {token, answer} ->
      place = Map.get(places, token)

      {token,
       %{
         correct?: answer.correct?,
         place: place,
         points: points(round, opened_at, answer, place)
       }}
    end)
  end

  ## PRIVATE FUNCTIONS

  defp points(_round, _opened_at, %{correct?: false}, _place), do: 0

  defp points(%Round{speed_bonus: false}, _opened_at, _answer, _place), do: @correct

  defp points(round, opened_at, answer, place) do
    @correct + bonus(round, opened_at, answer, place)
  end

  defp bonus(_round, _opened_at, _answer, place) when place <= 3, do: Enum.at(@podium, place - 1)

  defp bonus(round, opened_at, answer, _place) do
    halfway = opened_at + round.seconds * 1000 / 2

    if answer.at < halfway, do: @early, else: 0
  end
end
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `mix test test/model_name_talk/scoring_test.exs`
Expected: PASS, 6 tests.

- [ ] **Step 5: Commit**

```bash
mix format
git add lib/model_name_talk/scoring.ex test/model_name_talk/scoring_test.exs
git commit -m "Pay for being right, and a little for being first

The first right answer wins the round, which is the point of having a
leaderboard at all. But the bonus is capped at five against a base of ten,
because the audience is watching a shared screen and a video call hands
people the question one to three seconds apart depending on their connection.
A steeper curve would be ranking their internet. Capped, six right answers
slowly still beats four right answers quickly.

Numeric rounds pay flat. Round five asks for arithmetic and a race would
punish the one habit the talk most wants to leave behind."
```

---

### Task 6: The log, and replaying it after a crash

**Files:**
- Create: `lib/model_name_talk/ledger.ex`
- Test: `test/model_name_talk/ledger_test.exs`

**Interfaces:**
- Consumes: `ModelNameTalk.Scoring`, `ModelNameTalk.Round`
- Produces:
  - `ModelNameTalk.Ledger.start_link(keyword()) :: GenServer.on_start()`, accepting `path:`
  - `ModelNameTalk.Ledger.record(round :: atom(), %{String.t() => Scoring.scored()}) :: :ok`
  - `ModelNameTalk.Ledger.standings(handles :: %{String.t() => String.t()}) :: [%{token: String.t(), handle: String.t(), points: non_neg_integer(), rounds: non_neg_integer(), place: pos_integer()}]`
  - `ModelNameTalk.Ledger.rounds_asked() :: non_neg_integer()`
  - `ModelNameTalk.Ledger.forget() :: :ok`

The ledger owns an ETS table and an append only file. Recording a round twice
replaces the earlier record rather than adding to it, so walking back to a
round and asking it again is safe.

- [ ] **Step 1: Write the failing test**

Create `test/model_name_talk/ledger_test.exs`:

```elixir
defmodule ModelNameTalk.LedgerTest do
  use ExUnit.Case, async: false

  alias ModelNameTalk.Ledger

  setup do
    Ledger.forget()
    :ok
  end

  defp scored(list) do
    Map.new(list, fn {token, points} ->
      {token, %{points: points, correct?: points > 0, place: nil}}
    end)
  end

  describe "standings" do
    test "add a participant's points across rounds" do
      Ledger.record(:open_weights, scored([{"ada", 15}, {"grace", 10}]))
      Ledger.record(:how_many_gpt2s, scored([{"ada", 10}, {"grace", 0}]))

      standings = Ledger.standings(%{"ada" => "ada", "grace" => "grace"})

      assert [first, second] = standings
      assert first.handle == "ada"
      assert first.points == 25
      assert first.rounds == 2
      assert first.place == 1
      assert second.handle == "grace"
      assert second.points == 10
      assert second.rounds == 2
    end

    test "count a round answered even when it scored nothing" do
      Ledger.record(:open_weights, scored([{"ada", 0}]))

      assert [only] = Ledger.standings(%{"ada" => "ada"})
      assert only.rounds == 1
      assert only.points == 0
    end

    test "leave out somebody who never answered" do
      Ledger.record(:open_weights, scored([{"ada", 10}]))

      standings = Ledger.standings(%{"ada" => "ada", "absent" => "absent"})

      assert Enum.map(standings, & &1.handle) == ["ada"]
    end

    test "replace a round asked twice rather than paying for it twice" do
      Ledger.record(:open_weights, scored([{"ada", 15}]))
      Ledger.record(:open_weights, scored([{"ada", 10}]))

      assert [only] = Ledger.standings(%{"ada" => "ada"})
      assert only.points == 10
      assert only.rounds == 1
    end

    test "break a tie on points by handle, so the order is stable" do
      Ledger.record(:open_weights, scored([{"zoe", 10}, {"ada", 10}]))

      standings = Ledger.standings(%{"zoe" => "zoe", "ada" => "ada"})

      assert Enum.map(standings, & &1.handle) == ["ada", "zoe"]
      assert Enum.map(standings, & &1.place) == [1, 2]
    end

    test "are empty for a room that never answered anything" do
      assert Ledger.standings(%{}) == []
      assert Ledger.rounds_asked() == 0
    end
  end

  describe "the log" do
    test "replays every score after a restart" do
      Ledger.record(:open_weights, scored([{"ada", 15}]))
      Ledger.record(:how_many_gpt2s, scored([{"ada", 10}]))

      path = Ledger.path()
      GenServer.stop(Ledger)
      wait_for_restart()

      assert [only] = Ledger.standings(%{"ada" => "ada"})
      assert only.points == 25
      assert only.rounds == 2
      assert File.exists?(path)
    end
  end

  ## PRIVATE FUNCTIONS

  defp wait_for_restart, do: wait_for_restart(100)

  defp wait_for_restart(0), do: flunk("the ledger did not come back")

  defp wait_for_restart(attempts) do
    case Process.whereis(Ledger) do
      nil ->
        Process.sleep(10)
        wait_for_restart(attempts - 1)

      pid ->
        if Process.alive?(pid), do: :ok, else: wait_for_restart(attempts - 1)
    end
  end
end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `mix test test/model_name_talk/ledger_test.exs`
Expected: FAIL, `ModelNameTalk.Ledger.forget/0 is undefined`.

- [ ] **Step 3: Write the implementation**

Create `lib/model_name_talk/ledger.ex`:

```elixir
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
  record rather than pay for it twice.

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

    table =
      case :ets.whereis(@table) do
        :undefined -> :ets.new(@table, [:named_table, :public, :set])
        existing -> existing
      end

    replay(path)

    {:ok, %{path: path, table: table}}
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
    Path.join([
      Application.app_dir(:model_name_talk, "priv"),
      "rounds",
      "#{Date.utc_today()}.log"
    ])
  end

  # One line for each participant: the round, who, and what it paid. Plain
  # text, because the thing most likely to read it after the talk is a person.
  defp write(path, round, scored) do
    lines =
      Enum.map(scored, fn {token, result} ->
        "#{round}\t#{token}\t#{result.points}\n"
      end)

    File.write!(path, lines, [:append])
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

  defp replay_line(line) do
    case String.split(line, "\t") do
      [round, token, points] ->
        :ets.insert(@table, {{token, String.to_atom(round)}, String.to_integer(points)})

      _other ->
        :ok
    end
  end
end
```

Add to the children list in `lib/model_name_talk/application.ex`, after
`ModelNameTalk.Room`:

```elixir
      ModelNameTalk.Ledger,
```

Point the test environment at a scratch log. In `config/test.exs`:

```elixir
config :model_name_talk, ledger_path: "/tmp/model_name_talk_test_ledger.log"
```

and read it in `default_path/0` by changing the first line of that function to:

```elixir
  defp default_path do
    Application.get_env(:model_name_talk, :ledger_path) ||
      Path.join([
        Application.app_dir(:model_name_talk, "priv"),
        "rounds",
        "#{Date.utc_today()}.log"
      ])
  end
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `mix test test/model_name_talk/ledger_test.exs`
Expected: PASS, 7 tests.

- [ ] **Step 5: Commit**

```bash
mix format
git add lib/model_name_talk/ledger.ex test/model_name_talk/ledger_test.exs config/test.exs lib/model_name_talk/application.ex
git commit -m "Keep the scores in a table and on disk

The leaderboard is a fold over the answers rather than a counter, so it
cannot drift away from what people actually said, and a couple of hundred
rows is not worth optimising. The log is there so that a crash twenty minutes
into a talk costs nothing, and so that afterwards there is a record of which
idea the room got wrong."
```

---

### Task 7: Scoring a round when it is revealed

**Files:**
- Modify: `lib/model_name_talk/room.ex`
- Test: `test/model_name_talk/room_test.exs`

**Interfaces:**
- Consumes: `ModelNameTalk.Scoring.score/3`, `ModelNameTalk.Ledger.record/2`, `ModelNameTalk.Ledger.standings/1`
- Produces:
  - `ModelNameTalk.Room.standings() :: [map()]`
  - `ModelNameTalk.Room.handles(t()) :: %{String.t() => String.t()}`
  - revealing a round writes its scores to the ledger

- [ ] **Step 1: Write the failing test**

Append to `test/model_name_talk/room_test.exs`:

```elixir
  describe "revealing scores the round" do
    setup do
      ModelNameTalk.Ledger.forget()
      Room.open(:open_weights)
      Room.join("token-one", "ada", self())
      Room.join("token-two", "grace", elsewhere())
      :ok
    end

    test "pays the right answers and not the wrong ones" do
      Room.answer("token-one", "Qwen3")
      Room.answer("token-two", "Claude")
      Room.reveal()

      assert [only] = Room.standings()
      assert only.handle == "ada"
      assert only.points == 15
    end

    test "names people by the handle they chose" do
      Room.answer("token-one", "Qwen3")
      Room.reveal()

      assert [only] = Room.standings()
      assert only.handle == "ada"
    end

    test "adds a second round to the first" do
      Room.answer("token-one", "Qwen3")
      Room.reveal()

      Room.open(:how_many_gpt2s)
      Room.answer("token-one", "246")
      Room.reveal()

      assert [only] = Room.standings()
      assert only.points == 30
      assert only.rounds == 2
    end

    test "revealing twice does not pay twice" do
      Room.answer("token-one", "Qwen3")
      Room.reveal()
      Room.reveal()

      assert [only] = Room.standings()
      assert only.points == 15
    end

    test "scores nothing when nobody answered" do
      Room.reveal()

      assert Room.standings() == []
    end
  end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `mix test test/model_name_talk/room_test.exs`
Expected: FAIL, `ModelNameTalk.Room.standings/0 is undefined`.

- [ ] **Step 3: Write the implementation**

In `lib/model_name_talk/room.ex`, add the aliases:

```elixir
  alias ModelNameTalk.{Ledger, Round, Scoring}
```

replace the existing `handle_call(:reveal, ...)` clause for an open round with:

```elixir
  def handle_call(:reveal, _from, %__MODULE__{phase: :revealed} = room),
    do: {:reply, :ok, room}

  def handle_call(:reveal, _from, room) do
    room.round
    |> Round.fetch()
    |> Scoring.score(room.opened_at, room.answers)
    |> then(&Ledger.record(room.round, &1))

    {:reply, :ok, announce(%{room | phase: :revealed})}
  end
```

and add to the client section:

```elixir
  @doc "Everyone's handle, keyed by token, for naming people on the board."
  @spec handles(t()) :: %{String.t() => String.t()}
  def handles(%__MODULE__{participants: participants}) do
    Map.new(participants, fn {token, participant} -> {token, participant.handle} end)
  end

  @doc "The leaderboard, best first."
  @spec standings() :: [map()]
  def standings, do: __MODULE__.state() |> handles() |> Ledger.standings()
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `mix test`
Expected: PASS, the whole suite.

- [ ] **Step 5: Commit**

```bash
mix format
git add lib/model_name_talk/room.ex test/model_name_talk/room_test.exs
git commit -m "Pay the room when the answer goes up

Scoring waits for the reveal because the bonus depends on the order people
came in, and until answers are locked that order can still change. Revealing
a round twice replaces its record rather than paying for it again, so walking
back through the deck is safe."
```

---

### Task 8: The companion page

**Files:**
- Create: `lib/model_name_talk_web/live/play_live.ex`
- Create: `assets/css/play.css`
- Modify: `lib/model_name_talk_web/router.ex`
- Modify: `assets/css/app.css`
- Modify: `assets/js/app.js`
- Test: `test/model_name_talk_web/live/play_live_test.exs`

**Interfaces:**
- Consumes: `ModelNameTalk.Room`, `ModelNameTalk.Round`
- Produces: the route `/play`, and a `TokenKeeper` JS hook that mints and replays a token in `localStorage`

Four states and nothing else: asking for a handle, waiting, answering, and
the result. It never renders slide content, so it cannot drift out of sync
with a screenshare, and it stays readable on a phone held in one hand.

- [ ] **Step 1: Write the failing test**

Create `test/model_name_talk_web/live/play_live_test.exs`:

```elixir
defmodule ModelNameTalkWeb.PlayLiveTest do
  use ModelNameTalkWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ModelNameTalk.{Ledger, Room}

  setup do
    Room.reset()
    Ledger.forget()
    :ok
  end

  defp joined(conn, handle \\ "ada") do
    {:ok, view, _html} = live(conn, ~p"/play")
    render_hook(view, "token", %{"token" => "token-#{handle}"})
    render_submit(view, "handle", %{"handle" => handle})

    view
  end

  test "asks for a handle before anything else", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/play")

    assert html =~ "What should we call you"
  end

  test "says you are in once you have a handle", %{conn: conn} do
    view = joined(conn)

    assert render(view) =~ "You are in"
  end

  test "shows the question when a round opens", %{conn: conn} do
    view = joined(conn)

    Room.open(:open_weights)

    assert render(view) =~ "download the weights"
    assert render(view) =~ "Qwen3"
  end

  test "records an answer and says it landed", %{conn: conn} do
    view = joined(conn)
    Room.open(:open_weights)

    render_click(view, "answer", %{"value" => "Qwen3"})

    assert Room.state().answers["token-ada"].value == "Qwen3"
    assert render(view) =~ "Locked in"
  end

  test "takes a typed number on a numeric round", %{conn: conn} do
    view = joined(conn)
    Room.open(:how_many_gigabytes)

    render_submit(view, "answer", %{"value" => "74"})

    assert Room.state().answers["token-ada"].correct?
  end

  test "says how you did once the answer is revealed", %{conn: conn} do
    view = joined(conn)
    Room.open(:open_weights)
    render_click(view, "answer", %{"value" => "Qwen3"})

    Room.reveal()

    assert render(view) =~ "Right"
  end

  test "says you were wrong, and what the answer was", %{conn: conn} do
    view = joined(conn)
    Room.open(:open_weights)
    render_click(view, "answer", %{"value" => "Claude"})

    Room.reveal()

    html = render(view)
    assert html =~ "Not this time"
    assert html =~ "Qwen3"
  end

  test "keeps a returning phone's identity and score", %{conn: conn} do
    view = joined(conn)
    Room.open(:open_weights)
    render_click(view, "answer", %{"value" => "Qwen3"})
    Room.reveal()

    {:ok, returning, _html} = live(conn, ~p"/play")
    render_hook(returning, "token", %{"token" => "token-ada"})

    assert render(returning) =~ "ada"
    refute render(returning) =~ "What should we call you"
    assert Room.participant_count(Room.state()) == 1
    assert [%{points: 15}] = Room.standings()

    _ = view
  end
end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `mix test test/model_name_talk_web/live/play_live_test.exs`
Expected: FAIL, no route matches `/play`.

- [ ] **Step 3: Write the implementation**

Add the route in `lib/model_name_talk_web/router.ex`, inside the browser scope:

```elixir
    live "/play", PlayLive
```

Create `lib/model_name_talk_web/live/play_live.ex`:

```elixir
defmodule ModelNameTalkWeb.PlayLive do
  @moduledoc """
  What the audience plays on.

  One screen, no scrolling and no explanation: whatever the deck has open is
  what this shows, and when nothing is open it says so rather than inventing
  something to do. Somebody who joins late, or who answered a question twenty
  minutes ago and locked their phone, gets the current question the moment
  they look.

  It never draws slide content. The slides arrive over a screen share and this
  arrives over a websocket, so anything drawn in both places would disagree
  with itself by a second or two in front of everybody.

  The identity is a token in local storage rather than this process, which is
  the whole reason a phone can sleep here. The `TokenKeeper` hook mints one on
  a first visit and replays it on every reconnect.
  """

  use ModelNameTalkWeb, :live_view

  alias ModelNameTalk.{Room, Round}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Room.subscribe()

    {:ok,
     socket
     |> assign(room: nil, token: nil, handle: nil, answered: nil)
     |> assign(page_title: "How to Read a Model Name"), layout: false}
  end

  @impl true
  def handle_event("token", %{"token" => token}, socket) do
    room = Room.state()
    handle = get_in(room.participants, [token, Access.key(:handle)])

    socket = assign(socket, token: token, handle: handle, room: room)

    if handle, do: Room.join(token, handle, self())

    {:noreply, assign(socket, room: Room.state())}
  end

  def handle_event("handle", %{"handle" => handle}, socket) do
    handle = handle |> String.trim() |> String.slice(0, 24)

    case {handle, socket.assigns.token} do
      {"", _token} ->
        {:noreply, socket}

      {_handle, nil} ->
        {:noreply, socket}

      {handle, token} ->
        Room.join(token, handle, self())

        {:noreply, assign(socket, handle: handle, room: Room.state())}
    end
  end

  def handle_event("answer", %{"value" => value}, socket) do
    Room.answer(socket.assigns.token, value)

    {:noreply, assign(socket, answered: value, room: Room.state())}
  end

  @impl true
  def handle_info({:room, room}, socket) do
    {:noreply, socket |> assign(room: room) |> forget_stale_answer(room)}
  end

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(round: round(assigns))
      |> assign(mine: mine(assigns))

    ~H"""
    <main class="play" id="play" phx-hook="TokenKeeper">
      <p class="play__brand">How to Read a Model Name</p>

      <form :if={is_nil(@handle)} class="play__handle" phx-submit="handle">
        <label class="play__handle-label" for="handle">What should we call you?</label>
        <input class="play__handle-input" id="handle" name="handle" autocomplete="off" />
        <button class="play__handle-go" type="submit">Join</button>
      </form>

      <div :if={@handle && is_nil(@round)} class="play__idle">
        <p class="play__idle-title">You are in, {@handle}.</p>
        <p class="play__idle-body">Leave this open. A question will appear here.</p>
      </div>

      <div :if={@handle && @round} class="play__round">
        <p class="play__question">{@round.question}</p>
        <p :if={@round.hint} class="play__hint">{@round.hint}</p>

        <div :if={@round.type == :choice} class="play__options">
          <button
            :for={option <- @round.options}
            type="button"
            phx-click="answer"
            phx-value-value={option}
            disabled={@room.phase != :open}
            class={["play__option", @mine == option && "play__option--mine"]}
          >
            {option}
          </button>
        </div>

        <form :if={@round.type == :numeric} class="play__numeric" phx-submit="answer">
          <input
            class="play__numeric-input"
            name="value"
            inputmode="decimal"
            autocomplete="off"
            disabled={@room.phase != :open}
            value={@mine}
          />
          <button class="play__numeric-go" type="submit" disabled={@room.phase != :open}>
            Send
          </button>
        </form>

        <p :if={@mine && @room.phase == :open} class="play__state">Locked in. Change it if you like.</p>
        <p :if={is_nil(@mine) && @room.phase != :open} class="play__state">Time. You sat this one out.</p>

        <div :if={@room.phase == :revealed} class="play__result">
          <p :if={correct?(@round, @mine)} class="play__result-yes">Right.</p>
          <p :if={@mine && !correct?(@round, @mine)} class="play__result-no">Not this time.</p>
          <p class="play__result-answer">{answer_line(@round)}</p>
        </div>
      </div>
    </main>
    """
  end

  ## PRIVATE FUNCTIONS

  defp round(%{room: nil}), do: nil
  defp round(%{room: room}), do: Round.fetch(room.round)

  defp mine(%{room: nil}), do: nil
  defp mine(%{token: nil}), do: nil

  defp mine(%{room: room, token: token}) do
    get_in(room.answers, [token, Access.key(:value)])
  end

  defp correct?(_round, nil), do: false
  defp correct?(round, value), do: Round.correct?(round, value)

  defp answer_line(%Round{type: :choice, answer: answer}), do: "The answer: #{answer}"

  defp answer_line(%Round{type: :numeric, answer: answer, band: {low, high}}) do
    "The answer: about #{answer}. Anything from #{low} to #{high} counted."
  end

  # A new round clears the last one's answer, so the phone does not show a
  # choice belonging to a question nobody is asking any more.
  defp forget_stale_answer(socket, room) do
    if socket.assigns.room && socket.assigns.room.round != room.round do
      assign(socket, answered: nil)
    else
      socket
    end
  end
end
```

Add the hook in `assets/js/app.js`, alongside the existing hooks object:

```javascript
// The audience's identity lives in the phone, not in the socket. A locked
// phone, a discarded background tab and a browser crash all have to come back
// as the same player with the same score, and a LiveView process survives
// none of those.
Hooks.TokenKeeper = {
  mounted() {
    let token = null

    try {
      token = window.localStorage.getItem("mnt:token")
      if (!token) {
        token = crypto.randomUUID()
        window.localStorage.setItem("mnt:token", token)
      }
    } catch (error) {
      // Private browsing, or storage turned off. Play anonymously for as long
      // as this tab lives rather than refusing to let somebody join.
      token = crypto.randomUUID()
    }

    this.pushEvent("token", {token: token})
  }
}
```

Create `assets/css/play.css` with a phone first layout: a single column, large
tap targets at least 48px tall, high contrast, and no horizontal scrolling at
320px wide. Import it from `assets/css/app.css`:

```css
@import "./play.css";
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `mix test test/model_name_talk_web/live/play_live_test.exs`
Expected: PASS, 8 tests.

- [ ] **Step 5: Commit**

```bash
mix format
git add lib/model_name_talk_web/live/play_live.ex assets/css/play.css assets/css/app.css assets/js/app.js lib/model_name_talk_web/router.ex test/model_name_talk_web/live/play_live_test.exs
git commit -m "Give the audience one screen and four states

It never draws slide content. The slides arrive over a screen share and this
arrives over a websocket, so anything drawn in both places would disagree
with itself by a second or two in front of everybody.

The token comes from local storage rather than the socket, which is what lets
a phone lock in the middle of a talk and come back as the same player."
```

---

### Task 9: A stub deck that drives the game

**Files:**
- Create: `lib/model_name_talk_web/live/deck_live.ex`
- Create: `lib/model_name_talk_web/live/presenter_live.ex`
- Create: `lib/model_name_talk_web/position.ex`
- Modify: `lib/model_name_talk_web/router.ex`
- Modify: `config/config.exs`, `config/runtime.exs`
- Test: `test/model_name_talk_web/live/deck_live_test.exs`

**Interfaces:**
- Consumes: `ModelNameTalk.Room`, `ModelNameTalk.Round`
- Produces: routes `/` and `/presenter`, both synced over PubSub topic `"position"`

Enough deck to rehearse the game against: one slide per round, arrows to move,
the QR code on every slide, and the reveal on the second step. The real deck
is plan 2. What matters here is that the round lifecycle is driven by slide
position, so rehearsal exercises the thing the talk will actually do.

- [ ] **Step 1: Write the failing test**

Create `test/model_name_talk_web/live/deck_live_test.exs`:

```elixir
defmodule ModelNameTalkWeb.DeckLiveTest do
  use ModelNameTalkWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ModelNameTalk.{Ledger, Room}

  setup do
    Room.reset()
    Ledger.forget()
    :ok
  end

  test "opens the first round's question when it reaches that slide", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    render_keydown(view, "key", %{"key" => "ArrowRight"})

    assert Room.state().round == :open_weights
    assert render(view) =~ "download the weights"
  end

  test "reveals on the next press rather than moving on", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    render_keydown(view, "key", %{"key" => "ArrowRight"})

    render_keydown(view, "key", %{"key" => "ArrowRight"})

    assert Room.state().phase == :revealed
    assert Room.state().round == :open_weights
  end

  test "closes the round when it leaves the slide", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    render_keydown(view, "key", %{"key" => "ArrowRight"})
    render_keydown(view, "key", %{"key" => "ArrowRight"})

    render_keydown(view, "key", %{"key" => "ArrowRight"})

    assert Room.state().round == :how_many_gpt2s
  end

  test "re-opens a round when the speaker walks backwards", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    render_keydown(view, "key", %{"key" => "ArrowRight"})
    render_keydown(view, "key", %{"key" => "ArrowRight"})
    render_keydown(view, "key", %{"key" => "ArrowRight"})

    render_keydown(view, "key", %{"key" => "ArrowLeft"})

    assert Room.state().round == :open_weights
    assert Room.state().phase == :open
  end

  test "shows the answer count but never the tally before the reveal", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    render_keydown(view, "key", %{"key" => "ArrowRight"})
    Room.join("token-one", "ada", self())
    Room.answer("token-one", "Qwen3")

    html = render(view)

    assert html =~ "1 answered"
    refute html =~ "play__tally"
  end

  test "shows the QR code and the join URL on every slide", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/")

    assert html =~ "deck__join"
    render_keydown(view, "key", %{"key" => "ArrowRight"})
    assert render(view) =~ "deck__join"
  end

  test "renders every slide with an empty room", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    for _press <- 1..20 do
      assert render_keydown(view, "key", %{"key" => "ArrowRight"})
    end
  end

  test "the presenter view follows the deck", %{conn: conn} do
    {:ok, deck, _html} = live(conn, ~p"/")
    {:ok, presenter, _html} = live(conn, ~p"/presenter")

    render_keydown(deck, "key", %{"key" => "ArrowRight"})

    assert render(presenter) =~ "download the weights"
  end

  test "the presenter can end a round early", %{conn: conn} do
    {:ok, deck, _html} = live(conn, ~p"/")
    {:ok, presenter, _html} = live(conn, ~p"/presenter")
    render_keydown(deck, "key", %{"key" => "ArrowRight"})

    render_click(presenter, "lock", %{})

    assert Room.state().phase == :locked
  end
end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `mix test test/model_name_talk_web/live/deck_live_test.exs`
Expected: FAIL, no route matches `/`.

- [ ] **Step 3: Write the implementation**

Write `lib/model_name_talk_web/position.ex` holding the shared position over
PubSub topic `"position"`, with `subscribe/0`, `move/2` and `broadcast/1`.

Write `lib/model_name_talk_web/live/deck_live.ex` with a slide list built from
`Round.all()`: a title slide, then for each round one slide with two steps,
where step one opens the round and step two reveals it. Moving off a round
slide calls `Room.open(nil)`; moving onto one calls `Room.open(identifier)`.
Render the QR code from `Application.get_env(:model_name_talk, :join_url)`
using `EQRCode.encode/1` and `EQRCode.svg/2`, in a `deck__join` element
present on every slide.

Write `lib/model_name_talk_web/live/presenter_live.ex` rendering the same
slide plus the answer count, the tally after the reveal, the standings, and a
button sending `lock` that calls `Room.lock/0`.

Add both routes to the router. Add to `config/config.exs`:

```elixir
# What the QR code on every slide points a phone at. In production this is the
# tunnel host, because the audience is remote and nobody is on this network.
config :model_name_talk, join_url: "http://localhost:4000/play"
```

and to `config/runtime.exs`, inside the production branch:

```elixir
  config :model_name_talk, join_url: System.get_env("JOIN_URL") || "https://#{host}/play"
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `mix test`
Expected: PASS, the whole suite.

- [ ] **Step 5: Commit**

```bash
mix format
git add -A
git commit -m "Drive the rounds from the slide on screen

Arriving at a slide opens its round and leaving closes it, so there is no
second thing to manage while presenting and walking backwards asks the
question again. This deck is a stub: one slide for each round, enough to
rehearse the game against while the real slides are still unwritten.

The count of answers is on screen during a round but the tally is not.
Watching the bars move would tell the last ten people what everyone else
thinks, which is worth more to them than the question is."
```

---

### Task 10: Rehearsal notes and the verify table

**Files:**
- Create: `README.md`
- Create: `docs/verify.md`
- Test: none. This is documentation.

- [ ] **Step 1: Write `docs/verify.md`**

One row per fact, with columns: fact, value used, where it is used, source URL,
date checked, status. Seed it with the brief's eight `[VERIFY]` items plus
every number this plan hardcoded into a round: 124M for GPT-2 small, 30.5B,
109B and 17B for Llama-4-Scout, 70B and about 8.5 bits for Q8_0 giving the
68 to 80 band, 18.6 GB for Q4_K_M, and 12 GB for the RTX 3060.

Mark every row `not checked` until somebody checks it. Round 5's band is the
load bearing one: if Q8_0 is not about 8.5 bits for each weight, the round
scores people against a fiction.

- [ ] **Step 2: Write `README.md`**

Cover: what the talk is, the two windows and the join URL, how to run it, how
to start the tunnel, the keys, and the rule that the game is rehearsed before
the deck is written. Note that `cloudflared` is not yet installed.

- [ ] **Step 3: Commit**

```bash
git add README.md docs/verify.md
git commit -m "Write down what still has to be checked

Several of these numbers are now load bearing for scored questions rather
than for slides. If Q8_0 is not about eight and a half bits for each weight,
round five's tolerance band scores the audience against a fiction."
```

---

## Self-Review

**Spec coverage:**

| Spec section | Task |
|---|---|
| 4 Architecture, three LiveViews | 8, 9 |
| 4.1 Activity lifecycle from slide position | 9 |
| 4.2 Deployment, join_url, tunnel | 9, 10 |
| 5 The seven rounds | 2 |
| 5.1 Round mechanics, timer, lock early, no tally before reveal | 4, 9 |
| 5.2 Scoring, speed bonus, numeric exemption | 5 |
| 5.3 Numeric tolerance bands | 2, 5 |
| 5.4 Changing your mind | 4 |
| 6.1 Token identity | 3, 8 |
| 6.2 Log and replay | 6 |
| 6.3 Leaderboard, top 5 plus your line | 6, 7, 9 |
| 7 The deck | stub in 9, in full in plan 2 |
| 8 Testing | every task |
| 10 Verify table | 10 |

Spec section 7.3 (the file name header) and 7.4 (typography) belong to plan 2,
which covers the deck content. This plan builds only the stub deck needed to
rehearse the game, which is the approved game first sequence.

**Placeholder scan:** Task 9 step 3 and Task 10 describe files in prose rather
than giving complete code. That is deliberate for the stub deck, whose shape
is decided by plan 2, and for documentation. Every other step carries the code
it needs.

**Type consistency:** `Round.fetch/1` returns `t() | nil` and is called that
way in Room and PlayLive. `Scoring.score/3` returns a map keyed by token whose
values carry `:points`, `:correct?` and `:place`, which is what
`Ledger.record/2` reads and what `LedgerTest.scored/1` fakes.
`Ledger.standings/1` returns maps carrying `:token`, `:handle`, `:points`,
`:rounds` and `:place`, which is what `Room.standings/0` passes through.
