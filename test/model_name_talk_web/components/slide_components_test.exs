defmodule ModelNameTalkWeb.SlideComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias ModelNameTalk.{Deck, Room, Slide}
  alias ModelNameTalkWeb.{FigureComponents, SlideComponents}

  defp draw(slide, step \\ 1) do
    render_component(&SlideComponents.slide/1, slide: slide, step: step, room: %Room{})
  end

  defp find(id), do: Enum.find(Deck.slides(), &(&1.id == id))

  # In front of a room an undrawn slide is its title. Its notes are for the
  # speaker and stay on the presenter view.
  test "draws a slide with no clause of its own as its title, without its notes" do
    unwritten = %Slide{id: :not_a_real_slide, title: "Unwritten", notes: "- a cue\n"}

    html = draw(unwritten)

    assert html =~ "Unwritten"
    refute html =~ "a cue"
    refute html =~ "slide--stub"
  end

  test "a question slide holds its answer back until the second press" do
    question = find(:round_open_weights)

    refute draw(question, 1) =~ "slide__option--answer"
    assert draw(question, 2) =~ "slide__option--answer"
    assert draw(question, 2) =~ "The answer: Qwen3"
  end

  # It had three presses and five stages, one stage a press, so it stopped at
  # Base and never reached the thing the chapter is named after.
  test "the pipeline reaches Instruct on its last press" do
    pipeline = find(:the_pipeline)

    # The header always says Instruct, so look for the stage itself.
    stage = ~s(<span class="figure__pipeline-stage">Instruct</span>)

    refute draw(pipeline, 1) =~ stage
    assert draw(pipeline, pipeline.steps) =~ stage
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

  # These were falling through to the stub, which prints a slide's notes on
  # screen. The notes for a chapter opener said "Chapter title", so the room
  # would have read an instruction meant for whoever drew the slide.
  test "every chapter opener draws its segment, and is not a stub" do
    openers =
      Deck.slides()
      |> Enum.filter(&String.ends_with?(to_string(&1.id), "_chapter"))

    assert length(openers) == 7

    for opener <- openers do
      html = draw(opener)

      refute html =~ "slide--stub", "#{opener.id} is still falling through to the stub"
      assert html =~ "slide__segment"
    end
  end

  test "no slide ever shows its own speaker notes to the room" do
    for slide <- Deck.slides(), step <- 1..slide.steps do
      refute draw(slide, step) =~ "Chapter title"
    end
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

  test "the file box shows what one gguf holds" do
    html =
      render_component(&FigureComponents.file_box/1,
        parts: ["metadata", "tokenizer", "chat template", "tensors"],
        step: 4
      )

    for part <- ["metadata", "tokenizer", "chat template", "tensors"] do
      assert html =~ part
    end
  end

  # The room has been reading this string for forty minutes. Drawing the line
  # through it is the whole argument, and a new picture would weaken it.
  test "the two authors slide splits the header rather than drawing a new picture" do
    html = draw(find(:two_authors), 2)

    assert html =~ "filename__author"
    assert html =~ "Qwen wrote this"
  end

  test "the close shows the annotated name with every label" do
    html = draw(find(:annotated_name))

    for segment <- ModelNameTalk.Filename.segments() do
      assert html =~ segment.text
    end

    assert html =~ "annotated__label"
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
