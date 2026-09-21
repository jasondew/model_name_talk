defmodule ModelNameTalkWeb.PresenterLive do
  @moduledoc """
  The window on the speaker's laptop.

  The same slide the room is looking at, and under it the things only the
  speaker needs: how many people have answered, the leaderboard, and a button
  that ends a round early.

  That button matters more than it looks. Twenty seconds of silence on a video
  call is a long time, and once twenty-eight of thirty-one people have
  answered there is no reason to spend the last eight seconds of it waiting.
  """

  use ModelNameTalkWeb, :live_view

  import ModelNameTalkWeb.DeckComponents
  import ModelNameTalkWeb.SlideComponents

  alias ModelNameTalk.{Deck, Room}
  alias ModelNameTalkWeb.{DeckLive, Position}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Position.subscribe()
      Room.subscribe()
    end

    {:ok,
     socket
     |> assign(position: Position.current(), room: Room.state())
     |> assign(join_url: Application.get_env(:model_name_talk, :join_url))
     |> assign(page_title: "Presenter"), layout: false}
  end

  @impl true
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
  def handle_info({:position, position}, socket),
    do: {:noreply, assign(socket, position: position, room: Room.state())}

  def handle_info({:room, room}, socket), do: {:noreply, assign(socket, room: room)}

  @impl true
  def render(assigns) do
    {index, step} = assigns.position

    assigns =
      assigns
      |> assign(slide: Deck.at(index), step: step)
      |> assign(standings: Room.standings())

    ~H"""
    <main class="presenter" phx-window-keydown="key">
      <section class="presenter__stage">
        <.slide slide={@slide} step={@step} room={@room} />
      </section>

      <section class="presenter__desk">
        <p class="presenter__where">
          slide {elem(@position, 0) + 1} of {Deck.length()}, step {@step}
        </p>

        <p class="presenter__here">
          {Room.connected_count(@room)} connected, {Room.participant_count(@room)} playing, {Room.answered_count(
            @room
          )} answered
        </p>

        <div class="presenter__controls">
          <button type="button" phx-click="lock" disabled={@room.phase != :open}>
            End the round early
          </button>
          <button type="button" phx-click="reveal" disabled={is_nil(@room.round)}>
            Show the answer
          </button>
        </div>

        <.standings standings={@standings} limit={8} />
      </section>
    </main>
    """
  end
end
