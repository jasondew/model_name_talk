defmodule ModelNameTalkWeb.Position do
  @moduledoc """
  Where the talk is, shared between the window on the projector and the window
  on the speaker's laptop.

  Either window can hold the clicker. A move made in one is broadcast to the
  other, so the deck and the presenter view cannot disagree about which slide
  is up.

  Moving is also what drives the game. Arriving at a slide that asks a round
  opens it, the second press on that slide reveals the answer, and leaving
  closes it. There is no separate control, because the one thing a speaker
  cannot do while talking is remember a second thing.

  A round slide is always entered at its first step, from either direction.
  Walking back to a question means wanting to ask it again; a speaker who only
  wanted to see the answer again can press forward once more.
  """

  alias ModelNameTalk.{Deck, Room}
  alias Phoenix.PubSub

  @topic "position"

  @type t :: {non_neg_integer(), pos_integer()}

  @spec subscribe() :: :ok
  def subscribe, do: PubSub.subscribe(ModelNameTalk.PubSub, @topic)

  @doc "Where the talk is, for a window that has just opened."
  @spec current() :: t()
  def current, do: Room.position()

  @doc "Where the next press lands, and the game moved to match."
  @spec forward(t()) :: t()
  def forward({slide, step}) do
    if step < Deck.at(slide).steps do
      settle({slide, step + 1})
    else
      settle(enter(slide + 1, :forward))
    end
  end

  @doc "Where a press of the left arrow lands, and the game moved to match."
  @spec back(t()) :: t()
  def back({slide, step}) do
    if step > 1 do
      settle({slide, step - 1})
    else
      settle(enter(slide - 1, :back))
    end
  end

  @doc "Tells the other window where the talk now is."
  @spec broadcast(t()) :: :ok
  def broadcast(position) do
    PubSub.broadcast(ModelNameTalk.PubSub, @topic, {:position, position})
  end

  ## PRIVATE FUNCTIONS

  # Going forward lands on a slide's first step. Going back lands on its last,
  # the way a deck usually behaves, unless the slide asks a question, in which
  # case arriving at it means asking it.
  defp enter(index, direction) do
    index = Deck.clamp(index)
    slide = Deck.at(index)

    cond do
      slide.round -> {index, 1}
      direction == :back -> {index, slide.steps}
      true -> {index, 1}
    end
  end

  # Whatever the room is doing is a function of where the deck is, so it is
  # recomputed from the position rather than nudged by each key press.
  defp settle({index, step} = position) do
    slide = Deck.at(index)
    Room.move(position)

    case {slide.round, step} do
      {nil, _step} -> Room.open(nil)
      {round, 1} -> Room.ask(round)
      {round, _later} -> reveal(round)
    end

    position
  end

  defp reveal(round) do
    Room.open(round)
    Room.reveal()
  end
end
