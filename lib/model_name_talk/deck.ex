defmodule ModelNameTalk.Deck do
  @moduledoc """
  The running order, as data.

  This is the stub deck. It holds a title and one slide for each round, which
  is enough to rehearse the game against while the real slides are unwritten.
  The chapters come later; what matters now is that the rounds are driven by
  slide position, so a rehearsal exercises the thing the talk will actually do.

  A slide carries the round it asks, if any, and how many presses it takes
  before the deck moves on. A round slide takes two: the first asks, the
  second shows the answer.
  """

  alias ModelNameTalk.Round

  defmodule Slide do
    @moduledoc "One slide: what to draw, what it asks, and how many presses it takes."

    @enforce_keys [:id, :title]
    defstruct [:id, :title, :round, steps: 1]

    @type t :: %__MODULE__{
            id: atom(),
            title: String.t(),
            round: atom() | nil,
            steps: pos_integer()
          }
  end

  @doc "Every slide, in order."
  @spec slides() :: [Slide.t()]
  def slides do
    [
      %Slide{id: :title, title: "How to Read a Model Name"}
      | Enum.map(Round.all(), fn round ->
          %Slide{
            id: round.id,
            title: round.after_segment,
            round: round.id,
            steps: 2
          }
        end)
    ]
  end

  @doc "The slide at an index, clamped to the deck."
  @spec at(non_neg_integer()) :: Slide.t()
  def at(index), do: Enum.at(slides(), clamp(index))

  @doc "How many slides there are."
  @spec length() :: pos_integer()
  def length, do: Kernel.length(slides())

  @doc "An index brought back inside the deck."
  @spec clamp(integer()) :: non_neg_integer()
  def clamp(index), do: index |> max(0) |> min(__MODULE__.length() - 1)
end
