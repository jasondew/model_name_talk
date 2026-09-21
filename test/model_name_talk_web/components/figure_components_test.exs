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
end
