defmodule ModelNameTalkWeb.PlayLive do
  @moduledoc """
  What the audience plays on.

  One screen, no scrolling and no explanation: whatever the deck has open is
  what this shows, and when nothing is open it says so rather than inventing
  something to do. Somebody who joins late, or who answered a question twenty
  minutes ago and locked their phone, gets the current question the moment
  they look.

  It never draws slide content. The slides arrive over a screen share and this
  arrives over a websocket, so anything drawn in both places would disagree
  with itself by a second or two in front of everybody.

  The identity is a token in local storage rather than this process, which is
  the whole reason a phone can sleep here. The `TokenKeeper` hook mints one on
  a first visit and replays it on every reconnect.
  """

  use ModelNameTalkWeb, :live_view

  alias ModelNameTalk.{Room, Round}

  @longest_handle 24

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Room.subscribe()

    {:ok,
     socket
     |> assign(room: Room.state(), token: nil, handle: nil)
     |> assign(page_title: "How to Read a Model Name"), layout: false}
  end

  @impl true
  def handle_event("token", %{"token" => token}, socket) do
    room = Room.state()
    handle = get_in(room.participants, [token, Access.key(:handle)])

    if handle, do: Room.join(token, handle, self())

    {:noreply, assign(socket, token: token, handle: handle, room: Room.state())}
  end

  # Without a token there is nobody to register, so the form stays up rather
  # than letting somebody answer into a score that cannot be kept.
  def handle_event("handle", _params, %{assigns: %{token: nil}} = socket),
    do: {:noreply, socket}

  def handle_event("handle", %{"handle" => handle}, socket) do
    case String.trim(handle) do
      "" ->
        {:noreply, socket}

      trimmed ->
        chosen = String.slice(trimmed, 0, @longest_handle)
        Room.join(socket.assigns.token, chosen, self())

        {:noreply, assign(socket, handle: chosen, room: Room.state())}
    end
  end

  def handle_event("answer", %{"value" => value}, socket) do
    Room.answer(socket.assigns.token, value)

    {:noreply, assign(socket, room: Room.state())}
  end

  @impl true
  def handle_info({:room, room}, socket), do: {:noreply, assign(socket, room: room)}

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(round: Round.fetch(assigns.room.round))
      |> assign(mine: mine(assigns))

    ~H"""
    <main class="play" id="play" phx-hook="TokenKeeper">
      <p class="play__brand">How to Read a Model Name</p>

      <form :if={is_nil(@handle)} class="play__handle" phx-submit="handle">
        <label class="play__handle-label" for="handle">What should we call you?</label>
        <input class="play__handle-input" id="handle" name="handle" autocomplete="off" />
        <button class="play__handle-go" type="submit">Join</button>
      </form>

      <div :if={@handle && is_nil(@round)} class="play__idle">
        <p class="play__idle-title">You are in, {@handle}.</p>
        <p class="play__idle-body">Leave this open. A question will appear here.</p>
      </div>

      <div :if={@handle && @round} class="play__round">
        <p class="play__question">{@round.question}</p>
        <p :if={@round.hint} class="play__hint">{@round.hint}</p>

        <div :if={@round.type == :choice} class="play__options">
          <button
            :for={option <- @round.options}
            type="button"
            phx-click="answer"
            phx-value-value={option}
            disabled={@room.phase != :open}
            class={["play__option", @mine == option && "play__option--mine"]}
          >
            {option}
          </button>
        </div>

        <form :if={@round.type == :numeric} class="play__numeric" phx-submit="answer">
          <input
            class="play__numeric-input"
            name="value"
            inputmode="decimal"
            autocomplete="off"
            disabled={@room.phase != :open}
            value={@mine}
          />
          <button class="play__numeric-go" type="submit" disabled={@room.phase != :open}>
            Send
          </button>
        </form>

        <p :if={@mine && @room.phase == :open} class="play__state">
          Locked in. Change it if you like.
        </p>
        <p :if={is_nil(@mine) && @room.phase != :open} class="play__state">
          Time. You sat this one out.
        </p>

        <div :if={@room.phase == :revealed} class="play__result">
          <p :if={correct?(@round, @mine)} class="play__result-yes">Right.</p>
          <p :if={@mine && !correct?(@round, @mine)} class="play__result-no">Not this time.</p>
          <p class="play__result-answer">{answer_line(@round)}</p>
        </div>
      </div>
    </main>
    """
  end

  ## PRIVATE FUNCTIONS

  defp mine(%{token: nil}), do: nil

  defp mine(%{room: room, token: token}) do
    get_in(room.answers, [token, Access.key(:value)])
  end

  defp correct?(_round, nil), do: false
  defp correct?(round, value), do: Round.correct?(round, value)

  defp answer_line(%Round{type: :choice, answer: answer}), do: "The answer: #{answer}"

  defp answer_line(%Round{type: :numeric, answer: answer, band: {low, high}}) do
    "The answer: about #{answer}. Anything from #{low} to #{high} counted."
  end
end
