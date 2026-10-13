defmodule ModelNameTalk.Slide do
  @moduledoc """
  One slide.

  Notes are what the speaker says, never what the slide should look like. An
  undrawn slide falls through to the stub, which puts its notes on screen, so
  a line like "chapter title, segment very large" is an instruction to
  whoever draws the slide that the room ends up reading instead. Drawing
  decisions belong in `ModelNameTalkWeb.SlideComponents`, next to the drawing.

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

  The definitions are also the chapter's term card and the audience's
  reference sheet, which is why the three cannot disagree: they are one piece
  of text read three ways.
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

  @doc "Every definition this slide carries, in order."
  @spec definitions(t()) :: [{String.t(), String.t()}]
  def definitions(slide) do
    slide
    |> blocks()
    |> Enum.flat_map(fn
      {:definitions, pairs} -> pairs
      _other -> []
    end)
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
