defmodule ModelNameTalkWeb.SheetLiveTest do
  use ModelNameTalkWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias ModelNameTalk.{Deck, Filename, Slide}

  test "carries the annotated name, the formula and every term", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/sheet")

    for segment <- Filename.segments() do
      assert html =~ segment.text
    end

    assert html =~ "annotated__label"
    assert html =~ "bits"

    for {term, _meaning} <- every_definition() do
      assert html =~ term, "the sheet is missing #{term}"
    end
  end

  # Gathered from the slides rather than typed again, so a term card and the
  # sheet cannot disagree about what a word means.
  test "gathers its terms from the slides themselves", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/sheet")

    assert length(every_definition()) >= 20
    assert html =~ "sheet__term"
  end

  ## PRIVATE FUNCTIONS

  defp every_definition do
    Deck.slides() |> Enum.flat_map(&Slide.definitions/1)
  end
end
