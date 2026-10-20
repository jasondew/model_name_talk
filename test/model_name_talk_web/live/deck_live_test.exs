defmodule ModelNameTalkWeb.DeckLiveTest do
  use ModelNameTalkWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ModelNameTalk.{Deck, Ledger, Room}

  setup do
    Room.reset()
    Ledger.forget()
    :ok
  end

  defp forward(view, times \\ 1) do
    Enum.each(1..times//1, fn _press ->
      render_keydown(view, "key", %{"key" => "ArrowRight"})
    end)

    view
  end

  defp back(view) do
    render_keydown(view, "key", %{"key" => "ArrowLeft"})

    view
  end

  # How many presses it takes to land on a slide at its first step. Counting
  # presses in each test would mean editing every test whenever a slide is
  # added, which is the thing writing the deck does constantly.
  defp presses_to(slide_id) do
    Deck.slides()
    |> Enum.take_while(&(&1.id != slide_id))
    |> Enum.map(& &1.steps)
    |> Enum.sum()
  end

  defp press_to(view, slide_id), do: forward(view, presses_to(slide_id))

  describe "driving a round from the slide on screen" do
    test "opens the first round's question when it reaches that slide", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      press_to(view, :round_open_weights)

      assert Room.state().round == :open_weights
      assert render(view) =~ "download the weights"
    end

    test "reveals on the next press rather than moving on", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      press_to(view, :round_open_weights)

      forward(view)

      assert Room.state().phase == :revealed
      assert Room.state().round == :open_weights
    end

    test "closes the round when it moves to the next chapter", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      press_to(view, :round_open_weights)
      forward(view, 2)

      assert is_nil(Room.state().round)
    end

    test "re-opens and re-asks a round when the speaker walks backwards", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      press_to(view, :round_open_weights)
      forward(view)

      assert Room.state().phase == :revealed

      forward(view)
      back(view)

      assert Room.state().round == :open_weights
      assert Room.state().phase == :open
    end

    # The room remembers the position, so a fresh window opens where the talk
    # already is. Each round therefore gets its own reset rather than its own
    # window starting from the title.
    test "asks every round in the deck, each in its own chapter", %{conn: conn} do
      for slide <- Deck.slides(), slide.round do
        Room.reset()
        {:ok, view, _html} = live(conn, ~p"/")
        press_to(view, slide.id)

        assert Room.state().round == slide.round, "#{slide.id} did not open its round"
        assert Room.state().phase == :open
      end
    end
  end

  describe "what the room can see" do
    test "shows the question without its answer before the second press", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      press_to(view, :round_open_weights)

      html = render(view)

      assert html =~ "download the weights"
      refute html =~ "The answer:"
    end

    test "shows the answer on the second press", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      press_to(view, :round_open_weights)

      forward(view)

      assert render(view) =~ "The answer: Qwen3"
    end

    # Slides only: there is nothing for the audience to join.
    test "shows no join code on any slide", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/")

      refute html =~ "deck__join"

      press_to(view, :round_open_weights)
      refute render(view) =~ "deck__join"
    end
  end

  test "renders every slide, forwards and back, with an empty room", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    every_press = Deck.slides() |> Enum.map(& &1.steps) |> Enum.sum()

    for _press <- 1..every_press, do: assert(forward(view))
    for _press <- 1..every_press, do: assert(back(view))
  end

  describe "the two windows" do
    test "the presenter view follows the deck", %{conn: conn} do
      {:ok, deck, _html} = live(conn, ~p"/")
      {:ok, presenter, _html} = live(conn, ~p"/presenter")

      press_to(deck, :round_open_weights)

      assert render(presenter) =~ "download the weights"
    end

    test "the presenter can end a round early", %{conn: conn} do
      {:ok, deck, _html} = live(conn, ~p"/")
      {:ok, presenter, _html} = live(conn, ~p"/presenter")
      press_to(deck, :round_open_weights)

      render_click(presenter, "lock", %{})

      assert Room.state().phase == :locked
    end

    test "the presenter can drive the deck too", %{conn: conn} do
      {:ok, deck, _html} = live(conn, ~p"/")
      {:ok, presenter, _html} = live(conn, ~p"/presenter")

      press_to(presenter, :round_open_weights)

      assert Room.state().round == :open_weights
      assert render(deck) =~ "download the weights"
    end
  end

  describe "a window that arrives late" do
    # Reloading a window mid-talk is a plausible thing to do when something
    # looks stuck. Until the position was kept somewhere, a reloaded window
    # came back at the title while the room was on slide four, and the next
    # arrow press drove the game from the beginning.
    test "opens where the talk actually is", %{conn: conn} do
      {:ok, deck, _html} = live(conn, ~p"/")
      press_to(deck, :round_open_weights)

      {:ok, late, _html} = live(conn, ~p"/presenter")

      assert render(late) =~ "download the weights"
    end

    test "a reloaded deck carries on rather than rewinding the game", %{conn: conn} do
      {:ok, deck, _html} = live(conn, ~p"/")
      press_to(deck, :round_open_weights)

      {:ok, reloaded, _html} = live(conn, ~p"/")
      forward(reloaded)

      assert Room.state().round == :open_weights
      assert Room.state().phase == :revealed
    end
  end

  describe "what the speaker sees" do
    test "the next slide, before the room sees it", %{conn: conn} do
      {:ok, presenter, _html} = live(conn, ~p"/presenter")
      [first, second | _rest] = Deck.slides()

      forward(presenter, first.steps - 1)

      html = render(presenter)
      assert html =~ "Next slide: 2. #{second.title}"
      assert html =~ "presenter__preview"
    end

    test "the next press within a slide, when the slide builds", %{conn: conn} do
      {:ok, presenter, _html} = live(conn, ~p"/presenter")
      building = Enum.find(Deck.slides(), &(&1.steps > 1 and is_nil(&1.round)))

      press_to(presenter, building.id)

      assert render(presenter) =~ "Next press: step 2 of this slide"
    end

    test "looking ahead does not move the room", %{conn: conn} do
      {:ok, presenter, _html} = live(conn, ~p"/presenter")
      press_to(presenter, :round_open_weights)
      before = Room.state()

      render(presenter)

      assert Room.state() == before
    end

    test "the notes, with what must be said out loud marked", %{conn: conn} do
      {:ok, presenter, html} = live(conn, ~p"/presenter")

      assert html =~ "notes__must"
      assert html =~ "Say the title once"

      _ = presenter
    end

    test "the line this section has to land", %{conn: conn} do
      {:ok, _presenter, html} = live(conn, ~p"/presenter")

      assert html =~ Deck.section(hd(Deck.slides())).lands
    end

    test "a term card's definitions arrive as a glossary", %{conn: conn} do
      {:ok, presenter, _html} = live(conn, ~p"/presenter")
      press_to(presenter, :qwen3_terms)

      assert render(presenter) =~ "notes__definition"
    end

    test "where the talk is, against where it should be", %{conn: conn} do
      {:ok, _presenter, html} = live(conn, ~p"/presenter")

      assert html =~ "slide 1 of"
      assert html =~ "00:00"
    end

    test "the clock resets on r without moving the deck", %{conn: conn} do
      {:ok, presenter, _html} = live(conn, ~p"/presenter")
      press_to(presenter, :qwen3_terms)
      where = Room.position()

      render_keydown(presenter, "key", %{"key" => "r"})

      assert Room.position() == where
      assert render(presenter) =~ "00:00"
    end
  end
end
