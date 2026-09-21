defmodule ModelNameTalkWeb.DeckLiveTest do
  use ModelNameTalkWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ModelNameTalk.{Ledger, Room}

  setup do
    Room.reset()
    Ledger.forget()
    :ok
  end

  defp forward(view, times \\ 1) do
    Enum.each(1..times, fn _press ->
      render_keydown(view, "key", %{"key" => "ArrowRight"})
    end)

    view
  end

  defp back(view) do
    render_keydown(view, "key", %{"key" => "ArrowLeft"})

    view
  end

  test "opens the first round's question when it reaches that slide", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    forward(view)

    assert Room.state().round == :open_weights
    assert render(view) =~ "download the weights"
  end

  test "reveals on the next press rather than moving on", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    forward(view, 2)

    assert Room.state().phase == :revealed
    assert Room.state().round == :open_weights
  end

  test "moves to the next round once the answer is up", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    forward(view, 3)

    assert Room.state().round == :how_many_gpt2s
    assert Room.state().phase == :open
  end

  test "re-opens a round when the speaker walks backwards", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    forward(view, 3)

    back(view)

    assert Room.state().round == :open_weights
    assert Room.state().phase == :open
  end

  test "closes the round when it walks back off the first one", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    forward(view)

    back(view)

    assert is_nil(Room.state().round)
  end

  test "shows the answer count but never the tally before the reveal", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    forward(view)
    Room.join("token-one", "ada", self())
    Room.answer("token-one", "Qwen3")

    html = render(view)

    assert html =~ "1 answered"
    refute html =~ "deck__tally"
  end

  test "shows the tally once the answer is up", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    forward(view)
    Room.join("token-one", "ada", self())
    Room.answer("token-one", "Qwen3")

    forward(view)

    assert render(view) =~ "deck__tally"
  end

  test "shows the QR code and the join URL on every slide", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/")

    assert html =~ "deck__join"
    assert html =~ "/play"

    forward(view)
    assert render(view) =~ "deck__join"
  end

  test "renders every slide, forwards and back, with an empty room", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    for _press <- 1..25, do: assert(forward(view))
    for _press <- 1..25, do: assert(back(view))
  end

  test "the presenter view follows the deck", %{conn: conn} do
    {:ok, deck, _html} = live(conn, ~p"/")
    {:ok, presenter, _html} = live(conn, ~p"/presenter")

    forward(deck)

    assert render(presenter) =~ "download the weights"
  end

  test "the presenter can end a round early", %{conn: conn} do
    {:ok, deck, _html} = live(conn, ~p"/")
    {:ok, presenter, _html} = live(conn, ~p"/presenter")
    forward(deck)

    render_click(presenter, "lock", %{})

    assert Room.state().phase == :locked
  end

  test "the presenter can drive the deck too", %{conn: conn} do
    {:ok, deck, _html} = live(conn, ~p"/")
    {:ok, presenter, _html} = live(conn, ~p"/presenter")

    forward(presenter)

    assert Room.state().round == :open_weights
    assert render(deck) =~ "download the weights"
  end

  test "the presenter shows the standings", %{conn: conn} do
    {:ok, deck, _html} = live(conn, ~p"/")
    {:ok, presenter, _html} = live(conn, ~p"/presenter")
    forward(deck)
    Room.join("token-one", "ada", self())
    Room.answer("token-one", "Qwen3")
    forward(deck)

    assert render(presenter) =~ "ada"
  end

  describe "a window that arrives late" do
    # Reloading a window mid-talk is a plausible thing to do when something
    # looks stuck. Until the position was kept somewhere, a reloaded window
    # came back at the title while the room was on slide four, and the next
    # arrow press drove the game from the beginning.
    test "opens where the talk actually is", %{conn: conn} do
      {:ok, deck, _html} = live(conn, ~p"/")
      forward(deck, 3)

      {:ok, late, html} = live(conn, ~p"/presenter")

      assert html =~ "slide 3 of"
      assert render(late) =~ "GPT-2 small"
    end

    test "a reloaded deck carries on rather than rewinding the game", %{conn: conn} do
      {:ok, deck, _html} = live(conn, ~p"/")
      forward(deck, 3)

      {:ok, reloaded, _html} = live(conn, ~p"/")
      forward(reloaded)

      assert Room.state().round == :how_many_gpt2s
      assert Room.state().phase == :revealed
    end
  end
end
