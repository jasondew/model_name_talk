defmodule ModelNameTalkWeb.PresenterLive do
  @moduledoc """
  The window on the speaker's laptop.

  Top to bottom: where the talk is and the clock, the line this section has
  to land, the slide the room is looking at, and under it the notes beside
  the game's controls.

  That order is deliberate. The only two questions a speaker asks in the
  middle of a talk are where am I and am I behind, so the laptop answers both
  before it shows anything else.

  The end-round-early button matters more than it looks. Twenty seconds of
  silence on a video call is a long time, and once twenty-eight of thirty-one
  people have answered there is no reason to spend the last eight waiting.
  """

  use ModelNameTalkWeb, :live_view

  import ModelNameTalkWeb.NotesComponents
  import ModelNameTalkWeb.SlideComponents

  alias ModelNameTalk.{Deck, Room}
  alias ModelNameTalkWeb.{DeckLive, Position}

  @tick 1000

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Position.subscribe()
      Room.subscribe()
      :timer.send_interval(@tick, :tick)
    end

    {:ok,
     socket
     |> assign(position: Position.current(), room: Room.state())
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

  def handle_event("lock", _params, socket) do
    Room.lock()

    {:noreply, assign(socket, room: Room.state())}
  end

  def handle_event("reveal", _params, socket) do
    Room.reveal()

    {:noreply, assign(socket, room: Room.state())}
  end

  @impl true
  def handle_info(:tick, %{assigns: %{running: false}} = socket), do: {:noreply, socket}

  def handle_info(:tick, socket), do: {:noreply, update(socket, :elapsed, &(&1 + 1))}

  def handle_info({:position, position}, socket),
    do: {:noreply, assign(socket, position: position, room: Room.state())}

  def handle_info({:room, room}, socket), do: {:noreply, assign(socket, room: room)}

  @impl true
  def render(assigns) do
    {index, step} = assigns.position
    slide = Deck.at(index)
    section = Deck.section(slide)

    assigns =
      assigns
      |> assign(slide: slide, step: step, section: section)
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
        <.slide slide={@slide} step={@step} room={@room} />
      </section>

      <section class="presenter__desk">
        <.notes slide={@slide} />
      </section>
    </main>
    """
  end
end
