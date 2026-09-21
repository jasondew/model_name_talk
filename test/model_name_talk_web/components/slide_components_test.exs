defmodule ModelNameTalkWeb.SlideComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias ModelNameTalk.{Deck, Room, Slide}
  alias ModelNameTalkWeb.{FigureComponents, SlideComponents}

  defp draw(slide, step \\ 1) do
    render_component(&SlideComponents.slide/1, slide: slide, step: step, room: %Room{})
  end

  defp find(id), do: Enum.find(Deck.slides(), &(&1.id == id))

  test "draws a slide that has no clause of its own as a stub" do
    unwritten = %Slide{id: :not_a_real_slide, title: "Unwritten", notes: "- a cue\n"}

    html = draw(unwritten)

    assert html =~ "slide--stub"
    assert html =~ "Unwritten"
    assert html =~ "a cue"
  end

  test "draws every slide in the deck, at every step, without raising" do
    for slide <- Deck.slides(), step <- 1..slide.steps do
      assert draw(slide, step), "#{slide.id} would not draw at step #{step}"
    end
  end

  test "puts the file name header on a chapter slide and not on the title" do
    assert draw(find(:qwen3_chapter)) =~ "filename__name"
    refute draw(find(:title)) =~ "filename__name"
  end

  test "lights the chapter's own segment in the header" do
    assert draw(find(:a3b_chapter)) =~ "filename__segment--current"
  end

  test "a term card draws every definition it carries" do
    card = find(:qwen3_terms)
    html = draw(card)

    for {term, _meaning} <- Slide.definitions(card) do
      assert html =~ term
    end
  end

  test "a round slide asks its question" do
    assert draw(find(:round_open_weights)) =~ "download the weights"
  end

  test "the magnitude figure marks each model and labels its value" do
    html =
      render_component(&FigureComponents.orders_of_magnitude/1,
        points: [{"ours", 15_104}, {"GPT-2 small", 124_000_000}],
        step: 2
      )

    assert html =~ "ours"
    assert html =~ "GPT-2 small"
    assert html =~ "15,104"
    assert html =~ "124M"
    assert html =~ "magnitude__dot"
  end

  test "the magnitude figure brings its marks in one step at a time" do
    points = [{"ours", 15_104}, {"GPT-2 small", 124_000_000}, {"this one", 30_532_122_624}]

    early = render_component(&FigureComponents.orders_of_magnitude/1, points: points, step: 1)
    late = render_component(&FigureComponents.orders_of_magnitude/1, points: points, step: 3)

    assert early =~ "ours"
    refute early =~ "this one"
    assert late =~ "this one"
  end

  # A bar says magnitude with its length from zero, and a logarithmic axis has
  # no zero. Drawn as bars, fifteen thousand came out about forty percent as
  # long as thirty billion, which reads as "roughly half" on the one slide
  # whose point is "two million times". Dots carry position and claim nothing
  # about length, and the decades are drawn so the scale is visible.
  test "the magnitude figure draws the decades rather than only asserting them" do
    html =
      render_component(&FigureComponents.orders_of_magnitude/1,
        points: [{"ours", 15_104}, {"this one", 30_532_122_624}],
        step: 2
      )

    assert html =~ "magnitude__decade"
    assert html =~ "million"
    assert html =~ "billion"
    refute html =~ "figure__bar"

    # Only the decades with words get labels. Eight labels for three dots is
    # more type than the figure is worth.
    refute html =~ "10^"
  end

  test "the magnitude figure places a value by its logarithm, not its size" do
    points = [{"small", 1_000}, {"large", 1_000_000_000}]
    html = render_component(&FigureComponents.orders_of_magnitude/1, points: points, step: 2)

    positions =
      Regex.scan(~r/magnitude__dot" style="left: ([\d.]+)%/, html)
      |> Enum.map(fn [_whole, number] -> String.to_float(number) end)

    assert [small, large] = positions
    assert small < large

    # Three decades apart out of the ten the axis spans, so the gap is a
    # fraction of the width rather than the thousandfold a bar would draw.
    assert_in_delta large - small, 75.0, 15.0
  end
end
