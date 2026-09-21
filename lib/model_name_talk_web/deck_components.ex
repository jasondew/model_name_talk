defmodule ModelNameTalkWeb.DeckComponents do
  @moduledoc """
  The pieces both windows draw.

  The chrome both windows draw around a slide: the way in, and the board.
  The slide itself lives in `ModelNameTalkWeb.SlideComponents`, which has one
  clause for each slide id.
  """

  use Phoenix.Component

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
end
