defmodule ModelNameTalkWeb.DeckComponents do
  @moduledoc """
  The pieces both windows draw.

  The deck and the presenter view show the same slide, so the drawing lives
  here once rather than twice. What differs between them is what sits around
  the slide, not the slide itself.
  """

  use Phoenix.Component

  alias ModelNameTalk.{Room, Round}

  attr :slide, :map, required: true
  attr :step, :integer, required: true
  attr :room, :map, required: true

  @doc "One slide of the stub deck."
  def slide(assigns) do
    assigns = assign(assigns, round: Round.fetch(assigns.slide.round))

    ~H"""
    <section :if={is_nil(@round)} class="slide slide--title">
      <h1 class="slide__title">{@slide.title}</h1>
      <p class="slide__subtitle">Qwen3-30B-A3B-Instruct-2507-Q4_K_M.gguf</p>
    </section>

    <section :if={@round} class="slide slide--round">
      <p class="slide__segment">after {@slide.title}</p>
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

  attr :url, :string, required: true

  @doc """
  The way in, on every slide.

  The audience is remote and watching a shared screen, so somebody joining at
  minute twelve cannot scroll back through the chat to find the link. It is
  easier to keep it on screen than to paste it again.
  """
  def join(assigns) do
    ~H"""
    <aside class="deck__join">
      {Phoenix.HTML.raw(qr(@url))}
      <p class="deck__join-url">{@url}</p>
    </aside>
    """
  end

  attr :standings, :list, required: true
  attr :limit, :integer, default: 5

  @doc "The leaderboard, best first."
  def standings(assigns) do
    ~H"""
    <ol class="deck__standings">
      <li :for={standing <- Enum.take(@standings, @limit)} class="deck__standing">
        <span class="deck__standing-place">{standing.place}</span>
        <span class="deck__standing-handle">{standing.handle}</span>
        <span class="deck__standing-points">{standing.points}</span>
      </li>
      <li :if={@standings == []} class="deck__standing deck__standing--empty">
        Nobody has answered yet.
      </li>
    </ol>
    """
  end

  ## PRIVATE FUNCTIONS

  defp qr(url) do
    url
    |> EQRCode.encode()
    |> EQRCode.svg(width: 160, background_color: "#ffffff", color: "#000000")
  end

  defp answer_line(%Round{type: :choice, answer: answer}), do: "The answer: #{answer}"

  defp answer_line(%Round{type: :numeric, answer: answer, band: {low, high}}) do
    "The answer: about #{answer}. Anything from #{low} to #{high} counted."
  end
end
