defmodule ModelNameTalkWeb.SlideComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias ModelNameTalk.{Deck, Slide}
  alias ModelNameTalkWeb.{FigureComponents, SlideComponents}

  defp draw(slide, step \\ 1) do
    render_component(&SlideComponents.slide/1, slide: slide, step: step)
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

    first = draw(pipeline, 1)

    assert first =~ ~s(<span class="figure__pipeline-stage">a great deal of text</span>)
    refute first =~ ~s(<span class="figure__pipeline-stage">pre-training</span>)
    refute first =~ stage
    assert draw(pipeline, pipeline.steps) =~ stage
  end

  # Both had fewer presses than pieces, so their last piece never appeared.
  test "the kinds of model reach Thinking on the last press" do
    slide = find(:kinds_of_model)

    refute draw(slide, 1) =~ "reasoning first"
    assert draw(slide, slide.steps) =~ "reasoning first, then an answer"
  end

  test "the label explains M on the last press" do
    slide = find(:the_label)

    refute draw(slide, 1) =~ "medium"
    assert draw(slide, slide.steps) =~ "medium"
  end

  # mix format turned the template into a plain HTML attribute, where a
  # backslash n is two literal characters, so the slide printed "\n" and ran
  # the whole conversation onto one line.
  test "the chat template breaks onto real lines, with no literal backslash n" do
    html = draw(find(:chat_template), 2)

    refute html =~ "\\n"
    assert html =~ "user\nWhat is the capital"
  end

  test "the chat template sends the question, then shows the reply, then lights the tokens" do
    slide = find(:chat_template)

    refute draw(slide, 1) =~ "Paris"
    assert draw(slide, 2) =~ "The capital of France is Paris."
    refute draw(slide, 2) =~ "raw__special"
    assert draw(slide, 3) =~ "raw__special"
  end

  test "the blocks slide shows the outlier wiping out a shared scale, then a block saving it" do
    slide = find(:why_blocks)

    first = draw(slide, 1)
    assert first =~ "one scale for everything"
    refute first =~ "its own block of 32"

    assert draw(slide, slide.steps) =~ "its own block of 32"
  end

  test "the memory and speed slide adds up to 30.5B stored and 3.3B used" do
    slide = find(:memory_and_speed)

    refute draw(slide, 1) =~ "128 of them"
    assert draw(slide, 3) =~ "30.5B"
    assert draw(slide, 3) =~ "3.3B"
    refute draw(slide, 3) =~ "slide__equation"
    assert draw(slide, slide.steps) =~ "slide__equation"
  end

  test "the model only fits the GPU on the last press" do
    slide = find(:why_quantize)

    refute draw(slide, 1) =~ "fits</span>"
    refute draw(slide, 3) =~ "fits</span>"
    assert draw(slide, slide.steps) =~ "fits</span>"
  end

  test "the formula is worked through to 18.3 GB" do
    slide = find(:the_formula)

    refute draw(slide, 1) =~ "18.3 GB"
    assert draw(slide, 2) =~ "4.8 bits"
    assert draw(slide, 3) =~ "18.3 GB"
  end

  test "the precision slide draws each format's bits, one a press" do
    slide = find(:precision)

    first = draw(slide, 1)
    assert first =~ "FP32"
    assert first =~ "bits__field--exponent"
    refute first =~ "BF16"

    last = draw(slide, slide.steps)
    assert last =~ "INT4"
    assert last =~ "0.1001"
  end

  test "the quantized toy model holds to 4 bits and breaks at 2" do
    slide = find(:quality_and_speed)

    refute draw(slide, 1) =~ "who who"
    assert draw(slide, slide.steps) =~ "who who"
    assert draw(slide, slide.steps) =~ "Broken at 2"
  end

  test "one question gets three kinds of answer, one a press" do
    slide = find(:base_continues)

    first = draw(slide, 1)
    assert first =~ "How do I make a cup of tea?"
    refute first =~ "How do I boil an egg"

    assert draw(slide, 2) =~ "How do I boil an egg"
    refute draw(slide, 2) =~ "&lt;think&gt;"
    assert draw(slide, slide.steps) =~ "&lt;think&gt;"
    refute draw(slide, slide.steps) =~ "Embedding"
  end

  # The round after it asks what a base model does with "What is the capital
  # of France?". Showing that exact exchange first would give the answer away.
  test "the examples do not give away the round that follows" do
    slide = find(:base_continues)

    refute draw(slide, slide.steps) =~ "capital of France"
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

  test "the magnitude figure writes a trillion as T, not thousands of B" do
    html =
      render_component(&FigureComponents.orders_of_magnitude/1,
        points: [{"this one", 30_532_122_624}, {"Kimi K3", 2_800_000_000_000}],
        step: 2
      )

    assert html =~ "2.8T"
    assert html =~ "trillion"
    refute html =~ "2800.0B"
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
