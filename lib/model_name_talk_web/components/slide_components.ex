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

  import ModelNameTalkWeb.FigureComponents
  import ModelNameTalkWeb.FilenameComponents

  alias ModelNameTalk.{Filename, Room, Round, Slide}

  attr :n, :integer, required: true
  attr :step, :integer, required: true
  slot :inner_block, required: true

  @doc "Shows its contents once the slide has been pressed n times."
  def step(assigns) do
    ~H"""
    <div :if={@step >= @n} class="step">{render_slot(@inner_block)}</div>
    """
  end

  attr :slide, :map, required: true
  attr :step, :integer, required: true
  attr :room, :map, required: true

  @doc "One slide, drawn by its id."

  ## CHAPTER 1, OPENING

  def slide(%{slide: %Slide{id: :title}} = assigns) do
    ~H"""
    <section class="slide slide--centred">
      <h1 class="slide__title">{@slide.title}</h1>
      <p class="slide__subtitle">{Filename.text()}</p>
    </section>
    """
  end

  def slide(%{slide: %Slide{id: :the_name}} = assigns) do
    ~H"""
    <section class="slide slide--centred">
      <p class="slide__filename-huge">{Filename.text()}</p>
    </section>
    """
  end

  ## CHAPTER 3, 30B

  def slide(%{slide: %Slide{id: :how_big}} = assigns) do
    ~H"""
    <section class="slide">
      <.filename chapter={@slide.chapter} />
      <h2 class="slide__title">{@slide.title}</h2>

      <.orders_of_magnitude
        step={@step}
        caption="each mark along is ten times the one before it"
        points={[
          {"ours", 15_104},
          {"GPT-2 small", 124_000_000},
          {"this one", 30_532_122_624}
        ]}
      />

      <.step n={3} step={@step}>
        <p class="slide__caption">About two million times our model.</p>
      </.step>
    </section>
    """
  end

  ## TERM CARDS

  def slide(%{slide: %Slide{id: id}} = assigns) when id in ~w(
        qwen3_terms thirty_b_terms a3b_terms instruct_terms quant_terms gguf_terms
      )a do
    assigns = assign(assigns, definitions: Slide.definitions(assigns.slide))

    ~H"""
    <section class="slide">
      <.filename chapter={@slide.chapter} />
      <h2 class="slide__title slide__title--small">{@slide.title}</h2>

      <dl class="terms">
        <div :for={{term, meaning} <- @definitions} class="terms__row">
          <dt class="terms__term">{term}</dt>
          <dd class="terms__meaning">{meaning}</dd>
        </div>
      </dl>
    </section>
    """
  end

  ## ROUNDS

  def slide(%{slide: %Slide{round: round}} = assigns) when not is_nil(round) do
    assigns = assign(assigns, round: Round.fetch(round))

    ~H"""
    <section class="slide slide--round">
      <.filename chapter={@slide.chapter} />

      <h2 class="slide__question">{@round.question}</h2>

      <ul :if={@round.type == :choice} class="slide__options">
        <li
          :for={option <- @round.options}
          class={[
            "slide__option",
            @room.phase == :revealed and option == @round.answer and "slide__option--answer"
          ]}
        >
          {option}
        </li>
      </ul>

      <p :if={@round.type == :numeric} class="slide__numeric">
        Type a number on your phone.
      </p>

      <p :if={@room.phase != :revealed} class="slide__count">
        {Room.answered_count(@room)} answered
      </p>

      <div :if={@room.phase == :revealed} class="deck__tally slide__tally">
        <p :for={{option, count} <- Room.tally(@room)} class="slide__tally-row">
          <span class="slide__tally-option">{option}</span>
          <span class="slide__tally-count">{count}</span>
        </p>
        <p class="slide__answer">{answer_line(@round)}</p>
      </div>
    </section>
    """
  end

  ## ANYTHING NOT YET WRITTEN

  # Hatched, so an unwritten slide announces itself from the back of the room
  # rather than crashing or, worse, looking finished.
  def slide(assigns) do
    ~H"""
    <section class="slide slide--stub">
      <.filename :if={@slide.chapter} chapter={@slide.chapter} />
      <h2 class="slide__title slide__title--small">{@slide.title}</h2>
      <p class="slide__stub-notes">{Slide.prose(@slide)}</p>
    </section>
    """
  end

  ## PRIVATE FUNCTIONS

  defp answer_line(%Round{type: :choice, answer: answer}), do: "The answer: #{answer}"

  defp answer_line(%Round{type: :numeric, answer: answer, band: {low, high}}) do
    "The answer: about #{answer}. Anything from #{low} to #{high} counted."
  end
end
