defmodule ModelNameTalkWeb.FigureComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import ModelNameTalkWeb.FigureComponents

  # Counting by class prefix: HEEx leaves a trailing space in a class list
  # whose last entry is false, so an exact match misses every inactive expert.
  defp count(html, prefix) do
    html |> String.split(~s(class="#{prefix})) |> length() |> Kernel.-(1)
  end

  describe "the expert grid" do
    test "draws every expert" do
      html = render_component(&expert_grid/1, experts: 128, active: [3, 9, 20], step: 3)

      assert count(html, "figure__expert") == 128
    end

    test "lights only the experts the router picked" do
      html = render_component(&expert_grid/1, experts: 128, active: [3, 9, 20], step: 3)

      assert count(html, "figure__expert figure__expert--active") == 3
    end

    test "lights nothing before the router has run" do
      html = render_component(&expert_grid/1, experts: 128, active: [3, 9, 20], step: 1)

      refute html =~ "figure__expert--active"
    end

    test "draws the router once the layer is on screen" do
      early = render_component(&expert_grid/1, experts: 16, active: [1], step: 1)
      later = render_component(&expert_grid/1, experts: 16, active: [1], step: 2)

      refute early =~ "figure__router"
      assert later =~ "figure__router"
    end
  end

  describe "the dense layer beside it" do
    test "draws one block, the same height as the grid" do
      html = render_component(&dense_layer/1, %{})

      assert html =~ "figure__dense"
      assert html =~ "feed forward"
    end
  end

  describe "the pipeline" do
    test "draws each stage, arriving one at a time" do
      stages = ["text corpus", "pre-training", "base", "post-training", "Instruct"]

      early = render_component(&pipeline/1, stages: stages, step: 1)
      late = render_component(&pipeline/1, stages: stages, step: 5)

      assert early =~ "text corpus"
      refute early =~ "Instruct"
      assert late =~ "Instruct"
    end

    test "puts an arrow between stages and not after the last one" do
      html = render_component(&pipeline/1, stages: ["one", "two", "three"], step: 3)

      assert count(html, "figure__pipeline-arrow") == 2
    end
  end

  describe "the raw chat template" do
    test "shows the real special tokens rather than a picture of a chat" do
      html = render_component(&raw_text/1, text: "<|im_start|>user\nhi<|im_end|>", step: 2)

      assert html =~ "im_start"
      assert html =~ "im_end"
    end

    test "lights the special tokens on the second step" do
      early = render_component(&raw_text/1, text: "<|im_start|>hi<|im_end|>", step: 1)
      later = render_component(&raw_text/1, text: "<|im_start|>hi<|im_end|>", step: 2)

      refute early =~ "raw__special"
      assert later =~ "raw__special"
    end
  end

  describe "the quantisation figures" do
    test "the number line snaps each weight to one of sixteen levels" do
      html =
        render_component(&number_line/1, values: [0.13, -0.42, 0.87, -0.05], levels: 16, step: 3)

      assert count(html, "figure__level") == 16
      assert count(html, "figure__weight") == 4
    end

    test "the number line shows the weights before it shows the levels" do
      early = render_component(&number_line/1, values: [0.13, -0.42], levels: 16, step: 1)

      assert early =~ "figure__weight"
      refute early =~ "figure__level"
    end

    test "the label anatomy explains each part of Q4_K_M" do
      html =
        render_component(&label_anatomy/1,
          parts: [{"Q4", "4 bits for each weight"}, {"K", "k-quant"}, {"M", "medium"}],
          step: 4
        )

      for part <- ~w(Q4 K M), do: assert(html =~ part)
      assert html =~ "k-quant"
    end

    test "the label anatomy reveals one part at a time" do
      parts = [{"Q4", "four bits"}, {"K", "k-quant"}, {"M", "medium"}]

      early = render_component(&label_anatomy/1, parts: parts, step: 1)
      late = render_component(&label_anatomy/1, parts: parts, step: 4)

      refute early =~ "four bits"
      assert late =~ "medium"
    end

    test "the accuracy table carries real sizes against what the formula predicts" do
      html =
        render_component(&accuracy_table/1,
          rows: [{"Q8_0", 32.48, 32.44}, {"Q4_K_M", 18.56, 18.32}],
          step: 3
        )

      assert html =~ "32.48"
      assert html =~ "18.32"
      assert html =~ "%"
    end

    test "the accuracy table brings rows in one at a time" do
      rows = [{"BF16", 61.10, 61.06}, {"Q8_0", 32.48, 32.44}, {"Q4_K_M", 18.56, 18.32}]

      early = render_component(&accuracy_table/1, rows: rows, step: 1)

      assert early =~ "BF16"
      refute early =~ "Q4_K_M"
    end
  end
end
