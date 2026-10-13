defmodule ModelNameTalkWeb.DeckLive do
  @moduledoc """
  The window on the projector, or in this talk's case the window being shared.

  It holds the position, and moving it is what drives the game: arriving at a
  slide that asks a round opens it, the second press reveals the answer, and
  leaving closes it.

  While a round is open this shows how many people have answered and not what
  they answered. Watching the bars move would tell the last ten people what
  everybody else thinks, which is worth more to them than the question is.
  """

  use ModelNameTalkWeb, :live_view

  import ModelNameTalkWeb.SlideComponents

  alias ModelNameTalk.{Deck, Room}
  alias ModelNameTalkWeb.Position

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Position.subscribe()
      Room.subscribe()
    end

    {:ok,
     socket
     |> assign(position: Position.current(), room: Room.state())
     |> assign(page_title: "What's in a name?"), layout: false}
  end

  @impl true
  def handle_event("key", %{"key" => key}, socket) do
    {:noreply, move(socket, key)}
  end

  @impl true
  def handle_info({:position, position}, socket),
    do: {:noreply, assign(socket, position: position)}

  def handle_info({:room, room}, socket), do: {:noreply, assign(socket, room: room)}

  @impl true
  def render(assigns) do
    {index, step} = assigns.position

    assigns = assign(assigns, slide: Deck.at(index), step: step)

    ~H"""
    <main class="deck" phx-window-keydown="key">
      <.slide slide={@slide} step={@step} room={@room} />
    </main>
    """
  end

  ## PRIVATE FUNCTIONS

  # Shared by both windows: either one can hold the clicker, and the other
  # follows over PubSub.
  @doc false
  def move(socket, key) do
    case key do
      "ArrowRight" -> settled(socket, Position.forward(socket.assigns.position))
      " " -> settled(socket, Position.forward(socket.assigns.position))
      "ArrowLeft" -> settled(socket, Position.back(socket.assigns.position))
      _other -> socket
    end
  end

  defp settled(socket, position) do
    Position.broadcast(position)

    Phoenix.Component.assign(socket, position: position, room: Room.state())
  end
end
