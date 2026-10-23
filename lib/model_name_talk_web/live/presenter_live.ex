defmodule ModelNameTalkWeb.PresenterLive do
  @moduledoc """
  The window on the speaker's laptop.

  Top to bottom: where the talk is and the clock, the line this section has
  to land, the slide the room is looking at, and under it the notes beside
  what the next press will show.

  That order is deliberate. The only two questions a speaker asks in the
  middle of a talk are where am I and am I behind, so the laptop answers both
  before it shows anything else.
  """

  use ModelNameTalkWeb, :live_view

  import ModelNameTalkWeb.NotesComponents
  import ModelNameTalkWeb.SlideComponents

  alias ModelNameTalk.Deck
  alias ModelNameTalkWeb.{DeckLive, Position}

  @tick 1000

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Position.subscribe()
      :timer.send_interval(@tick, :tick)
    end

    {:ok,
     socket
     |> assign(position: Position.current())
     |> assign(elapsed: 0, running: true)
     |> assign(page_title: "Presenter"), layout: false}
  end

  @impl true
  # The clock keys must not also move the deck, so they are matched before
  # anything reaches the mover.
  def handle_event("key", %{"key" => "r"}, socket),
    do: {:noreply, assign(socket, elapsed: 0, running: true)}

  def handle_event("key", %{"key" => "t"}, socket),
    do: {:noreply, update(socket, :running, &(!&1))}

  def handle_event("key", %{"key" => key}, socket), do: {:noreply, DeckLive.move(socket, key)}

  @impl true
  def handle_info(:tick, %{assigns: %{running: false}} = socket), do: {:noreply, socket}

  def handle_info(:tick, socket), do: {:noreply, update(socket, :elapsed, &(&1 + 1))}

  def handle_info({:position, position}, socket),
    do: {:noreply, assign(socket, position: position)}

  @impl true
  def render(assigns) do
    {index, step} = assigns.position
    slide = Deck.at(index)
    section = Deck.section(slide)

    assigns =
      assigns
      |> assign(slide: slide, step: step, section: section)
      |> assign(upcoming: Position.upcoming(assigns.position))
      |> assign(expected: Deck.minutes_before(section) + section.minutes)

    ~H"""
    <main class="presenter" phx-window-keydown="key">
      <header class="presenter__top">
        <p class="presenter__where">
          slide {elem(@position, 0) + 1} of {Deck.length()}, step {@step} &middot; {@section.title}
        </p>
        <.clock elapsed={@elapsed} expected={@expected} running={@running} />
      </header>

      <p class="presenter__lands">{@section.lands}</p>

      <section class="presenter__stage">
        <.slide slide={@slide} step={@step} />
      </section>

      <section class="presenter__desk">
        <.notes slide={@slide} />

        <aside class="presenter__upcoming">
          <p class="presenter__here">{upcoming_label(@position, @upcoming)}</p>
          <div :if={@upcoming != @position} class="presenter__preview">
            <.slide slide={Deck.at(elem(@upcoming, 0))} step={elem(@upcoming, 1)} />
          </div>
        </aside>
      </section>
    </main>
    """
  end

  ## PRIVATE FUNCTIONS

  defp upcoming_label(position, position), do: "End of the deck"
  defp upcoming_label({index, _step}, {index, step}), do: "Next press: step #{step} of this slide"

  defp upcoming_label(_position, {index, _step}),
    do: "Next slide: #{index + 1}. #{Deck.at(index).title}"
end
