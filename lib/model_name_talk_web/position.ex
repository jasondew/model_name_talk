defmodule ModelNameTalkWeb.Position do
  @moduledoc """
  Where the talk is, shared between the window being screen shared and the
  window on the speaker's laptop.

  Either window can hold the clicker. A move made in one is broadcast to the
  other, so the deck and the presenter view cannot disagree about which slide
  is up.

  The position is also kept here, not only broadcast. A window that arrives
  in the middle of a talk, or one the speaker reloads because something looks
  stuck, has to come back where the talk already is, and nobody is listening
  to a broadcast until they have mounted.

  A question slide is always entered at its first step, from either
  direction. Walking back to a question means wanting to ask it again; a
  speaker who only wanted to see the answer again can press forward once more.
  """

  use Agent

  alias ModelNameTalk.Deck
  alias Phoenix.PubSub

  @topic "position"

  @type t :: {non_neg_integer(), pos_integer()}

  def start_link(_options), do: Agent.start_link(fn -> {0, 1} end, name: __MODULE__)

  @spec subscribe() :: :ok
  def subscribe, do: PubSub.subscribe(ModelNameTalk.PubSub, @topic)

  @doc "Where the talk is, for a window that has just opened."
  @spec current() :: t()
  def current, do: Agent.get(__MODULE__, & &1)

  @doc "Back to the title. For rehearsals and tests."
  @spec reset() :: :ok
  def reset, do: Agent.update(__MODULE__, fn _position -> {0, 1} end)

  @doc "Where the next press lands, remembered."
  @spec forward(t()) :: t()
  def forward(position), do: position |> upcoming() |> remember()

  @doc """
  Where the next press would land, without moving anything.

  The presenter view shows it, so the speaker can lead into a slide rather
  than react to it.
  """
  @spec upcoming(t()) :: t()
  def upcoming({slide, step}) do
    if step < Deck.at(slide).steps do
      {slide, step + 1}
    else
      enter(slide + 1, :forward)
    end
  end

  @doc "Where a press of the left arrow lands, remembered."
  @spec back(t()) :: t()
  def back({slide, step}) do
    if step > 1 do
      remember({slide, step - 1})
    else
      remember(enter(slide - 1, :back))
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

  defp remember(position) do
    Agent.update(__MODULE__, fn _previous -> position end)

    position
  end
end
