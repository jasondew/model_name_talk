defmodule ModelNameTalkWeb.FigureComponents do
  @moduledoc """
  The diagrams.

  The brief's rule is diagrams before bullets, and every figure here replaces
  a list the slide would otherwise have carried. Each one takes a `step` and
  arrives a piece at a time, because a diagram that appears complete is a
  diagram the room reads ahead of the speaker.

  Colour has one job for each figure. Magnitude gets a single hue; nothing
  else wears the accent, and text never does.
  """

  use Phoenix.Component

  attr :points, :list, required: true
  attr :step, :integer, default: 1
  attr :caption, :string, default: nil

  @doc """
  Sizes four orders of magnitude apart, as dots on a logarithmic axis.

  This started as a bar chart, which the brief asked for and which is wrong.
  A bar says magnitude with its length measured from zero, and a logarithmic
  axis has no zero to measure from: drawn that way our fifteen thousand
  parameter model came out about forty percent as long as a thirty billion
  parameter one, which reads as "roughly half" on a slide whose whole point
  is "two million times".

  A dot has no length, so it makes no such claim. Position carries the value,
  the decades are drawn and labelled so the scale is visible rather than
  asserted in a caption, and the ratio is said in words underneath.
  """
  def orders_of_magnitude(assigns) do
    values = Enum.map(assigns.points, &elem(&1, 1))
    low = values |> Enum.min() |> :math.log10() |> Float.floor() |> Kernel.-(0.5)
    high = values |> Enum.max() |> :math.log10() |> Float.ceil() |> Kernel.+(0.5)

    assigns =
      assigns
      |> assign(low: low, high: high)
      |> assign(decades: decades(low, high))

    ~H"""
    <figure class="figure figure--magnitude">
      <div class="magnitude">
        <div class="magnitude__grid">
          <div
            :for={decade <- @decades}
            class="magnitude__decade"
            style={"left: #{position(:math.pow(10, decade), @low, @high)}%"}
          >
            <span :if={decade_label(decade)} class="magnitude__decade-label">
              {decade_label(decade)}
            </span>
          </div>
        </div>

        <div
          :for={{{label, value}, order} <- Enum.with_index(@points, 1)}
          :if={order <= @step}
          class="magnitude__row"
        >
          <p class="magnitude__label">{label}</p>
          <div class="magnitude__track">
            <span class="magnitude__dot" style={"left: #{position(value, @low, @high)}%"}></span>
            <span class="magnitude__value" style={"left: #{position(value, @low, @high)}%"}>
              {humanise(value)}
            </span>
          </div>
        </div>
      </div>

      <figcaption :if={@caption} class="figure__caption">{@caption}</figcaption>
    </figure>
    """
  end

  ## PRIVATE FUNCTIONS

  defp decades(low, high) do
    low
    |> Float.ceil()
    |> trunc()
    |> Range.new(high |> Float.floor() |> trunc())
    |> Enum.to_list()
  end

  defp position(value, low, high) do
    (:math.log10(value) - low) / (high - low) * 100
  end

  # Only the decades people have words for get a label. "A billion" lands in a
  # room and "ten to the ninth" does not, and labelling all eight would put
  # more type on the slide than the three dots it exists to place.
  defp decade_label(3), do: "thousand"
  defp decade_label(6), do: "million"
  defp decade_label(9), do: "billion"
  defp decade_label(12), do: "trillion"
  defp decade_label(_decade), do: nil

  defp humanise(count) when count >= 1_000_000_000 do
    "#{Float.round(count / 1_000_000_000, 1)}B"
  end

  defp humanise(count) when count >= 1_000_000 do
    "#{trunc(Float.round(count / 1_000_000, 0))}M"
  end

  defp humanise(count) do
    count |> Integer.to_string() |> String.replace(~r/(\d)(?=(\d{3})+$)/, "\\1,")
  end
end
