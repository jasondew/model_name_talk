defmodule ModelNameTalkWeb.FilenameComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import ModelNameTalkWeb.FilenameComponents

  alias ModelNameTalk.Filename

  test "draws every segment of the name" do
    html = render_component(&filename/1, chapter: 4)

    for segment <- Filename.segments() do
      assert html =~ segment.text
    end
  end

  test "marks the chapter on screen, what is behind it, and what is ahead" do
    html = render_component(&filename/1, chapter: 4)

    assert html =~ "filename__segment--current"
    assert html =~ "filename__segment--done"
    assert html =~ "filename__segment--pending"
  end

  test "marks nothing current before the first chapter with a segment" do
    html = render_component(&filename/1, chapter: 1)

    refute html =~ "filename__segment--current"
  end

  test "names the two authors only when asked" do
    plain = render_component(&filename/1, chapter: 8)
    split = render_component(&filename/1, chapter: 8, authors: true)

    refute plain =~ "filename__author"
    assert split =~ "filename__author"
    assert split =~ "Qwen wrote this"
    assert split =~ "whoever converted it"
  end

  test "the annotated name carries a label for every segment" do
    html = render_component(&annotated/1, %{})

    for segment <- Filename.segments() do
      assert html =~ segment.text
      assert html =~ escaped(segment.label)
    end
  end

  ## PRIVATE FUNCTIONS

  # Labels reach the page HTML-escaped, and one of them has an apostrophe in
  # it, so the comparison has to be against what actually gets written out.
  defp escaped(text) do
    text |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
  end
end
