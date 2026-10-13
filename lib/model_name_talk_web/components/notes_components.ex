defmodule ModelNameTalkWeb.NotesComponents do
  @moduledoc """
  The speaker's notes, and the clocks.

  Notes come out of the deck in three kinds. A cue is a plain line. A must is
  drawn lit and tagged, because those are the points that get dropped when
  the clock goes red and the talk starts being summarised rather than given.
  A definition is a term and its meaning, which is also the chapter's term
  card: the room and the speaker read the same text.
  """

  use Phoenix.Component

  alias ModelNameTalk.Slide

  attr :slide, :map, required: true

  @doc "What to say, for the slide on screen."
  def notes(assigns) do
    assigns = assign(assigns, blocks: Slide.blocks(assigns.slide))

    ~H"""
    <div class="notes">
      <%= for block <- @blocks do %>
        <ul :if={elem(block, 0) == :cues} class="notes__cues">
          <li :for={cue <- elem(block, 1)} class="notes__cue">{cue}</li>
        </ul>

        <ul :if={elem(block, 0) == :musts} class="notes__musts">
          <li :for={must <- elem(block, 1)} class="notes__must">
            <span class="notes__must-tag">say</span>{must}
          </li>
        </ul>

        <dl :if={elem(block, 0) == :definitions} class="notes__definitions">
          <div :for={{term, meaning} <- elem(block, 1)} class="notes__definition">
            <dt class="notes__term">{term}</dt>
            <dd class="notes__meaning">{meaning}</dd>
          </div>
        </dl>
      <% end %>
    </div>
    """
  end

  attr :elapsed, :integer, required: true
  # Section minutes are a mix of whole numbers and halves, so :any rather
  # than a numeric type.
  attr :expected, :any, required: true
  attr :running, :boolean, default: true

  @doc """
  The clock, and whether the talk is on pace.

  The only two questions a speaker asks in the middle of a talk are where am
  I and am I behind, so this answers both before the laptop shows anything
  else.
  """
  def clock(assigns) do
    assigns = assign(assigns, pace: pace(assigns.elapsed, assigns.expected))

    ~H"""
    <div class="clock">
      <p class={["clock__time", !@running && "clock__time--paused"]}>{minutes(@elapsed)}</p>
      <p class={["clock__pace", "clock__pace--#{elem(@pace, 0)}"]}>{elem(@pace, 1)}</p>
    </div>
    """
  end

  ## PRIVATE FUNCTIONS

  defp minutes(seconds) do
    "#{seconds |> div(60) |> pad()}:#{seconds |> rem(60) |> pad()}"
  end

  defp pad(number), do: number |> Integer.to_string() |> String.pad_leading(2, "0")

  # A minute either side is on pace. Past that the speaker needs a word, not
  # a number, because a number mid-sentence is one more thing to work out.
  defp pace(elapsed, expected) do
    drift = elapsed / 60 - expected

    cond do
      drift < -1.5 -> {:ahead, "ahead, slow down"}
      drift > 1.5 -> {:behind, "behind, move"}
      true -> {:on, "on pace"}
    end
  end
end
