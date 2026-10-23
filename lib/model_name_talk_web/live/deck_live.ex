defmodule ModelNameTalkWeb.DeckLive do
  @moduledoc """
  The window being screen shared.

  Either this or the presenter view can hold the clicker. Arrows or space
  move, and the left arrow goes back.
  """

  use ModelNameTalkWeb, :live_view

  import ModelNameTalkWeb.SlideComponents

  alias ModelNameTalk.Deck
  alias ModelNameTalkWeb.Position

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Position.subscribe()

    {:ok,
     socket
     |> assign(position: Position.current())
     |> assign(page_title: "What's in a name?"), layout: false}
  end

  @impl true
  def handle_event("key", %{"key" => key}, socket) do
    {:noreply, move(socket, key)}
  end

  @impl true
  def handle_info({:position, position}, socket),
    do: {:noreply, assign(socket, position: position)}

  @impl true
  def render(assigns) do
    {index, step} = assigns.position

    assigns = assign(assigns, slide: Deck.at(index), step: step)

    ~H"""
    <main class="deck" phx-window-keydown="key">
      <.slide slide={@slide} step={@step} />
    </main>
    """
  end

  @doc false
  # Shared by both windows: either one can hold the clicker, and the other
  # follows over PubSub.
  def move(socket, key) do
    case key do
      "ArrowRight" -> settled(socket, Position.forward(socket.assigns.position))
      " " -> settled(socket, Position.forward(socket.assigns.position))
      "ArrowLeft" -> settled(socket, Position.back(socket.assigns.position))
      _other -> socket
    end
  end

  ## PRIVATE FUNCTIONS

  defp settled(socket, position) do
    Position.broadcast(position)

    Phoenix.Component.assign(socket, position: position)
  end
end
