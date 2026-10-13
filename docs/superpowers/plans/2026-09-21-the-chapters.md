# The Chapters Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The talk itself: nine chapters that decode `Qwen3-30B-A3B-Instruct-2507-Q4_K_M.gguf` left to right, with a persistent file name header, term cards, speaker notes and the seven rounds already working.

**Architecture:** The running order is data in `ModelNameTalk.Deck`, one readable file that can be diffed against the brief. Drawing is separate: `ModelNameTalkWeb.SlideComponents` has one function clause per slide id, and any slide without a clause falls through to a hatched stub showing its title and notes. The file name is its own module, so the header on every slide and the annotated summary on the last slide are the same object in two states.

**Tech Stack:** Elixir 1.18.4, Phoenix 1.8.9, LiveView 1.2. Figures are inline SVG and CSS grid, no charting library.

**Spec:** `docs/superpowers/specs/2026-09-21-model-name-talk-design.md`

**Facts:** `docs/verify.md`. Every number on a slide must appear there with a source. Do not invent numbers. If a figure is not in that file, find a primary source and add a row, or leave the fact off the slide.

**Builds on:** `docs/superpowers/plans/2026-09-21-audience-game.md`, which is complete. The game works; `ModelNameTalk.Deck` currently holds a stub running order that this plan replaces.

## Global Constraints

- No em-dashes or dashes in prose, in speaker notes, in code comments or in commit messages.
- Descriptive names only. No single letter variables, no abbreviations. `competency` not `comp`.
- Public and private functions separated by a `## PRIVATE FUNCTIONS` comment.
- Prefer pattern matching over conditionals.
- Run `mix format` and `mix test` before every commit.
- **Body text on a slide stays under about 15 words.** Term cards are the only exception. The detail goes in the speaker notes.
- **Diagrams before bullets.** If the brief names a visual for a chapter, build the visual.
- **Every slide gets 2 to 5 sentences of speaker notes**, conversational.
- **Type is sized for a video codec.** The audience is remote and watching a screen share. Follow the sizes already in `assets/css/deck.css`; when in doubt, larger.
- Out of scope, per the brief: harnesses, agents, tool calls, MCP, RAG, fine tuning methods, RLHF, LoRA, how attention works, benchmark scores.

## Corrections this plan carries

Three things differ from the brief, all settled in `docs/verify.md`:

1. **The toy model has 15,104 parameters, not 13K.** Chapter 3 says 15K, and the comparison is approximately 2.0 million times.
2. **Chapter 7 is reframed.** The brief treats the gap between a predicted 15 GB and a real 18.6 GB as overhead to explain away. Measured against six real files, the formula is accurate to about one percent once the right bits for each weight goes in. The gap is the wrong constant, not overhead. Teach `4.8`, not `4` plus an apology.
3. **Q8_0 is 8.5 bits for each weight**, verified from the llama.cpp struct, and that fact is worth showing because it is exactly why the naive formula undershoots.

## File structure

| File | Responsibility |
|---|---|
| `lib/model_name_talk/filename.ex` | the file name as segments and their states |
| `lib/model_name_talk/section.ex` | one chapter: number, title, minutes, what it must land |
| `lib/model_name_talk/slide.ex` | one slide: id, title, notes, steps, round; notes parsing |
| `lib/model_name_talk/deck.ex` | the running order, as data. Replaces the stub. |
| `lib/model_name_talk_web/components/filename_components.ex` | the persistent header, and the annotated summary |
| `lib/model_name_talk_web/components/slide_components.ex` | one `slide/1` clause per slide id |
| `lib/model_name_talk_web/components/figure_components.ex` | the diagrams the brief names |
| `lib/model_name_talk_web/live/presenter_live.ex` | grows notes, a section clock and a pace line |
| `assets/css/figures.css` | figure styling, separate from `deck.css` |

`slide_components.ex` will be the largest file. Split it when it passes roughly 600 lines, by chapter, into `slide_components/chapter_seven.ex` and so on, with the main module delegating.

---

### Task 1: The file name as segments

**Files:**
- Create: `lib/model_name_talk/filename.ex`
- Test: `test/model_name_talk/filename_test.exs`

**Interfaces:**
- Consumes: nothing
- Produces:
  - `%ModelNameTalk.Filename.Segment{text: String.t(), chapter: pos_integer(), label: String.t(), author: :vendor | :converter}`
  - `ModelNameTalk.Filename.segments() :: [Segment.t()]`
  - `ModelNameTalk.Filename.text() :: String.t()`
  - `ModelNameTalk.Filename.state(Segment.t(), chapter :: pos_integer() | nil) :: :done | :current | :pending`

The whole talk hangs off this. The header on every content slide and the
annotated name on the last slide are the same list in two presentations, and
chapter 8's payoff is the `author` field made visible.

- [ ] **Step 1: Write the failing test**

Create `test/model_name_talk/filename_test.exs`:

```elixir
defmodule ModelNameTalk.FilenameTest do
  use ExUnit.Case, async: true

  alias ModelNameTalk.Filename

  test "joins back into the name the talk decodes" do
    assert Filename.text() == "Qwen3-30B-A3B-Instruct-2507-Q4_K_M.gguf"
  end

  test "names a segment for each chapter that has one" do
    chapters = Filename.segments() |> Enum.map(& &1.chapter)

    assert chapters == [2, 3, 4, 5, 6, 7, 8]
  end

  test "gives every segment a one line label" do
    for segment <- Filename.segments() do
      assert segment.label != ""
      assert segment.text != ""
    end
  end

  test "splits the name between its two authors" do
    by_author = Enum.group_by(Filename.segments(), & &1.author, & &1.text)

    assert by_author.vendor == ~w(Qwen3 30B A3B Instruct 2507)
    assert by_author.converter == ["Q4_K_M", ".gguf"]
  end

  describe "state/2" do
    test "lights the chapter on screen and dims the ones behind it" do
      segments = Filename.segments()
      states = Enum.map(segments, &Filename.state(&1, 4))

      assert states == [:done, :done, :current, :pending, :pending, :pending, :pending]
    end

    test "leaves everything pending before the first chapter with a segment" do
      states = Enum.map(Filename.segments(), &Filename.state(&1, 1))

      assert Enum.all?(states, &(&1 == :pending))
    end

    test "shows the whole name as done at the close" do
      states = Enum.map(Filename.segments(), &Filename.state(&1, 9))

      assert Enum.all?(states, &(&1 == :done))
    end

    test "treats a slide with no chapter as showing nothing yet" do
      states = Enum.map(Filename.segments(), &Filename.state(&1, nil))

      assert Enum.all?(states, &(&1 == :pending))
    end
  end
end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `mix test test/model_name_talk/filename_test.exs`
Expected: FAIL, `ModelNameTalk.Filename.text/0 is undefined`.

- [ ] **Step 3: Write the implementation**

Create `lib/model_name_talk/filename.ex`:

```elixir
defmodule ModelNameTalk.Filename do
  @moduledoc """
  The name the talk decodes, in pieces.

  One segment for each chapter, in the order a reader meets them. The header
  on every content slide is this list with one segment lit, and the annotated
  name on the last slide is the same list with every label shown. Keeping it
  in one place means the summary slide cannot drift away from the header the
  room has been watching all talk.

  The `author` field is chapter 8's payoff. The vendor wrote everything up to
  the date stamp; somebody else entirely, converting the model for llama.cpp,
  wrote the quantisation and the extension. The name has two authors and the
  header can show exactly where the handover is.
  """

  defmodule Segment do
    @moduledoc "One piece of the name, and what it tells you."

    @enforce_keys [:text, :chapter, :label, :author]
    defstruct [:text, :chapter, :label, :author]

    @type t :: %__MODULE__{
            text: String.t(),
            chapter: pos_integer(),
            label: String.t(),
            author: :vendor | :converter
          }
  end

  @segments [
    %Segment{text: "Qwen3", chapter: 2, author: :vendor, label: "family and generation"},
    %Segment{text: "30B", chapter: 3, author: :vendor, label: "total parameters"},
    %Segment{text: "A3B", chapter: 4, author: :vendor, label: "active for each token"},
    %Segment{text: "Instruct", chapter: 5, author: :vendor, label: "post-trained to answer"},
    %Segment{text: "2507", chapter: 6, author: :vendor, label: "July 2025"},
    %Segment{text: "Q4_K_M", chapter: 7, author: :converter, label: "4 bits, k-quant, medium"},
    %Segment{text: ".gguf", chapter: 8, author: :converter, label: "llama.cpp's format"}
  ]

  @doc "Every segment, left to right."
  @spec segments() :: [Segment.t()]
  def segments, do: @segments

  @doc "The whole name, as it appears on disk."
  @spec text() :: String.t()
  def text do
    @segments
    |> Enum.map(& &1.text)
    |> Enum.reduce(fn segment, joined ->
      if String.starts_with?(segment, "."), do: joined <> segment, else: joined <> "-" <> segment
    end)
  end

  @doc """
  How a segment is drawn while a given chapter is on screen: the chapter's own
  segment is lit, the ones already explained are dimmed, and the rest are
  waiting.
  """
  @spec state(Segment.t(), pos_integer() | nil) :: :done | :current | :pending
  def state(_segment, nil), do: :pending

  def state(%Segment{chapter: chapter}, showing) do
    cond do
      chapter < showing -> :done
      chapter == showing -> :current
      true -> :pending
    end
  end
end
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `mix test test/model_name_talk/filename_test.exs`
Expected: PASS, 8 tests.

- [ ] **Step 5: Commit**

```bash
mix format
git add lib/model_name_talk/filename.ex test/model_name_talk/filename_test.exs
git commit -m "Put the file name in one place

The header on every slide and the annotated name at the close are the same
list in two presentations, so the summary the room photographs cannot drift
away from the header it has been reading for forty minutes.

The author field is chapter 8's payoff sitting in the data from the start.
The vendor wrote up to the date stamp and a stranger wrote the rest, and the
header can show where the handover is rather than asserting it."
```

---

### Task 2: The header, and the annotated name

**Files:**
- Create: `lib/model_name_talk_web/components/filename_components.ex`
- Modify: `assets/css/deck.css`
- Test: `test/model_name_talk_web/components/filename_components_test.exs`

**Interfaces:**
- Consumes: `ModelNameTalk.Filename`
- Produces:
  - `<.filename chapter={4} />` the persistent header
  - `<.filename chapter={4} authors={true} />` the same, with the two author spans marked
  - `<.annotated />` the close's summary slide, every segment with its label

- [ ] **Step 1: Write the failing test**

Create `test/model_name_talk_web/components/filename_components_test.exs`:

```elixir
defmodule ModelNameTalkWeb.FilenameComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import ModelNameTalkWeb.FilenameComponents

  test "draws every segment of the name" do
    html = render_component(&filename/1, chapter: 4)

    for segment <- ModelNameTalk.Filename.segments() do
      assert html =~ segment.text
    end
  end

  test "marks the chapter on screen, what is behind it, and what is ahead" do
    html = render_component(&filename/1, chapter: 4)

    assert html =~ "filename__segment--current"
    assert html =~ "filename__segment--done"
    assert html =~ "filename__segment--pending"
  end

  test "marks nothing current before the first chapter with a segment" do
    html = render_component(&filename/1, chapter: 1)

    refute html =~ "filename__segment--current"
  end

  test "names the two authors only when asked" do
    plain = render_component(&filename/1, chapter: 8)
    split = render_component(&filename/1, chapter: 8, authors: true)

    refute plain =~ "filename__author"
    assert split =~ "filename__author"
    assert split =~ "Qwen"
    assert split =~ "whoever converted it"
  end

  test "the annotated name carries a label for every segment" do
    html = render_component(&annotated/1, %{})

    for segment <- ModelNameTalk.Filename.segments() do
      assert html =~ segment.text
      assert html =~ segment.label
    end
  end
end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `mix test test/model_name_talk_web/components/filename_components_test.exs`
Expected: FAIL, module not available.

- [ ] **Step 3: Write the implementation**

Create `lib/model_name_talk_web/components/filename_components.ex`:

```elixir
defmodule ModelNameTalkWeb.FilenameComponents do
  @moduledoc """
  The file name, drawn.

  The header is the progress bar of this talk. It sits on every content slide,
  it never moves, and the only thing that changes is which segment is lit. By
  the close the room has looked at it thirty times, which is what makes the
  annotated version worth photographing.

  It is set in monospace at a size that looks excessive on a laptop. It is not
  excessive: this reaches people through a screen share, and a long monospace
  string is the first thing a video codec ruins.
  """

  use Phoenix.Component

  alias ModelNameTalk.Filename

  attr :chapter, :integer, default: nil
  attr :authors, :boolean, default: false

  @doc "The name across the top of a slide, with the current chapter lit."
  def filename(assigns) do
    assigns = assign(assigns, segments: Filename.segments())

    ~H"""
    <header class={["filename", @authors && "filename--authors"]}>
      <p :if={@authors} class="filename__author filename__author--vendor">Qwen wrote this</p>

      <p class="filename__name">
        <span
          :for={segment <- @segments}
          class={["filename__segment", "filename__segment--#{Filename.state(segment, @chapter)}"]}
        >{separator(segment)}{segment.text}</span>
      </p>

      <p :if={@authors} class="filename__author filename__author--converter">
        whoever converted it wrote this
      </p>
    </header>
    """
  end

  @doc """
  The close's summary: every segment with its label underneath.

  This is the slide people photograph, so it is the one slide in the deck
  allowed to be dense.
  """
  def annotated(assigns) do
    assigns = assign(assigns, segments: Filename.segments())

    ~H"""
    <div class="annotated">
      <div :for={segment <- @segments} class="annotated__column">
        <p class="annotated__segment">{segment.text}</p>
        <p class="annotated__label">{segment.label}</p>
      </div>
    </div>
    """
  end

  ## PRIVATE FUNCTIONS

  # The extension hangs off the name without a dash, every other segment takes
  # one. Drawing the separator with its segment keeps the header one flex row
  # rather than a string that has to be re-split to be styled.
  defp separator(%Filename.Segment{text: "." <> _rest}), do: ""
  defp separator(%Filename.Segment{chapter: 2}), do: ""
  defp separator(_segment), do: "-"
end
```

Add to `assets/css/deck.css`: `.filename` as a flex row, monospace, with
`--done` at `var(--deck-dim)`, `--current` at `var(--deck-lit)` and bold, and
`--pending` at a dimmer grey. `.filename--authors` draws a bracket or rule
under each author's run. `.annotated` is a CSS grid, one column per segment,
segment in monospace above its label.

- [ ] **Step 4: Run the test to verify it passes**

Run: `mix test test/model_name_talk_web/components/filename_components_test.exs`
Expected: PASS, 5 tests.

- [ ] **Step 5: Commit**

```bash
mix format
git add lib/model_name_talk_web/components/filename_components.ex assets/css/deck.css test/model_name_talk_web/components/filename_components_test.exs
git commit -m "Draw the header that is the talk's progress bar

Thirty slides of looking at the same string with one piece lit is what makes
the annotated version at the close worth photographing. The two are the same
list, so they cannot disagree."
```

---

### Task 3: Sections, slides and speaker notes

**Files:**
- Create: `lib/model_name_talk/section.ex`
- Create: `lib/model_name_talk/slide.ex`
- Test: `test/model_name_talk/slide_test.exs`

**Interfaces:**
- Consumes: nothing
- Produces:
  - `%ModelNameTalk.Section{number: pos_integer(), title: String.t(), minutes: number(), lands: String.t(), slides: [Slide.t()]}`
  - `%ModelNameTalk.Slide{id: atom(), title: String.t(), notes: String.t(), steps: pos_integer(), round: atom() | nil, chapter: pos_integer() | nil, section: pos_integer() | nil, index: pos_integer() | nil}`
  - `ModelNameTalk.Slide.blocks(Slide.t()) :: [{:cues, [String.t()]} | {:musts, [String.t()]} | {:definitions, [{String.t(), String.t()}]}]`
  - `ModelNameTalk.Slide.prose(Slide.t()) :: String.t()`

The notes format is carried over from `tiny_llm_talk`: `-` is a cue, `!` is a
point that must be said out loud, `=` is `term: definition`. That third kind
maps exactly onto the brief's term cards, so a chapter's term card and its
notes are the same text.

- [ ] **Step 1: Write the failing test**

Create `test/model_name_talk/slide_test.exs`:

```elixir
defmodule ModelNameTalk.SlideTest do
  use ExUnit.Case, async: true

  alias ModelNameTalk.Slide

  defp slide(notes), do: %Slide{id: :example, title: "Example", notes: notes}

  test "reads a run of cues" do
    blocks = Slide.blocks(slide("- first\n- second\n"))

    assert blocks == [{:cues, ["first", "second"]}]
  end

  test "reads a point that must be said out loud" do
    blocks = Slide.blocks(slide("! say this\n"))

    assert blocks == [{:musts, ["say this"]}]
  end

  test "reads a definition as a term and its meaning" do
    blocks = Slide.blocks(slide("= token: what the model reads\n"))

    assert blocks == [{:definitions, [{"token", "what the model reads"}]}]
  end

  test "keeps a colon inside a definition's meaning" do
    blocks = Slide.blocks(slide("= ratio: one thing: another\n"))

    assert blocks == [{:definitions, [{"ratio", "one thing: another"}]}]
  end

  test "groups consecutive lines of one kind and keeps their order" do
    blocks = Slide.blocks(slide("- a\n! b\n- c\n= d: e\n"))

    assert blocks == [
             {:cues, ["a"]},
             {:musts, ["b"]},
             {:cues, ["c"]},
             {:definitions, [{"d", "e"}]}
           ]
  end

  test "continues an item on the line after it" do
    blocks = Slide.blocks(slide("- a long cue\n  that wrapped\n"))

    assert blocks == [{:cues, ["a long cue that wrapped"]}]
  end

  test "ignores blank lines" do
    assert Slide.blocks(slide("\n\n- a\n\n")) == [{:cues, ["a"]}]
  end

  test "has no blocks when there are no notes" do
    assert Slide.blocks(slide("")) == []
  end

  test "flattens to one paragraph for the stub" do
    prose = Slide.prose(slide("- a\n! b\n= c: d\n"))

    assert prose == "a b c: d"
  end
end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `mix test test/model_name_talk/slide_test.exs`
Expected: FAIL, `ModelNameTalk.Slide.__struct__/1 is undefined`.

- [ ] **Step 3: Write the implementation**

Create `lib/model_name_talk/section.ex`:

```elixir
defmodule ModelNameTalk.Section do
  @moduledoc """
  One chapter, with the minutes the brief gives it and the one thing it has to
  land. The presenter view shows both, because the only two questions a
  speaker asks mid-talk are where am I and am I behind.
  """

  @enforce_keys [:number, :title, :minutes, :lands, :slides]
  defstruct [:number, :title, :minutes, :lands, :slides]

  @type t :: %__MODULE__{
          number: pos_integer(),
          title: String.t(),
          minutes: number(),
          lands: String.t(),
          slides: [ModelNameTalk.Slide.t()]
        }
end
```

Create `lib/model_name_talk/slide.ex`:

```elixir
defmodule ModelNameTalk.Slide do
  @moduledoc """
  One slide.

  `id` is what the renderer matches on, so a slide's drawing lives in
  `ModelNameTalkWeb.SlideComponents` as a clause named by this atom and
  nowhere else. `steps` is how many presses it takes before the deck moves on,
  which is what lets a figure arrive a piece at a time. `round` names the
  question this slide asks, if it asks one. `chapter` is which segment of the
  file name the header should light.
  """

  @enforce_keys [:id, :title]
  defstruct [:id, :title, :round, :chapter, :section, :index, notes: "", steps: 1]

  @type t :: %__MODULE__{
          id: atom(),
          title: String.t(),
          round: atom() | nil,
          chapter: pos_integer() | nil,
          section: pos_integer() | nil,
          index: pos_integer() | nil,
          notes: String.t(),
          steps: pos_integer()
        }

  @typedoc "A run of cues, a run of things that must be said, or a run of definitions."
  @type block ::
          {:cues, [String.t()]}
          | {:musts, [String.t()]}
          | {:definitions, [{String.t(), String.t()}]}

  @doc """
  The notes as blocks for the presenter. A line starting with `- ` is a cue,
  `! ` is a point that must be made out loud, and `= ` is a definition written
  `term: what it means`. Any other line continues the item before it.
  Consecutive items of one kind are grouped, so the presenter can draw a list,
  then a glossary, then a list again.

  The definitions are also the chapter's term card, which is why the two
  cannot disagree: they are one piece of text.
  """
  @spec blocks(t()) :: [block()]
  def blocks(%__MODULE__{notes: notes}) do
    notes
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.reduce([], &add_line/2)
    |> Enum.reverse()
    |> Enum.map(fn {kind, items} -> {kind, Enum.reverse(items)} end)
  end

  @doc "The notes as one paragraph, for the stub slide and for checking a slide has any."
  @spec prose(t()) :: String.t()
  def prose(slide) do
    slide
    |> blocks()
    |> Enum.flat_map(fn
      {:cues, items} -> items
      {:musts, items} -> items
      {:definitions, pairs} -> Enum.map(pairs, fn {term, text} -> term <> ": " <> text end)
    end)
    |> Enum.join(" ")
  end

  ## PRIVATE FUNCTIONS

  defp add_line("- " <> text, [{:cues, items} | rest]), do: [{:cues, [text | items]} | rest]
  defp add_line("- " <> text, blocks), do: [{:cues, [text]} | blocks]

  defp add_line("! " <> text, [{:musts, items} | rest]), do: [{:musts, [text | items]} | rest]
  defp add_line("! " <> text, blocks), do: [{:musts, [text]} | blocks]

  defp add_line("= " <> text, [{:definitions, pairs} | rest]),
    do: [{:definitions, [definition(text) | pairs]} | rest]

  defp add_line("= " <> text, blocks), do: [{:definitions, [definition(text)]} | blocks]

  # Any other line continues the item above it, so a long cue can wrap in the
  # source without becoming two cues on the speaker's screen.
  defp add_line(text, [{kind, [latest | rest]} | blocks]) do
    [{kind, [join(kind, latest, text) | rest]} | blocks]
  end

  defp add_line(_text, blocks), do: blocks

  defp join(:definitions, {term, meaning}, text), do: {term, meaning <> " " <> text}
  defp join(_kind, latest, text), do: latest <> " " <> text

  defp definition(text) do
    case String.split(text, ": ", parts: 2) do
      [term, meaning] -> {term, meaning}
      [term] -> {term, ""}
    end
  end
end
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `mix test test/model_name_talk/slide_test.exs`
Expected: PASS, 9 tests.

- [ ] **Step 5: Commit**

```bash
mix format
git add lib/model_name_talk/section.ex lib/model_name_talk/slide.ex test/model_name_talk/slide_test.exs
git commit -m "Give a slide notes, and a chapter something it has to land

The notes format carries over from the last deck: a cue, a thing that must be
said out loud, and a definition. That third kind is also the chapter's term
card, so the card the room reads and the glossary the speaker reads are one
piece of text and cannot drift apart."
```

---

### Task 4: The running order

**Files:**
- Modify: `lib/model_name_talk/deck.ex` (replaces the stub entirely)
- Test: `test/model_name_talk/deck_test.exs`

**Interfaces:**
- Consumes: `ModelNameTalk.{Section, Slide, Round, Filename}`
- Produces:
  - `ModelNameTalk.Deck.sections() :: [Section.t()]`
  - `ModelNameTalk.Deck.slides() :: [Slide.t()]` flattened, each with `section`, `index` and `chapter` filled in
  - `ModelNameTalk.Deck.at(index) :: Slide.t()`, `length/0`, `clamp/1` unchanged in signature
  - `ModelNameTalk.Deck.section(Slide.t()) :: Section.t()`
  - `ModelNameTalk.Deck.minutes_before(Section.t()) :: number()`

This is the content task. Everything after it is drawing.

The stub's `slides/0` built one slide per round; that goes. `Position` and
both LiveViews already call `at/1`, `length/0` and `clamp/1` and keep working
unchanged, and the round lifecycle keeps working because round slides still
carry `round:`.

- [ ] **Step 1: Write the failing test**

Create `test/model_name_talk/deck_test.exs`:

```elixir
defmodule ModelNameTalk.DeckTest do
  use ExUnit.Case, async: true

  alias ModelNameTalk.{Deck, Filename, Round, Slide}

  test "runs the nine chapters the brief names, in order" do
    numbers = Enum.map(Deck.sections(), & &1.number)

    assert numbers == [1, 2, 3, 4, 5, 6, 7, 8, 9]
  end

  test "gives every section minutes and something it has to land" do
    for section <- Deck.sections() do
      assert section.minutes > 0
      assert section.lands != ""
      assert section.slides != []
    end
  end

  test "budgets about forty two minutes" do
    total = Deck.sections() |> Enum.map(& &1.minutes) |> Enum.sum()

    assert_in_delta total, 42, 1.5
  end

  test "gives every slide a unique id" do
    identifiers = Enum.map(Deck.slides(), & &1.id)

    assert length(identifiers) == length(Enum.uniq(identifiers))
  end

  test "gives every slide speaker notes" do
    for slide <- Deck.slides() do
      assert Slide.prose(slide) != "", "#{slide.id} has no notes"
    end
  end

  test "numbers every slide with its section and its place in the deck" do
    slides = Deck.slides()

    assert Enum.map(slides, & &1.index) == Enum.to_list(1..length(slides))
    assert Enum.all?(slides, &(&1.section != nil))
  end

  test "asks every round exactly once, in the order the rounds are written" do
    asked = Deck.slides() |> Enum.map(& &1.round) |> Enum.reject(&is_nil/1)

    assert asked == Enum.map(Round.all(), & &1.id)
  end

  test "gives every round slide two steps, so the answer waits for a press" do
    for slide <- Deck.slides(), slide.round do
      assert slide.steps == 2
    end
  end

  test "puts each round in the chapter whose segment it follows" do
    for slide <- Deck.slides(), slide.round do
      round = Round.fetch(slide.round)
      segment = Enum.find(Filename.segments(), &(&1.chapter == slide.chapter))

      assert segment.text == round.after_segment
    end
  end

  test "gives a chapter to every slide that should light a segment" do
    chapters = Deck.slides() |> Enum.map(& &1.chapter) |> Enum.uniq() |> Enum.reject(&is_nil/1)

    assert Enum.sort(chapters) == [2, 3, 4, 5, 6, 7, 8]
  end

  test "ends each chapter that has terms with a term card" do
    cards = Deck.slides() |> Enum.filter(&String.ends_with?(to_string(&1.id), "_terms"))

    assert length(cards) >= 5

    for card <- cards do
      definitions =
        card |> Slide.blocks() |> Enum.filter(&match?({:definitions, _pairs}, &1))

      refute definitions == [], "#{card.id} is a term card with no definitions"
    end
  end

  test "finds the section a slide belongs to, and the minutes before it" do
    [first | _rest] = Deck.slides()

    assert Deck.section(first).number == 1
    assert Deck.minutes_before(Deck.section(first)) == 0
  end
end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `mix test test/model_name_talk/deck_test.exs`
Expected: FAIL, `ModelNameTalk.Deck.sections/0 is undefined`.

- [ ] **Step 3: Write the implementation**

Replace `lib/model_name_talk/deck.ex`. Structure:

```elixir
defmodule ModelNameTalk.Deck do
  @moduledoc """
  The talk, as data.

  Nothing here draws anything. A slide is a title, some notes, a count of
  reveal steps and the chapter whose segment it lights;
  `ModelNameTalkWeb.SlideComponents` matches on the id to draw it. Keeping the
  arc as a list means the running order is one readable file that can be
  diffed against the brief rather than something recovered by reading
  templates.

  The arc is one file name, read left to right. Every chapter takes one
  segment, explains it, and ends by asking the room a question about it.
  """

  alias ModelNameTalk.{Section, Slide}

  @sections [
    # ... the nine sections, written out below
  ]
end
```

The nine sections, with every slide. Notes are written in the three line
kinds from Task 3. Times sum to about 42 minutes per the spec's budget.

**Section 1, Opening, 2 minutes.** Lands: the room knows what it will be able
to do in forty minutes.

| id | title | steps | chapter | notes |
|---|---|---|---|---|
| `:title` | How to Read a Model Name | 1 | nil | cue: say the title once. must: by the end you can read this and know if it fits on your machine. cue: join now, the QR is on every slide |
| `:the_name` | (the name, very large) | 1 | nil | must: in forty minutes you will be able to read every part of this. cue: do not explain anything yet. cue: let it sit for a beat |

**Section 2, `Qwen3`, 4 minutes.** Lands: a model is a file of numbers plus an
architecture, and some vendors give you the file.

| id | title | steps | chapter | notes |
|---|---|---|---|---|
| `:qwen3_chapter` | Qwen3 | 1 | 2 | cue: chapter title, segment very large |
| `:open_or_closed` | Open weights, or an API | 2 | 2 | must: open weights is not open source, the training data and code are not published. cue: Qwen ships you a file. cue: Claude and GPT you reach through an endpoint |
| `:what_a_model_is` | A model is numbers, plus a shape | 1 | 2 | must: the weights are the numbers training moved. must: the architecture is the program that knows what to do with them. cue: our toy model was both, in one repo |
| `:tokens_again` | A token is not a word | 1 | 2 | cue: one word was one token in the toy model. cue: real models use pieces of words. cue: Qwen3's vocabulary is 151,936 |
| `:qwen3_terms` | The words so far | 1 | 2 | definitions for model, weights, checkpoint, family and generation, open weights, token |
| `:round_open_weights` | Which one ships you a file? | 2 | 2 | round `:open_weights` |

**Section 3, `30B`, 5 minutes.** Lands: a parameter here is the same object as
a parameter in the toy model, only there are more of them.

| id | title | steps | chapter | notes |
|---|---|---|---|---|
| `:thirty_b_chapter` | 30B | 1 | 3 | cue: chapter title |
| `:b_is_billion` | B is billion | 1 | 3 | cue: 30.5 billion, exactly 30,532,122,624. cue: M is million |
| `:how_big` | Our model, GPT-2, this one | 3 | 3 | must: same kind of number, two million times as many. cue: log scale, say so out loud. cue: 15,104 then 124M then 30.5B |
| `:what_it_buys` | Size is memory, and a hint about capability | 1 | 3 | must: parameter count causes memory and cost directly. cue: it only suggests capability. cue: closed vendors often do not publish it |
| `:thirty_b_terms` | The words so far | 1 | 3 | definitions for parameter count, dense model |
| `:round_how_many` | How many GPT-2s fit inside? | 2 | 3 | round `:how_many_gpt2s` |

**Section 4, `A3B`, 6 minutes.** Lands: total parameters set the memory,
active parameters set the speed.

| id | title | steps | chapter | notes |
|---|---|---|---|---|
| `:a3b_chapter` | A3B | 1 | 4 | cue: chapter title. cue: the A is the whole point |
| `:dense_or_sparse` | One big block, or many small ones | 3 | 4 | cue: dense layer on the left, one feed forward block. cue: MoE on the right, 128 small ones and a router. cue: 8 light up |
| `:not_specialists` | The experts are not subject specialists | 1 | 4 | must: there is no maths expert and no French expert. must: the routing is learned for each token and each layer, and a person usually cannot read it. cue: this is the most common wrong idea about MoE |
| `:memory_and_speed` | Total sets memory, active sets speed | 2 | 4 | must: every expert must be in memory, because the next token may need a different one. must: but only 3B of arithmetic happens for each token. cue: attention is not split, all tokens use it |
| `:a3b_terms` | The words so far | 1 | 4 | definitions for mixture of experts, expert, router, active parameters |
| `:round_memory_speed` | Scout: memory like what, speed like what? | 2 | 4 | round `:memory_versus_speed` |

**Section 5, `Instruct`, 5 minutes.** Lands: a base model continues text, and
post-training is what makes it answer.

| id | title | steps | chapter | notes |
|---|---|---|---|---|
| `:instruct_chapter` | Instruct | 1 | 5 | cue: chapter title |
| `:the_pipeline` | Corpus, then base, then this | 3 | 5 | cue: pre-training is next token prediction at enormous scale. cue: the toy model did the same thing on five sentences. cue: post-training is more training that makes it follow instructions |
| `:base_continues` | A base model continues the document | 2 | 5 | must: ask a base model a question and it may write more questions. must: it is not being unhelpful, it is doing exactly its job. cue: this is the demo |
| `:demo_base_instruct` | DEMO | 1 | 5 | cue: same prompt, Qwen3-4B-Base and Qwen3-4B-Instruct-2507. cue: base continues, instruct answers. cue: if it fails, next slide has the screenshot |
| `:demo_base_instruct_fallback` | (fallback screenshot) | 1 | 5 | cue: the screenshot, in case the demo will not run |
| `:chat_template` | The model only ever sees one string | 2 | 5 | must: there is no such thing as a message to a model. must: the chat template is text with special tokens around it. cue: show the raw Qwen format |
| `:other_words` | Base, Chat, it, Coder, VL, Distill | 1 | 5 | cue: two or three words each, no more. cue: it is Gemma's word for instruct |
| `:instruct_terms` | The words so far | 1 | 5 | definitions for pre-training, base model, post-training, instruct and thinking, chat template |
| `:round_base_completion` | What comes back from a base model? | 2 | 5 | round `:base_completion` |

**Section 6, `2507`, 2 minutes.** Lands: pin the version the way you pin a
dependency.

| id | title | steps | chapter | notes |
|---|---|---|---|---|
| `:date_chapter` | 2507 | 1 | 6 | cue: chapter title. cue: July 2025 |
| `:same_name_different_model` | The name stayed. The model did not. | 3 | 6 | cue: April 2025, one model with a thinking switch. cue: July 2025, that became two models. cue: the context went from 32K to 262,144, and natively. must: pin the version like a dependency. must: the date stamp is not the knowledge cutoff |

**Section 7, `Q4_K_M`, 9 minutes.** Lands: the formula works, once you put the
right number of bits into it.

| id | title | steps | chapter | notes |
|---|---|---|---|---|
| `:quant_chapter` | Q4_K_M | 1 | 7 | cue: chapter title. cue: this is the technical centre |
| `:precision` | How many bits for each weight | 2 | 7 | cue: FP32 four bytes, BF16 two, INT8 one, 4-bit a half. cue: vendors usually publish at 16 |
| `:the_formula` | parameters x bits / 8 | 1 | 7 | must: this is the one thing to take home. cue: alone on the slide, very large |
| `:the_method` | A scale, and sixteen levels | 3 | 7 | cue: cut the weights into blocks of 32. cue: store one scale for the block and a small integer for each weight. cue: four bits is sixteen levels. cue: walk the worked example |
| `:why_blocks` | One huge weight would ruin a whole tensor | 1 | 7 | must: small blocks keep the damage local. cue: this is the entire reason for blocks |
| `:the_label` | Q4 K M, one piece at a time | 3 | 7 | cue: Q4 is four bits. cue: K is llama.cpp's k-quant, which also quantises the scales. cue: M is medium, the sensitive tensors keep more bits |
| `:the_real_cost` | 34 bytes for 32 weights | 2 | 7 | must: Q8_0 is not 8 bits, it is 8.5. must: every block of 32 carries a 2 byte scale. cue: show the struct, it is four lines. cue: this is why the naive formula undershoots |
| `:does_it_work` | The formula against real files | 3 | 7 | must: within about one percent, every time. cue: 4.8 bits for Q4_K_M, not 4. cue: the gap is not overhead, it is the wrong constant |
| `:quality_and_speed` | Rules of thumb, labelled as such | 1 | 7 | must: say out loud that these are rules of thumb. cue: 8 bits is nearly lossless, 4 is the usual deal, below 3 it falls apart. cue: quantising also makes it faster, generation is memory bandwidth bound |
| `:not_just_weights` | The weights are not the whole bill | 1 | 7 | cue: the KV cache stores keys and values for every previous token, so the model does not recompute them. cue: it grows with context. one sentence only |
| `:other_labels` | Q8_0, Q5_K_M, IQ4_XS, FP8, AWQ, GPTQ, MLX | 1 | 7 | cue: names only. cue: do not compare them, we do not have nine minutes |
| `:quant_terms` | The words so far | 1 | 7 | definitions for precision, quantization, block and scale, context window, KV cache |
| `:round_gigabytes` | How many gigabytes? | 2 | 7 | round `:how_many_gigabytes`. must: say out loud this is the no rush round |
| `:round_two_bit` | Which one is 2 bit? | 2 | 7 | round `:which_is_two_bit`. cue: three samples from our own toy model |

**Section 8, `.gguf`, 3 minutes.** Lands: the format tells you which program
runs it, and the name has two authors.

| id | title | steps | chapter | notes |
|---|---|---|---|---|
| `:gguf_chapter` | .gguf | 1 | 8 | cue: chapter title |
| `:one_file` | Metadata, tokenizer, chat template, tensors | 2 | 8 | cue: one file holds all of it. cue: the chat template from chapter 5 is in there |
| `:which_program` | GGUF, safetensors, MLX | 1 | 8 | cue: GGUF for llama.cpp, Ollama, LM Studio. cue: safetensors for Transformers and vLLM. cue: MLX on Apple silicon |
| `:two_authors` | This name has two authors | 3 | 8 | must: Qwen wrote everything up to the date stamp. must: somebody in the community converted it and wrote the rest. cue: show it on the header they have watched all talk. cue: Ollama tags like qwen3:30b hide the quantisation, usually Q4_K_M |
| `:gguf_terms` | The words so far | 1 | 8 | definitions for inference engine, GGUF, safetensors |
| `:round_does_it_fit` | Does it fit? | 2 | 8 | round `:does_it_fit` |

**Section 9, Close, 4 minutes.** Lands: they can read the name, and the board
says who read it best.

| id | title | steps | chapter | notes |
|---|---|---|---|---|
| `:annotated_name` | (the whole name, annotated) | 1 | 9 | must: this is the slide to photograph. cue: leave it up while you talk. cue: every segment with its label |
| `:the_board` | The leaderboard | 1 | 9 | cue: read the top three out loud. cue: thank the room |
| `:whats_next` | Next: from the file to the agent | 1 | 9 | cue: one line only. cue: cut this slide if you are over time |

After `@sections`, the public functions:

```elixir
  @doc "The nine chapters, in order."
  @spec sections() :: [Section.t()]
  def sections, do: @sections

  @doc "Every slide, flattened, numbered, and told which section it belongs to."
  @spec slides() :: [Slide.t()]
  def slides do
    @sections
    |> Enum.flat_map(fn section ->
      Enum.map(section.slides, &%{&1 | section: section.number})
    end)
    |> Enum.with_index(1)
    |> Enum.map(fn {slide, index} -> %{slide | index: index} end)
  end

  @doc "The slide at an index, clamped to the deck."
  @spec at(integer()) :: Slide.t()
  def at(index), do: Enum.at(slides(), clamp(index))

  @spec length() :: pos_integer()
  def length, do: Kernel.length(slides())

  @spec clamp(integer()) :: non_neg_integer()
  def clamp(index), do: index |> max(0) |> min(__MODULE__.length() - 1)

  @doc "The section a slide belongs to."
  @spec section(Slide.t()) :: Section.t()
  def section(%Slide{section: number}), do: Enum.find(@sections, &(&1.number == number))

  @doc "Minutes the talk should have spent before this section starts."
  @spec minutes_before(Section.t()) :: number()
  def minutes_before(%Section{number: number}) do
    @sections |> Enum.filter(&(&1.number < number)) |> Enum.map(& &1.minutes) |> Enum.sum()
  end
```

As in Task 2 of the previous plan, the `@sections` literal must live inside a
function rather than a module attribute if it builds structs of a module
defined in the same file. `Section` and `Slide` are separate modules here, so
a module attribute is fine.

- [ ] **Step 4: Run the test to verify it passes**

Run: `mix test`
Expected: PASS. The existing `deck_live_test.exs` will need its slide indices
updated, since the stub's running order is gone: round 1 is no longer slide 2.
Update those tests to find round slides by id rather than by counting presses:

```elixir
  defp press_to(view, slide_id) do
    target = Enum.find_index(Deck.slides(), &(&1.id == slide_id))

    Enum.each(1..target, fn _press ->
      render_keydown(view, "key", %{"key" => "ArrowRight"})
    end)

    view
  end
```

- [ ] **Step 5: Commit**

```bash
mix format
git add lib/model_name_talk/deck.ex test/model_name_talk/deck_test.exs test/model_name_talk_web/live/deck_live_test.exs
git commit -m "Write the running order down

Nine chapters, one for each segment of the name, each ending by asking the
room about the thing it just explained. The arc is one file name read left to
right, which is also the order somebody meets it in a download link.

The order is a list rather than a pile of templates, so it can be diffed
against the brief. It departs from the brief in three places and docs/verify
says why each one.

The deck tests now find a round by its id rather than by counting presses,
because the number of presses to reach a question is exactly the thing this
commit changes and will keep changing."
```

---

### Task 5: The stub renderer, and chapters 1 to 3

**Files:**
- Create: `lib/model_name_talk_web/components/slide_components.ex`
- Create: `lib/model_name_talk_web/components/figure_components.ex`
- Create: `assets/css/figures.css`
- Modify: `lib/model_name_talk_web/deck_components.ex`, `assets/css/app.css`
- Test: `test/model_name_talk_web/components/slide_components_test.exs`

**Interfaces:**
- Consumes: `ModelNameTalk.{Deck, Slide, Filename}`, `ModelNameTalkWeb.FilenameComponents`
- Produces:
  - `ModelNameTalkWeb.SlideComponents.slide/1` with attrs `slide`, `step`, `room`
  - `ModelNameTalkWeb.FigureComponents.log_scale/1` taking `bars` as a list of `{label, count}`
  - a stub clause drawing any slide with no clause of its own, on a hatched background

The stub is what makes the rest of this plan safe to do in any order: an
unwritten slide shows its title and its notes rather than crashing, so the
deck is presentable from this task onward.

`deck_components.ex` currently holds a `slide/1` that draws the stub deck's
rounds. Move round drawing into `slide_components.ex` as the clause for a
slide carrying a `round`, and leave `join/1` and `standings/1` where they are.

- [ ] **Step 1: Write the failing test**

Create `test/model_name_talk_web/components/slide_components_test.exs`:

```elixir
defmodule ModelNameTalkWeb.SlideComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import ModelNameTalkWeb.SlideComponents

  alias ModelNameTalk.{Deck, Room, Slide}

  defp draw(slide, step \\ 1) do
    render_component(&slide/1, slide: slide, step: step, room: %Room{})
  end

  test "draws a slide that has no clause of its own as a stub" do
    unwritten = %Slide{id: :not_a_real_slide, title: "Unwritten", notes: "- a cue\n"}

    html = draw(unwritten)

    assert html =~ "slide--stub"
    assert html =~ "Unwritten"
    assert html =~ "a cue"
  end

  test "draws every slide in the deck without raising" do
    for slide <- Deck.slides(), step <- 1..slide.steps do
      assert draw(slide, step)
    end
  end

  test "puts the file name header on a chapter slide and not on the title" do
    chapter = Enum.find(Deck.slides(), &(&1.chapter == 3))
    [title | _rest] = Deck.slides()

    assert draw(chapter) =~ "filename__name"
    refute draw(title) =~ "filename__name"
  end

  test "lights the chapter's own segment in the header" do
    chapter = Enum.find(Deck.slides(), &(&1.chapter == 4))

    assert draw(chapter) =~ "filename__segment--current"
  end

  test "the log scale figure draws a bar for each model with its label" do
    html =
      render_component(&ModelNameTalkWeb.FigureComponents.log_scale/1,
        bars: [{"ours", 15_104}, {"GPT-2 small", 124_000_000}],
        step: 2
      )

    assert html =~ "ours"
    assert html =~ "GPT-2 small"
    assert html =~ "figure__bar"
  end
end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `mix test test/model_name_talk_web/components/slide_components_test.exs`
Expected: FAIL, module not available.

- [ ] **Step 3: Write the implementation**

`slide_components.ex` opens with:

```elixir
defmodule ModelNameTalkWeb.SlideComponents do
  @moduledoc """
  How each slide is drawn.

  One clause of `slide/1` for each slide id, matched on the id and nowhere
  else, so finding the drawing of a slide is a search for its name. A slide
  with no clause yet falls through to a stub on a hatched background that
  shows its title and its notes, which means the deck is presentable at every
  point while it is being written and an unwritten slide is obvious from the
  back of the room rather than being a crash.

  `<.step n={2} step={@step}>` shows its contents from step two onward, and a
  slide's `steps:` in the deck says how many presses it takes.
  """

  use Phoenix.Component

  import ModelNameTalkWeb.FilenameComponents
  import ModelNameTalkWeb.FigureComponents

  alias ModelNameTalk.{Room, Round, Slide}
```

Then `step/1`:

```elixir
  attr :n, :integer, required: true
  attr :step, :integer, required: true
  slot :inner_block, required: true

  @doc "Shows its contents once the slide has been pressed n times."
  def step(assigns) do
    ~H"""
    <div :if={@step >= @n} class="step">{render_slot(@inner_block)}</div>
    """
  end
```

Then one clause per slide id for chapters 1 to 3, each shaped like:

```elixir
  def slide(%{slide: %Slide{id: :the_name}} = assigns) do
    ~H"""
    <section class="slide slide--centred">
      <p class="slide__filename-huge">{ModelNameTalk.Filename.text()}</p>
    </section>
    """
  end

  def slide(%{slide: %Slide{id: :how_big, chapter: chapter}} = assigns) do
    ~H"""
    <section class="slide">
      <.filename chapter={chapter} />
      <h2 class="slide__title">{@slide.title}</h2>
      <.log_scale
        step={@step}
        bars={[{"ours", 15_104}, {"GPT-2 small", 124_000_000}, {"Qwen3-30B-A3B", 30_532_122_624}]}
      />
      <.step n={3} step={@step}>
        <p class="slide__caption">About two million times our model.</p>
      </.step>
    </section>
    """
  end
```

and finally the round clause and the stub, which must be last:

```elixir
  def slide(%{slide: %Slide{round: round}} = assigns) when not is_nil(round) do
    # the question, the answer count, and the tally after the reveal.
    # Move the markup here from ModelNameTalkWeb.DeckComponents.slide/1.
  end

  # Anything not yet written. Hatched, so it is obvious from the back row.
  def slide(assigns) do
    ~H"""
    <section class="slide slide--stub">
      <.filename :if={@slide.chapter} chapter={@slide.chapter} />
      <h2 class="slide__title">{@slide.title}</h2>
      <p class="slide__stub-notes">{Slide.prose(@slide)}</p>
    </section>
    """
  end
```

`figure_components.ex` gets `log_scale/1`: a horizontal bar for each model
where width is `:math.log10(count) / :math.log10(largest) * 100` percent,
each bar arriving on its own step, with the count printed at the end of the
bar and the axis labelled as logarithmic in words.

`assets/css/figures.css` holds `.figure__bar` and the hatched
`.slide--stub` background. Import it from `app.css`.

- [ ] **Step 4: Run the test to verify it passes**

Run: `mix test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
mix format
git add lib/model_name_talk_web/components/ assets/css/figures.css assets/css/app.css test/model_name_talk_web/components/slide_components_test.exs
git commit -m "Draw the opening, and make an unwritten slide obvious

One clause for each slide id and a hatched stub for everything else, so the
deck is presentable from here on and a slide nobody has written yet announces
itself from the back of the room instead of crashing.

The size chart is on a log scale and says so in words. Three bars four orders
of magnitude apart are a lie drawn linearly and unreadable drawn honestly."
```

---

### Task 6: Chapter 4, the mixture of experts

**Files:**
- Modify: `lib/model_name_talk_web/components/slide_components.ex`
- Modify: `lib/model_name_talk_web/components/figure_components.ex`, `assets/css/figures.css`
- Test: `test/model_name_talk_web/components/figure_components_test.exs`

**Interfaces:**
- Produces: `FigureComponents.expert_grid/1` with attrs `experts` (integer), `active` (list of indices), `step`

- [ ] **Step 1: Write the failing test**

```elixir
defmodule ModelNameTalkWeb.FigureComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import ModelNameTalkWeb.FigureComponents

  test "the expert grid draws every expert and lights only the active ones" do
    html = render_component(&expert_grid/1, experts: 128, active: [3, 9, 20], step: 3)

    assert html |> String.split("figure__expert\"") |> length() == 126
    assert html |> String.split("figure__expert figure__expert--active") |> length() == 4
  end

  test "the expert grid lights nothing before the router has run" do
    html = render_component(&expert_grid/1, experts: 128, active: [3, 9, 20], step: 1)

    refute html =~ "figure__expert--active"
  end
end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `mix test test/model_name_talk_web/components/figure_components_test.exs`
Expected: FAIL, `expert_grid/1 is undefined`.

- [ ] **Step 3: Write the implementation**

`expert_grid/1` draws a CSS grid of `experts` small squares, and from step 3
adds `figure__expert--active` to the ones in `active`. The `:dense_or_sparse`
slide puts a dense layer (one large block) beside it, so the two are the same
height and the comparison is immediate.

The `:memory_and_speed` slide is two lines, arriving one per step, in the
largest type in the deck:

```
Total parameters  ->  memory
Active parameters ->  speed
```

The `:not_specialists` slide is text only, deliberately: it is correcting a
belief, and a diagram of a thing that does not exist would work against that.

Use the verified numbers: 128 experts, 8 active, and note in the speaker
notes that all 48 layers are MoE with no dense layers interleaved.

- [ ] **Step 4: Run the test to verify it passes**

Run: `mix test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
mix format
git add -A
git commit -m "Draw a layer with a router and a hundred and twenty eight experts

Beside a dense layer at the same height, so the comparison needs no caption.
Eight light up, which is the whole of A3B in one picture.

The slide that corrects the specialist idea has no figure on purpose. It
argues that a thing does not exist, and drawing it would undercut that."
```

---

### Task 7: Chapter 5, base and instruct

**Files:**
- Modify: `lib/model_name_talk_web/components/slide_components.ex`, `figure_components.ex`, `assets/css/figures.css`
- Test: extend `slide_components_test.exs`

**Interfaces:**
- Produces: `FigureComponents.pipeline/1` with attrs `stages` (list of strings), `step`

- [ ] **Step 1: Write the failing test**

```elixir
  test "the pipeline draws each stage and arrives one at a time" do
    early =
      render_component(&ModelNameTalkWeb.FigureComponents.pipeline/1,
        stages: ["text corpus", "pre-training", "base", "post-training", "Instruct"],
        step: 1
      )

    late = %{early | }

    assert early =~ "text corpus"
    refute early =~ "Instruct"
  end

  test "the chat template slide shows the raw tokens rather than a picture of a chat" do
    slide = Enum.find(Deck.slides(), &(&1.id == :chat_template))

    html = draw(slide, 2)

    assert html =~ "im_start"
    assert html =~ "im_end"
  end

  test "each demo has a placeholder and a fallback slide" do
    identifiers = Enum.map(Deck.slides(), & &1.id)

    assert :demo_base_instruct in identifiers
    assert :demo_base_instruct_fallback in identifiers
  end
```

Fix the malformed `late` binding when writing this: render the component a
second time with `step: 5` and assert `late =~ "Instruct"`.

- [ ] **Step 2: Run the test to verify it fails**

Run: `mix test test/model_name_talk_web/components/slide_components_test.exs`
Expected: FAIL.

- [ ] **Step 3: Write the implementation**

`pipeline/1` is a horizontal row of boxes with arrows between them, each box
appearing on its own step.

The `:chat_template` slide shows the literal text, in monospace, large:

```
<|im_start|>user
What is the capital of France?<|im_end|>
<|im_start|>assistant
```

Step 2 highlights the special tokens. The point is that there is no such
thing as a message; there is one string, and the template is how a
conversation is flattened into it.

`:demo_base_instruct` is a slide with the word DEMO, very large, and one line
saying what is about to happen. `:demo_base_instruct_fallback` shows a
screenshot from `priv/static/images/demo-base-instruct.png` if that file
exists and a bordered placeholder saying what belongs there if it does not,
so the deck never shows a broken image at the podium.

- [ ] **Step 4: Run the test to verify it passes**

Run: `mix test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
mix format
git add -A
git commit -m "Draw the pipeline, and the raw chat template

The template slide shows the actual string with the actual special tokens,
because the point is that a message is not a thing the model knows about. A
picture of a chat bubble would teach the opposite of the slide.

The demo fallback degrades to a bordered note when the screenshot is not
there, so a missing file is never a broken image on a projector."
```

---

### Task 8: Chapters 6 and 7, the technical centre

**Files:**
- Modify: `lib/model_name_talk_web/components/slide_components.ex`, `figure_components.ex`, `assets/css/figures.css`
- Possibly create: `lib/model_name_talk_web/components/slide_components/chapter_seven.ex` if the main file passes 600 lines
- Test: extend `figure_components_test.exs`

**Interfaces:**
- Produces:
  - `FigureComponents.number_line/1` attrs `values` (floats), `levels` (integer), `step`
  - `FigureComponents.block_diagram/1` attrs `scale` (float), `quants` (list of integers), `step`
  - `FigureComponents.label_anatomy/1` attrs `parts` (list of `{text, explanation}`), `step`
  - `FigureComponents.size_bars/1` attrs `rows` (list of `{label, gigabytes}`), `step`

This is the chapter the talk is for. Nine minutes, and the one number
everybody should leave with.

- [ ] **Step 1: Write the failing test**

```elixir
  test "the number line snaps each weight to one of sixteen levels" do
    html =
      render_component(&number_line/1,
        values: [0.13, -0.42, 0.87, -0.05],
        levels: 16,
        step: 2
      )

    assert html =~ "figure__tick"
    assert html =~ "figure__value"
  end

  test "the label anatomy explains every part of Q4_K_M" do
    html =
      render_component(&label_anatomy/1,
        parts: [{"Q4", "4 bits for each weight"}, {"K", "llama.cpp's k-quant"}, {"M", "medium"}],
        step: 4
      )

    for part <- ~w(Q4 K M), do: assert(html =~ part)
    assert html =~ "k-quant"
  end

  test "the size bars carry the real file sizes from docs/verify.md" do
    html =
      render_component(&size_bars/1,
        rows: [{"BF16", 61.10}, {"Q8_0", 32.48}, {"Q4_K_M", 18.56}],
        step: 3
      )

    assert html =~ "61.1"
    assert html =~ "18.56"
  end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `mix test test/model_name_talk_web/components/figure_components_test.exs`
Expected: FAIL.

- [ ] **Step 3: Write the implementation**

The chapter, slide by slide:

`:the_formula` is one line, alone, in the largest type in the deck:
`memory in GB = parameters in billions x bits / 8`

`:the_method` uses `number_line/1` and `block_diagram/1`. Use six real
numbers and do the arithmetic on the slide so it can be checked:

```
weights   0.13  -0.42   0.87  -0.05   0.51  -0.68
scale     0.87 / 7  =  0.124
integers     1     -3      7      0      4     -5
back      0.124 -0.372  0.868  0.000  0.496 -0.620
```

`:the_real_cost` shows the llama.cpp struct verbatim, which is four lines and
is the primary source:

```c
#define QK8_0 32
typedef struct {
    ggml_half d;       // delta
    int8_t  qs[QK8_0]; // quants
} block_q8_0;          // 2 + 32 = 34 bytes for 32 weights
```

Step 2 lands `34 x 8 / 32 = 8.5 bits for each weight`.

`:does_it_work` is the reframing, and the best slide in the chapter. A table
of real files against what the formula predicts, from `docs/verify.md`:

| | real | formula | out by |
|---|---|---|---|
| Qwen3-30B BF16 | 61.10 GB | 61.06 | 0.05% |
| Qwen3-30B Q8_0 | 32.48 GB | 32.44 | 0.13% |
| Qwen3-30B Q4_K_M | 18.56 GB | 18.32 | 1.30% |
| Llama-3.3-70B Q8_0 | 74.98 GB | 74.96 | 0.02% |

The speaker note must say plainly: the brief framed the difference between a
predicted 15 GB and a real 18.6 GB as overhead to apologise for. It is not.
Put 4.8 in rather than 4 and the formula is right to within about one
percent. That is a better thing to teach and a better thing to remember.

`:round_two_bit` needs three real samples from the toy model at 8, 4 and 2
bits. Generating them is a separate piece of work tracked in `docs/verify.md`
under talk day prerequisites; until they exist, the slide shows three
labelled placeholder boxes and the round still works as a guess.

- [ ] **Step 4: Run the test to verify it passes**

Run: `mix test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
mix format
git add -A
git commit -m "Build the quantisation chapter around a formula that works

The brief framed the distance between a predicted 15 GB and a real 18.6 GB as
overhead to explain away. Measured against six real files it is nothing of
the kind: the formula lands within about one percent once the right bits for
each weight goes in. The gap is the wrong constant, not overhead.

So the chapter teaches 4.8 rather than 4 plus an apology, and shows the
llama.cpp struct that explains where the extra half bit lives. Four lines of
C is a better argument than a paragraph about it."
```

---

### Task 9: Chapters 8 and 9, and the close

**Files:**
- Modify: `lib/model_name_talk_web/components/slide_components.ex`, `figure_components.ex`
- Test: extend `slide_components_test.exs`

**Interfaces:**
- Produces: `FigureComponents.file_box/1` attrs `parts` (list of strings), `step`

- [ ] **Step 1: Write the failing test**

```elixir
  test "the file box shows what one gguf holds" do
    html =
      render_component(&ModelNameTalkWeb.FigureComponents.file_box/1,
        parts: ["metadata", "tokenizer", "chat template", "tensors"],
        step: 2
      )

    for part <- ["metadata", "tokenizer", "chat template", "tensors"],
        do: assert(html =~ part)
  end

  test "the two authors slide splits the header rather than drawing a new picture" do
    slide = Enum.find(Deck.slides(), &(&1.id == :two_authors))

    html = draw(slide, 2)

    assert html =~ "filename__author"
  end

  test "the close shows the annotated name with every label" do
    slide = Enum.find(Deck.slides(), &(&1.id == :annotated_name))

    html = draw(slide)

    for segment <- ModelNameTalk.Filename.segments() do
      assert html =~ segment.label
    end
  end

  test "the close shows the leaderboard" do
    slide = Enum.find(Deck.slides(), &(&1.id == :the_board))

    assert draw(slide) =~ "deck__standings"
  end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `mix test test/model_name_talk_web/components/slide_components_test.exs`
Expected: FAIL.

- [ ] **Step 3: Write the implementation**

`:two_authors` renders `<.filename chapter={8} authors={true} />` at the
centre of the slide rather than in the header position. The room has been
reading this string for forty minutes; splitting it is the payoff, and it
works precisely because it is not a new picture.

`:annotated_name` is `<.annotated />`, large, with nothing else on the slide.
It is the one slide allowed to be dense, because it is the one people
photograph.

`:the_board` renders the standings from `Room.standings()` through the
existing `DeckComponents.standings/1`, top five, with the same component the
presenter view uses.

- [ ] **Step 4: Run the test to verify it passes**

Run: `mix test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
mix format
git add -A
git commit -m "Close on the header the room has been reading all talk

The two authors slide is the same string they have looked at thirty times,
with a line drawn where Qwen stopped writing and a stranger started. It works
because it is not a new picture.

The annotated name is the one slide allowed to be dense. It is the one people
photograph."
```

---

### Task 10: The presenter's notes and clocks

**Files:**
- Modify: `lib/model_name_talk_web/live/presenter_live.ex`
- Create: `lib/model_name_talk_web/components/notes_components.ex`
- Modify: `assets/css/deck.css`
- Test: extend `test/model_name_talk_web/live/deck_live_test.exs`

**Interfaces:**
- Consumes: `Slide.blocks/1`, `Deck.section/1`, `Deck.minutes_before/1`
- Produces: `NotesComponents.notes/1` with attr `slide`; presenter gains `r` to reset the clock and `t` to pause it

The laptop screen shows, top to bottom: where the talk is and the clocks, the
line the section must land, the slide the room is looking at, and under it the
notes on the left with the game's controls on the right.

- [ ] **Step 1: Write the failing test**

```elixir
  test "the presenter shows the notes, with what must be said marked", %{conn: conn} do
    {:ok, presenter, _html} = live(conn, ~p"/presenter")

    html = render(presenter)

    assert html =~ "notes__must"
    assert html =~ "say the title once"
  end

  test "the presenter shows what the section has to land", %{conn: conn} do
    {:ok, presenter, html} = live(conn, ~p"/presenter")

    assert html =~ ModelNameTalk.Deck.section(hd(ModelNameTalk.Deck.slides())).lands
  end

  test "the presenter clock resets on r", %{conn: conn} do
    {:ok, presenter, _html} = live(conn, ~p"/presenter")

    render_keydown(presenter, "key", %{"key" => "r"})

    assert render(presenter) =~ "00:00"
  end

  test "a term card's definitions reach the presenter as a glossary", %{conn: conn} do
    {:ok, presenter, _html} = live(conn, ~p"/presenter")
    press_to(presenter, :qwen3_terms)

    assert render(presenter) =~ "notes__definition"
  end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `mix test test/model_name_talk_web/live/deck_live_test.exs`
Expected: FAIL.

- [ ] **Step 3: Write the implementation**

`notes/1` renders `Slide.blocks/1`: cues as a plain list, musts drawn lit and
tagged "say", definitions as a term and meaning grid.

The presenter gains a clock started at mount, reset by `r` and paused by `t`,
shown against `Deck.minutes_before/1` plus the current section's minutes, with
a line saying whether the talk is on pace, ahead or behind. Keys that are not
arrows must not move the deck, so `DeckLive.move/2` already ignores them.

- [ ] **Step 4: Run the test to verify it passes**

Run: `mix test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
mix format
git add -A
git commit -m "Give the speaker notes, a clock and a line to land

The only two questions a speaker asks in the middle of a talk are where am I
and am I behind, so the laptop answers both before it shows anything else.
Points that must be said out loud are drawn lit, because they are the ones
that get dropped when the clock is red."
```

---

### Task 11: The reference sheet

**Files:**
- Create: `lib/model_name_talk_web/controllers/sheet_html.ex` and its template, or a `/sheet` LiveView
- Modify: `lib/model_name_talk_web/router.ex`
- Test: `test/model_name_talk_web/sheet_test.exs`

Deliverable 2 of the brief: a one page reference for the audience holding the
annotated file name, every term definition, and the memory formula. It is a
route rather than a PDF so the same link works in the meeting chat.

- [ ] **Step 1: Write the failing test**

```elixir
defmodule ModelNameTalkWeb.SheetTest do
  use ModelNameTalkWeb.ConnCase, async: true

  alias ModelNameTalk.{Deck, Filename, Slide}

  test "holds the annotated name, the formula and every definition", %{conn: conn} do
    html = conn |> get(~p"/sheet") |> html_response(200)

    for segment <- Filename.segments() do
      assert html =~ segment.text
      assert html =~ segment.label
    end

    assert html =~ "bits"

    definitions =
      Deck.slides()
      |> Enum.flat_map(&Slide.blocks/1)
      |> Enum.flat_map(fn
        {:definitions, pairs} -> pairs
        _other -> []
      end)

    assert length(definitions) >= 20

    for {term, _meaning} <- definitions, do: assert(html =~ term)
  end
end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `mix test test/model_name_talk_web/sheet_test.exs`
Expected: FAIL, no route.

- [ ] **Step 3: Write the implementation**

The sheet gathers definitions by walking `Deck.slides()` and collecting every
`{:definitions, pairs}` block, so a term added to a slide's notes appears on
the sheet without anybody remembering to add it twice. Styled to print on one
page and to read on a phone.

- [ ] **Step 4: Run the test to verify it passes**

Run: `mix test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
mix format
git add -A
git commit -m "Give the room one page to take away

The definitions are gathered from the slides' own notes rather than typed
again, so a term card and the sheet cannot disagree about what a word means.
A route rather than a PDF, because the link can go in the meeting chat next
to the one they joined with."
```

---

### Task 12: A rehearsal pass

**Files:**
- Modify: `README.md`, `docs/verify.md`
- Test: `test/model_name_talk/deck_test.exs`

- [ ] **Step 1: Write the failing test**

```elixir
  test "no slide carries more body text than the brief allows" do
    # Term cards, the annotated close and the code slides are exempt: the
    # brief names them as the exceptions.
    exempt = [:qwen3_terms, :thirty_b_terms, :a3b_terms, :instruct_terms,
              :quant_terms, :gguf_terms, :annotated_name, :chat_template,
              :the_real_cost, :the_method, :does_it_work]

    for slide <- Deck.slides(), slide.id not in exempt do
      words = slide.title |> String.split() |> length()

      assert words <= 10, "#{slide.id} has a #{words} word title"
    end
  end

  test "every chapter with a segment ends by asking about it" do
    for chapter <- 2..8, chapter != 6 do
      slides = Enum.filter(Deck.slides(), &(&1.chapter == chapter))

      assert List.last(slides).round != nil,
             "chapter #{chapter} does not end on a round"
    end
  end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `mix test test/model_name_talk/deck_test.exs`
Expected: FAIL if any slide title runs long or a chapter does not close on its
round. Fix the deck, not the test.

- [ ] **Step 3: Rehearse it for real**

Not a code step, and it is the point of the whole plan.

1. `mix phx.server`, open `/` and `/presenter` on separate screens.
2. Start a `cloudflared` tunnel, set `JOIN_URL`, and join from an actual phone.
3. Walk the whole deck forwards. Time each section against the presenter's
   pace line.
4. Walk it backwards from the end, checking no slide crashes and every
   walked-back round re-asks rather than showing its answer.
5. Share the screen in a real Zoom or Meet call and read the file name header
   from the shared view, not the local one. That is the test that matters.
6. Record what broke in `docs/verify.md` under talk day prerequisites.

- [ ] **Step 4: Update the documents**

Tick off what rehearsal confirmed in `docs/verify.md`. Replace the README's
"Still to do" section, which currently says the deck is a stub.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "Rehearse the whole thing, and write down what broke

The screen share test is the one that counts: the header has to be legible in
the shared view on somebody else's laptop, not in the window it is rendered
in."
```

---

## Self-Review

**Spec coverage:**

| Spec section | Task |
|---|---|
| 7.1 recovered code | done in plan 1 |
| 7.2 deck as data, one clause per id, stub fallback | 4, 5 |
| 7.3 the file name header, two authors | 1, 2, 9 |
| 7.4 typography for a codec | 2, 5, 12 |
| 7.5 persistent join chrome | done in plan 1 |
| 5 the seven rounds, placed in chapters | 4 |
| Brief chapters 1 to 9 | 5, 6, 7, 8, 9 |
| Brief deliverable 1, deck with notes | 4, 10 |
| Brief deliverable 2, reference sheet | 11 |
| Brief deliverable 3, verify list | done, `docs/verify.md` |
| Brief's demo placeholders and fallbacks | 7 |
| Spec 9, deviations recorded | done, spec section 9 plus this plan's corrections |

**Placeholder scan:** Task 5 and Task 8 describe some slide clauses in prose
plus one worked example rather than giving every clause's markup. That is
deliberate: the content is fully specified in Task 4's tables and the visual
treatment is a drawing decision that wants a browser open. Every figure
component, which is the reusable part, has its signature and test. Task 12
step 3 is a manual rehearsal and says so.

One known gap, carried openly: round 6 needs three real samples from the toy
model quantised to 8, 4 and 2 bits. That work is not in this plan because it
belongs to `tiny_llm`, not here. Task 8 ships labelled placeholders so the
round works meanwhile, and `docs/verify.md` tracks it.

**Type consistency:** `Slide` gains `round`, `chapter`, `section` and `index`
over the stub's `id`, `title`, `round`, `steps`; `Deck.at/1`, `length/0` and
`clamp/1` keep their signatures so `Position` and both LiveViews are
untouched. `Filename.state/2` takes a `Segment` and a chapter and is called
that way in `FilenameComponents`. `Slide.blocks/1` returns `:cues`, `:musts`
and `:definitions`, which is what `NotesComponents` matches and what the sheet
in Task 11 collects.
