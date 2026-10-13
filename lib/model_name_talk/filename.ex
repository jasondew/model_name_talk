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

  @doc "Every segment, left to right."
  @spec segments() :: [Segment.t()]
  def segments do
    [
      %Segment{text: "Qwen3", chapter: 2, author: :vendor, label: "family and generation"},
      %Segment{text: "30B", chapter: 3, author: :vendor, label: "total parameters"},
      %Segment{text: "A3B", chapter: 4, author: :vendor, label: "active for each token"},
      %Segment{text: "Instruct", chapter: 5, author: :vendor, label: "post-trained to answer"},
      %Segment{text: "2507", chapter: 6, author: :vendor, label: "July 2025"},
      %Segment{text: "Q4_K_M", chapter: 7, author: :converter, label: "4 bits, k-quant, medium"},
      %Segment{text: ".gguf", chapter: 8, author: :converter, label: "llama.cpp's format"}
    ]
  end

  @doc "The whole name, as it appears on disk."
  @spec text() :: String.t()
  def text do
    segments()
    |> Enum.map(& &1.text)
    |> Enum.reduce(fn segment, joined -> joined <> separator(segment) <> segment end)
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

  @doc """
  What comes before a segment when the name is written out: a dash, except
  for the extension, which hangs off the name directly.

  Drawing the separator with its segment keeps the header one flex row rather
  than a string that has to be re-split to be styled.
  """
  @spec separator(Segment.t() | String.t()) :: String.t()
  def separator(%Segment{text: text}), do: separator(text)
  def separator("." <> _rest), do: ""
  def separator(_text), do: "-"

  @doc "Whether a segment is the first one, and so takes no separator at all."
  @spec first?(Segment.t()) :: boolean()
  def first?(%Segment{chapter: chapter}), do: chapter == hd(segments()).chapter
end
