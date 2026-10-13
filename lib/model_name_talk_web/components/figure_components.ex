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

  attr :experts, :integer, required: true
  attr :tokens, :list, required: true
  attr :step, :integer, default: 1

  @doc """
  One Mixture of Experts layer: a router, and a grid of small feed forward
  blocks with the ones the current token uses lit.

  The router appears on the second press and the first token's experts on
  the third. Each press after that is the next token, lighting a different
  eight, while the experts earlier tokens used stay faintly lit. That is the
  answer to "why must all of it be in memory if only a little is used": a
  few tokens in, the touched experts are already spread across the grid.
  """
  def expert_grid(assigns) do
    shown = assigns.step - 2

    current =
      if shown >= 1,
        do: Enum.at(assigns.tokens, min(shown, length(assigns.tokens)) - 1, []),
        else: []

    earlier =
      assigns.tokens
      |> Enum.take(max(min(shown, length(assigns.tokens)) - 1, 0))
      |> List.flatten()
      |> MapSet.new()

    touched = earlier |> MapSet.union(MapSet.new(current)) |> MapSet.size()

    assigns =
      assign(assigns,
        current: current,
        earlier: earlier,
        touched: touched,
        token: min(max(shown, 0), length(assigns.tokens))
      )

    ~H"""
    <div class="figure__moe">
      <p :if={@step >= 2} class="figure__router">router</p>

      <div class="figure__grid">
        <span
          :for={expert <- 1..@experts}
          class={[
            "figure__expert",
            expert in @current && "figure__expert--active",
            (expert not in @current and MapSet.member?(@earlier, expert)) && "figure__expert--used"
          ]}
        ></span>
      </div>

      <p :if={@token == 0} class="figure__moe-caption">{@experts} experts</p>
      <p :if={@token >= 1} class="figure__moe-caption">
        token {@token}: {length(@current)} experts &middot; {@touched} of {@experts} touched so far
      </p>
    </div>
    """
  end

  @doc """
  A dense layer: one feed forward block, drawn the same height as the grid
  beside it so the comparison needs no caption.
  """
  def dense_layer(assigns) do
    ~H"""
    <div class="figure__moe">
      <div class="figure__dense">feed forward</div>
      <p class="figure__moe-caption">one block, always used</p>
    </div>
    """
  end

  attr :stages, :list, required: true
  attr :step, :integer, default: 1

  @doc """
  A pipeline: boxes with arrows between them, arriving one stage at a time.

  Pre-training and post-training are two different things that happen in an
  order, and an order is what a row of arrows says without a sentence.
  """
  def pipeline(assigns) do
    ~H"""
    <figure class="figure figure--pipeline">
      <div class="figure__pipeline">
        <%= for {stage, order} <- Enum.with_index(@stages, 1), order <= @step do %>
          <span :if={order > 1} class="figure__pipeline-arrow">&rarr;</span>
          <span class="figure__pipeline-stage">{stage}</span>
        <% end %>
      </div>
    </figure>
    """
  end

  attr :text, :string, required: true
  attr :step, :integer, default: 1

  @doc """
  Text exactly as the model receives it, with the special tokens picked out
  once the slide has been pressed.

  The point of the chat template slide is that a message is not a thing the
  model knows about: there is one string, and the template is how a
  conversation gets flattened into it. A drawing of chat bubbles would teach
  the opposite, so this draws the string.
  """
  def raw_text(assigns) do
    assigns = assign(assigns, parts: split_specials(assigns.text))

    ~H"""
    <pre class="raw"><%= for {kind, part} <- @parts do %><span class={
        kind == :special and @step >= 2 and "raw__special"
      }>{part}</span><% end %></pre>
    """
  end

  attr :values, :list, required: true
  attr :levels, :integer, default: 16
  attr :step, :integer, default: 1

  @doc """
  Weights on a number line, and the levels they are allowed to land on.

  Step one is the weights where they really are. Step two draws the sixteen
  places four bits can represent. Step three snaps each weight to its nearest
  level, which is the whole of quantisation in one movement.
  """
  def number_line(assigns) do
    ~H"""
    <figure class="figure figure--line">
      <div class="line">
        <span
          :for={level <- 0..(@levels - 1)}
          :if={@step >= 2}
          class="figure__level"
          style={"left: #{level / (@levels - 1) * 100}%"}
        ></span>

        <span
          :for={value <- @values}
          class={["figure__weight", @step >= 3 && "figure__weight--snapped"]}
          style={"left: #{on_line(snap(value, @levels, @step))}%"}
        ></span>
      </div>

      <figcaption class="figure__caption">
        {if @step >= 2,
          do: "#{@levels} levels is all four bits can say",
          else: "the weights as trained"}
      </figcaption>
    </figure>
    """
  end

  attr :parts, :list, required: true
  attr :step, :integer, default: 1

  @doc "The label taken apart, one piece explained for each press."
  def label_anatomy(assigns) do
    ~H"""
    <div class="anatomy">
      <div :for={{{text, meaning}, order} <- Enum.with_index(@parts, 1)} class="anatomy__part">
        <p class={["anatomy__text", order < @step && "anatomy__text--explained"]}>{text}</p>
        <p :if={order < @step} class="anatomy__meaning">{meaning}</p>
      </div>
    </div>
    """
  end

  attr :rows, :list, required: true
  attr :step, :integer, default: 1

  @doc """
  Real file sizes against what the formula predicts, with the bits that went
  into it.

  The bits column is the point: without it the room cannot see where the
  predicted size came from. BF16's 16 and Q8_0's 8.5 are known in advance,
  from the format and from the llama.cpp struct, so those rows are genuine
  predictions. Q4_K_M mixes formats, so its 4.8 is measured from real files
  rather than derived, and the slide says "about".
  """
  def accuracy_table(assigns) do
    ~H"""
    <table class="accuracy">
      <thead>
        <tr>
          <th class="accuracy__head"></th>
          <th class="accuracy__head">bits for each weight</th>
          <th class="accuracy__head">the formula</th>
          <th class="accuracy__head">real file</th>
          <th class="accuracy__head">formula is off by</th>
        </tr>
      </thead>
      <tbody>
        <tr
          :for={{{label, bits, real, predicted}, order} <- Enum.with_index(@rows, 1)}
          :if={order <= @step}
          class="accuracy__row"
        >
          <td class="accuracy__label">{label}</td>
          <td class="accuracy__bits">{bits}</td>
          <td class="accuracy__predicted">{predicted} GB</td>
          <td class="accuracy__real">{real} GB</td>
          <td class="accuracy__error">{error(real, predicted)}</td>
        </tr>
      </tbody>
    </table>
    """
  end

  attr :parts, :list, required: true
  attr :step, :integer, default: 1

  @doc """
  One file, divided into what it holds.

  GGUF's whole claim is that everything travels together, so the figure is
  one box with the parts inside it rather than four boxes side by side.
  """
  def file_box(assigns) do
    ~H"""
    <figure class="figure figure--file">
      <div class="file-box">
        <span
          :for={{part, order} <- Enum.with_index(@parts, 1)}
          :if={order <= @step}
          class="file-box__part"
        >
          {part}
        </span>
      </div>
    </figure>
    """
  end

  attr :headers, :list, required: true
  attr :rows, :list, required: true
  attr :step, :integer, default: 1
  attr :lit, :string, default: nil
  attr :variant, :string, default: nil

  @doc """
  A comparison, one row at a time.

  Three chapters turn on a distinction that is genuinely a table: what you get
  from a closed model against an open weights one, what each post-trained
  variant hands back, and what the quantisation labels cost. Prose makes the
  room hold four things at once; a table lets them look.

  `lit` names the row that is this talk's own answer, so the one the audience
  came to hear about stands out from its neighbours.
  """
  def comparison(assigns) do
    ~H"""
    <table class={["comparison", @variant && "comparison--#{@variant}"]}>
      <thead>
        <tr>
          <th :for={header <- @headers} class="comparison__head">{header}</th>
        </tr>
      </thead>
      <tbody>
        <tr
          :for={{cells, order} <- Enum.with_index(@rows, 1)}
          :if={order <= @step}
          class={["comparison__row", hd(cells) == @lit && "comparison__row--lit"]}
        >
          <td :for={cell <- cells} class="comparison__cell">{cell}</td>
        </tr>
      </tbody>
    </table>
    """
  end

  attr :formats, :list, required: true
  attr :step, :integer, default: 1
  attr :widest, :float, default: 16.0

  @doc """
  What each quantisation label costs, as a bar and a real file size.

  The bar is bits for each weight, which is the thing the label actually
  chooses. The number beside it is the file that choice produces, measured
  rather than predicted, so the room can see the formula working before it is
  shown the formula working.
  """
  def format_comparison(assigns) do
    ~H"""
    <div class="formats">
      <div
        :for={{{label, bits, gigabytes}, order} <- Enum.with_index(@formats, 1)}
        :if={order <= @step}
        class="formats__row"
      >
        <p class="formats__label">{label}</p>
        <div class="formats__track">
          <div class="formats__bar" style={"width: #{bits / @widest * 100}%"}>
            <span class="formats__bits">{bits}</span>
          </div>
        </div>
        <p class="formats__size">{gigabytes} GB</p>
      </div>
    </div>
    """
  end

  ## PRIVATE FUNCTIONS

  # Weights run from minus one to one; the line runs from zero to a hundred.
  defp on_line(value), do: (value + 1) / 2 * 100

  defp snap(value, _levels, step) when step < 3, do: value

  defp snap(value, levels, _step) do
    span = 2 / (levels - 1)

    round((value + 1) / span) * span - 1
  end

  defp error(real, predicted) do
    "#{Float.round((real - predicted) / predicted * 100, 2)}%"
  end

  # Chops the text into ordinary runs and `<|...|>` special tokens, keeping
  # both so the whole string renders exactly as the model would read it.
  defp split_specials(text) do
    ~r/<\|[^|]*\|>/
    |> Regex.split(text, include_captures: true)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(fn part ->
      if String.starts_with?(part, "<|"), do: {:special, part}, else: {:plain, part}
    end)
  end

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
