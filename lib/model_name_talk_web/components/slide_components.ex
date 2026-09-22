defmodule ModelNameTalkWeb.SlideComponents do
  @moduledoc """
  How each slide is drawn.

  One clause of `slide/1` for each slide id, matched on the id and nowhere
  else, so finding the drawing of a slide is a search for its name. A slide
  with no clause yet falls through to a stub on a hatched background that
  shows its title and its notes, which means the deck is presentable at every
  point while it is being written and an unwritten slide is obvious from the
  back of the room rather than being a crash.

  `<.step n={2} step={@step}>` shows its contents from step two onward, and a
  slide's `steps:` in the deck says how many presses it takes.
  """

  use Phoenix.Component

  import ModelNameTalkWeb.DeckComponents, only: [standings: 1]
  import ModelNameTalkWeb.FigureComponents
  import ModelNameTalkWeb.FilenameComponents

  alias ModelNameTalk.{Filename, Room, Round, Slide}

  attr :n, :integer, required: true
  attr :step, :integer, required: true
  slot :inner_block, required: true

  @doc "Shows its contents once the slide has been pressed n times."
  def step(assigns) do
    ~H"""
    <div :if={@step >= @n} class="step">{render_slot(@inner_block)}</div>
    """
  end

  attr :slide, :map, required: true
  attr :step, :integer, required: true
  attr :room, :map, required: true

  @doc "One slide, drawn by its id."

  ## CHAPTER 1, OPENING

  def slide(%{slide: %Slide{id: :title}} = assigns) do
    ~H"""
    <section class="slide slide--centred">
      <h1 class="slide__title">{@slide.title}</h1>
      <p class="slide__subtitle">{Filename.text()}</p>
    </section>
    """
  end

  def slide(%{slide: %Slide{id: :the_name}} = assigns) do
    ~H"""
    <section class="slide slide--centred">
      <p class="slide__filename-huge">{Filename.text()}</p>
    </section>
    """
  end

  ## CHAPTER 3, 30B

  def slide(%{slide: %Slide{id: :how_big}} = assigns) do
    ~H"""
    <section class="slide">
      <.filename chapter={@slide.chapter} />
      <h2 class="slide__title">{@slide.title}</h2>

      <.orders_of_magnitude
        step={@step}
        caption="each mark along is ten times the one before it"
        points={[
          {"ours", 15_104},
          {"GPT-2 small", 124_000_000},
          {"this one", 30_532_122_624}
        ]}
      />

      <.step n={3} step={@step}>
        <p class="slide__caption">About two million times our model.</p>
      </.step>
    </section>
    """
  end

  ## CHAPTER 4, A3B

  def slide(%{slide: %Slide{id: :dense_or_sparse}} = assigns) do
    ~H"""
    <section class="slide">
      <.filename chapter={@slide.chapter} />
      <h2 class="slide__title slide__title--small">{@slide.title}</h2>

      <div class="slide__pair">
        <.dense_layer />
        <.expert_grid experts={128} active={[6, 19, 31, 44, 68, 83, 101, 119]} step={@step} />
      </div>
    </section>
    """
  end

  # Two lines, and the largest type in the deck. This is the chapter, and
  # everything before it exists to make these two lines mean something.
  def slide(%{slide: %Slide{id: :memory_and_speed}} = assigns) do
    ~H"""
    <section class="slide slide--centred">
      <.filename chapter={@slide.chapter} />

      <p class="slide__equation">
        <span class="slide__equation-from">Total parameters</span>
        <span class="slide__equation-arrow">&rarr;</span>
        <span class="slide__equation-to">memory</span>
      </p>

      <.step n={2} step={@step}>
        <p class="slide__equation">
          <span class="slide__equation-from">Active parameters</span>
          <span class="slide__equation-arrow">&rarr;</span>
          <span class="slide__equation-to">speed</span>
        </p>
      </.step>
    </section>
    """
  end

  ## CHAPTER 5, INSTRUCT

  def slide(%{slide: %Slide{id: :the_pipeline}} = assigns) do
    ~H"""
    <section class="slide">
      <.filename chapter={@slide.chapter} />
      <h2 class="slide__title slide__title--small">{@slide.title}</h2>

      <.pipeline
        step={@step}
        stages={["a great deal of text", "pre-training", "Base", "post-training", "Instruct"]}
      />
    </section>
    """
  end

  def slide(%{slide: %Slide{id: :chat_template}} = assigns) do
    ~H"""
    <section class="slide">
      <.filename chapter={@slide.chapter} />
      <h2 class="slide__title slide__title--small">{@slide.title}</h2>

      <.raw_text
        step={@step}
        text="<|im_start|>user\nWhat is the capital of France?<|im_end|>\n<|im_start|>assistant\n"
      />

      <.step n={2} step={@step}>
        <p class="slide__caption">The lit parts are just tokens. The model cannot see a message.</p>
      </.step>
    </section>
    """
  end

  def slide(%{slide: %Slide{id: :demo_base_instruct}} = assigns) do
    ~H"""
    <section class="slide slide--centred">
      <.filename chapter={@slide.chapter} />
      <p class="slide__demo">DEMO</p>
      <p class="slide__caption">One prompt. Qwen3-4B-Base, then Qwen3-4B-Instruct-2507.</p>
    </section>
    """
  end

  # A missing screenshot draws a bordered note saying what belongs there,
  # rather than a broken image on a projector. The fallback for the demo must
  # not itself need a fallback.
  def slide(%{slide: %Slide{id: :demo_base_instruct_fallback}} = assigns) do
    assigns = assign(assigns, shot: screenshot("demo-base-instruct.png"))

    ~H"""
    <section class="slide">
      <.filename chapter={@slide.chapter} />
      <h2 class="slide__title slide__title--small">{@slide.title}</h2>

      <img
        :if={@shot}
        src={@shot}
        alt="The same prompt sent to a base model and an instruct model"
        class="slide__shot"
      />

      <p :if={is_nil(@shot)} class="slide__missing">
        Rehearsal screenshot goes here: priv/static/images/demo-base-instruct.png
      </p>
    </section>
    """
  end

  ## CHAPTER 7, Q4_K_M

  def slide(%{slide: %Slide{id: :the_formula}} = assigns) do
    ~H"""
    <section class="slide slide--centred">
      <.filename chapter={@slide.chapter} />
      <p class="slide__formula">parameters &times; bits &divide; 8</p>
      <p class="slide__caption">billions in, gigabytes out</p>
    </section>
    """
  end

  def slide(%{slide: %Slide{id: :the_method}} = assigns) do
    ~H"""
    <section class="slide">
      <.filename chapter={@slide.chapter} />
      <h2 class="slide__title slide__title--small">{@slide.title}</h2>

      <.number_line step={@step} levels={16} values={[0.13, -0.42, 0.87, -0.05, 0.51, -0.68]} />

      <.step n={3} step={@step}>
        <p class="slide__caption">
          One scale for the block. One small integer for each weight.
        </p>
      </.step>
    </section>
    """
  end

  def slide(%{slide: %Slide{id: :the_label}} = assigns) do
    ~H"""
    <section class="slide">
      <.filename chapter={@slide.chapter} />

      <.label_anatomy
        step={@step}
        parts={[
          {"Q4", "four bits for each weight"},
          {"K", "llama.cpp's k-quant, which quantises the scales too"},
          {"M", "medium. The sensitive tensors keep more bits"}
        ]}
      />
    </section>
    """
  end

  # Four lines of C, which is a better argument than a paragraph about them.
  # The source lives in a binary rather than inline, because HEEx reads the
  # struct's own opening brace as the start of an interpolation.
  def slide(%{slide: %Slide{id: :the_real_cost}} = assigns) do
    assigns = assign(assigns, source: block_q8_0_source())

    ~H"""
    <section class="slide">
      <.filename chapter={@slide.chapter} />
      <h2 class="slide__title slide__title--small">{@slide.title}</h2>

      <pre class="raw"><code>{@source}</code></pre>

      <.step n={2} step={@step}>
        <p class="slide__caption">34 &times; 8 &divide; 32 = 8.5 bits for each weight, not 8.</p>
      </.step>
    </section>
    """
  end

  def slide(%{slide: %Slide{id: :does_it_work}} = assigns) do
    ~H"""
    <section class="slide">
      <.filename chapter={@slide.chapter} />
      <h2 class="slide__title slide__title--small">{@slide.title}</h2>

      <.accuracy_table
        step={@step}
        rows={[
          {"Qwen3-30B BF16", 61.1, 61.06},
          {"Qwen3-30B Q8_0", 32.48, 32.44},
          {"Qwen3-30B Q4_K_M", 18.56, 18.32}
        ]}
      />

      <.step n={3} step={@step}>
        <p class="slide__caption">Not overhead. The wrong constant. Use 4.8, not 4.</p>
      </.step>
    </section>
    """
  end

  ## CHAPTER 8, .gguf

  def slide(%{slide: %Slide{id: :one_file}} = assigns) do
    ~H"""
    <section class="slide">
      <.filename chapter={@slide.chapter} />
      <h2 class="slide__title slide__title--small">{@slide.title}</h2>

      <.file_box step={@step * 4} parts={["metadata", "tokenizer", "chat template", "tensors"]} />

      <.step n={2} step={@step}>
        <p class="slide__caption">The chat template from chapter five ships inside the weights.</p>
      </.step>
    </section>
    """
  end

  # No new picture. The room has been reading this string for forty minutes,
  # and drawing the line through it is the entire argument.
  def slide(%{slide: %Slide{id: :two_authors}} = assigns) do
    ~H"""
    <section class="slide slide--centred">
      <.filename chapter={@slide.chapter} authors={@step >= 2} />

      <.step n={3} step={@step}>
        <p class="slide__caption">
          Qwen released safetensors at BF16. Someone else converted it and named the rest.
        </p>
      </.step>
    </section>
    """
  end

  ## CHAPTER 9, CLOSE

  def slide(%{slide: %Slide{id: :annotated_name}} = assigns) do
    ~H"""
    <section class="slide slide--centred">
      <.annotated />
    </section>
    """
  end

  def slide(%{slide: %Slide{id: :the_board}} = assigns) do
    ~H"""
    <section class="slide">
      <.filename chapter={@slide.chapter} />
      <h2 class="slide__title slide__title--small">{@slide.title}</h2>

      <.standings standings={Room.standings()} limit={5} />
    </section>
    """
  end

  ## CHAPTER OPENERS

  # One segment, as large as it goes, under the header it belongs to. These
  # were falling through to the stub, which draws a slide's speaker notes on
  # screen, so the room was being shown an instruction meant for whoever drew
  # the slide.
  def slide(%{slide: %Slide{id: id, chapter: chapter}} = assigns)
      when not is_nil(chapter) and id in ~w(
        qwen3_chapter thirty_b_chapter a3b_chapter instruct_chapter
        date_chapter quant_chapter gguf_chapter
      )a do
    assigns = assign(assigns, segment: segment(chapter))

    ~H"""
    <section class="slide slide--centred">
      <.filename chapter={@slide.chapter} />
      <p class="slide__segment">{@segment.text}</p>
      <p class="slide__segment-label">{@segment.label}</p>
    </section>
    """
  end

  ## TERM CARDS

  def slide(%{slide: %Slide{id: id}} = assigns) when id in ~w(
        qwen3_terms thirty_b_terms a3b_terms instruct_terms quant_terms gguf_terms
      )a do
    assigns = assign(assigns, definitions: Slide.definitions(assigns.slide))

    ~H"""
    <section class="slide">
      <.filename chapter={@slide.chapter} />
      <h2 class="slide__title slide__title--small">{@slide.title}</h2>

      <dl class="terms">
        <div :for={{term, meaning} <- @definitions} class="terms__row">
          <dt class="terms__term">{term}</dt>
          <dd class="terms__meaning">{meaning}</dd>
        </div>
      </dl>
    </section>
    """
  end

  ## ROUNDS

  def slide(%{slide: %Slide{round: round}} = assigns) when not is_nil(round) do
    assigns = assign(assigns, round: Round.fetch(round))

    ~H"""
    <section class="slide slide--round">
      <.filename chapter={@slide.chapter} />

      <h2 class="slide__question">{@round.question}</h2>

      <ul :if={@round.type == :choice} class="slide__options">
        <li
          :for={option <- @round.options}
          class={[
            "slide__option",
            @room.phase == :revealed and option == @round.answer and "slide__option--answer"
          ]}
        >
          {option}
        </li>
      </ul>

      <p :if={@round.type == :numeric} class="slide__numeric">
        Type a number on your phone.
      </p>

      <p :if={@room.phase != :revealed} class="slide__count">
        {Room.answered_count(@room)} answered
      </p>

      <div :if={@room.phase == :revealed} class="deck__tally slide__tally">
        <p :for={{option, count} <- Room.tally(@room)} class="slide__tally-row">
          <span class="slide__tally-option">{option}</span>
          <span class="slide__tally-count">{count}</span>
        </p>
        <p class="slide__answer">{answer_line(@round)}</p>
      </div>
    </section>
    """
  end

  ## ANYTHING NOT YET WRITTEN

  # Hatched, so an unwritten slide announces itself from the back of the room
  # rather than crashing or, worse, looking finished.
  def slide(assigns) do
    ~H"""
    <section class="slide slide--stub">
      <.filename :if={@slide.chapter} chapter={@slide.chapter} />
      <h2 class="slide__title slide__title--small">{@slide.title}</h2>
      <p class="slide__stub-notes">{Slide.prose(@slide)}</p>
    </section>
    """
  end

  ## PRIVATE FUNCTIONS

  defp segment(chapter) do
    Enum.find(Filename.segments(), &(&1.chapter == chapter))
  end

  # Verbatim from llama.cpp, ggml/src/ggml-common.h. Quoted rather than
  # paraphrased: the point of the slide is that this is the primary source,
  # and that the eight-bit answer everyone repeats leaves out the scale.
  defp block_q8_0_source do
    [
      "#define QK8_0 32",
      "",
      "typedef struct {",
      "    ggml_half d;       // 2 bytes: the scale",
      "    int8_t  qs[QK8_0]; // 32 bytes: the weights",
      "} block_q8_0;"
    ]
    |> Enum.join("\n")
  end

  # Nil when the file is not there, so the slide can say what is missing
  # instead of drawing a broken image in front of a room.
  defp screenshot(name) do
    path = Path.join([:code.priv_dir(:model_name_talk), "static", "images", name])

    if File.exists?(path), do: "/images/#{name}", else: nil
  end

  defp answer_line(%Round{type: :choice, answer: answer}), do: "The answer: #{answer}"

  defp answer_line(%Round{type: :numeric, answer: answer, band: {low, high}}) do
    "The answer: about #{answer}. Anything from #{low} to #{high} counted."
  end
end
