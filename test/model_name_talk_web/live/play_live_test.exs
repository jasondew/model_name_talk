defmodule ModelNameTalkWeb.PlayLiveTest do
  use ModelNameTalkWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ModelNameTalk.{Ledger, Room}

  setup do
    Room.reset()
    Ledger.forget()
    :ok
  end

  defp joined(conn, handle \\ "ada") do
    {:ok, view, _html} = live(conn, ~p"/play")
    render_hook(view, "token", %{"token" => "token-#{handle}"})
    render_submit(view, "handle", %{"handle" => handle})

    view
  end

  test "asks for a handle before anything else", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/play")

    assert html =~ "What should we call you"
  end

  test "says you are in once you have a handle", %{conn: conn} do
    view = joined(conn)

    assert render(view) =~ "You are in"
  end

  test "refuses an empty handle", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/play")
    render_hook(view, "token", %{"token" => "token-blank"})

    render_submit(view, "handle", %{"handle" => "   "})

    assert render(view) =~ "What should we call you"
  end

  test "shows the question when a round opens", %{conn: conn} do
    view = joined(conn)

    Room.open(:open_weights)

    assert render(view) =~ "download the weights"
    assert render(view) =~ "Qwen3"
  end

  test "records an answer and says it landed", %{conn: conn} do
    view = joined(conn)
    Room.open(:open_weights)

    render_click(view, "answer", %{"value" => "", "choice" => "Qwen3"})

    assert Room.state().answers["token-ada"].value == "Qwen3"
    assert render(view) =~ "Locked in"
  end

  test "takes a typed number on a numeric round", %{conn: conn} do
    view = joined(conn)
    Room.open(:how_many_gigabytes)

    render_submit(view, "answer", %{"choice" => "74"})

    assert Room.state().answers["token-ada"].correct?
  end

  test "says how you did once the answer is revealed", %{conn: conn} do
    view = joined(conn)
    Room.open(:open_weights)
    render_click(view, "answer", %{"value" => "", "choice" => "Qwen3"})

    Room.reveal()

    assert render(view) =~ "Right"
  end

  test "says you were wrong, and what the answer was", %{conn: conn} do
    view = joined(conn)
    Room.open(:open_weights)
    render_click(view, "answer", %{"value" => "", "choice" => "Claude"})

    Room.reveal()

    html = render(view)
    assert html =~ "Not this time"
    assert html =~ "Qwen3"
  end

  test "clears the last round's answer when the next one opens", %{conn: conn} do
    view = joined(conn)
    Room.open(:open_weights)
    render_click(view, "answer", %{"value" => "", "choice" => "Qwen3"})

    Room.open(:how_many_gpt2s)

    refute render(view) =~ "Locked in"
  end

  test "keeps a returning phone's identity and score", %{conn: conn} do
    view = joined(conn)
    Room.open(:open_weights)
    render_click(view, "answer", %{"value" => "", "choice" => "Qwen3"})
    Room.reveal()

    {:ok, returning, _html} = live(conn, ~p"/play")
    render_hook(returning, "token", %{"token" => "token-ada"})

    html = render(returning)

    # Straight back into the live question, with the answer they already gave
    # still marked as theirs. No second join, and no second player.
    refute html =~ "What should we call you"
    assert html =~ "play__option--mine"
    assert Room.participant_count(Room.state()) == 1
    assert [%{handle: "ada", points: 15}] = Room.standings()

    _ = view
  end

  test "works for a phone that cannot keep a token", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/play")

    render_submit(view, "handle", %{"handle" => "ada"})

    assert render(view) =~ "What should we call you"
  end

  # A real browser merges a button's own value property into the event, and a
  # button without one sends an empty string. Naming the parameter "value"
  # meant that empty string overwrote the answer, the room dropped it for not
  # being an option, and the deck sat there saying nobody had answered. The
  # tests did not see it because render_click/3 hands the server its params
  # directly rather than reading them off the button.
  test "takes the answer from choice, not from the button's own value", %{conn: conn} do
    view = joined(conn)
    Room.open(:open_weights)

    assert render(view) =~ "phx-value-choice"
    refute render(view) =~ "phx-value-value"

    render_click(view, "answer", %{"value" => "", "choice" => "Qwen3"})

    assert Room.state().answers["token-ada"].value == "Qwen3"
  end
end
