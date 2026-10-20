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

  import ModelNameTalkWeb.FigureComponents
  import ModelNameTalkWeb.FilenameComponents

  alias ModelNameTalk.{Filename, Round, Slide}

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
        <.expert_grid
          experts={128}
          step={@step}
          tokens={[
            [6, 19, 31, 44, 68, 83, 101, 119],
            [3, 27, 40, 57, 72, 90, 108, 125],
            [11, 19, 35, 61, 77, 94, 113, 122]
          ]}
        />
      </div>
    </section>
    """
  end

  # Two lines, and the largest type in the deck. This is the chapter, and
  # everything before it exists to make these two lines mean something.
  # The accounting, a row a press, then the two lines it adds up to. Numbers
  # are computed from the model's config.json and land on the published
  # 30.5B and 3.3B; the working is in docs/verify.md.
  def slide(%{slide: %Slide{id: :memory_and_speed}} = assigns) do
    ~H"""
    <section class="slide">
      <.filename chapter={@slide.chapter} />
      <h2 class="slide__title slide__title--small">{@slide.title}</h2>

      <.comparison
        step={@step}
        lit="total"
        headers={["", "stored", "used for each token"]}
        rows={[
          ["shared: attention, embeddings, router", "1.5B", "1.5B"],
          ["experts, about 0.23B each", "128 of them: 29.0B", "8 of them: 1.8B"],
          ["total", "30.5B", "3.3B"]
        ]}
      />

      <.step n={4} step={@step}>
        <p class="slide__equation">
          <span class="slide__equation-from">30.5B stored</span>
          <span class="slide__equation-arrow">&rarr;</span>
          <span class="slide__equation-to">memory</span>
        </p>
        <p class="slide__equation">
          <span class="slide__equation-from">3.3B used</span>
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

      <%!-- One stage a press, starting from the text alone. --%>
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

      <%!-- What you send, then what the model writes back, then the special
           tokens light up. --%>
      <.raw_text step={if @step >= 3, do: 2, else: 1} text={chat_template_text(@step)} />

      <.step n={3} step={@step}>
        <p class="slide__caption">The lit parts are just tokens. The model cannot see a message.</p>
      </.step>
    </section>
    """
  end

  # One question and what each kind of model sends back. The replies are
  # illustrative and the notes say so; the question differs from the round
  # that follows so that slide does not give the round away.
  def slide(%{slide: %Slide{id: :base_continues}} = assigns) do
    ~H"""
    <section class="slide">
      <.filename chapter={@slide.chapter} />
      <h2 class="slide__title slide__title--small">{@slide.title}</h2>

      <p class="slide__prompt">How do I make a cup of tea?</p>

      <.comparison
        step={@step - 1}
        variant="sentences"
        lit="Instruct"
        headers={["", "what comes back"]}
        rows={[
          ["Base", "How do I make a cup of coffee? How do I boil an egg? How do I"],
          ["Instruct", "Boil water, steep a tea bag for 3 to 5 minutes, add milk if you like."],
          [
            "Thinking",
            "<think>Simple steps: water, bag, time. Milk is optional.</think> Boil water, steep a tea bag for 3 to 5 minutes, add milk to taste."
          ],
          ["Embedding", "[0.018, -0.097, 0.231, 0.004, ...]"]
        ]}
      />
    </section>
    """
  end

  ## CHAPTER 7, Q4_K_M

  # The formula, then the formula used: Q4_K_M, the file in the title.
  def slide(%{slide: %Slide{id: :the_formula}} = assigns) do
    ~H"""
    <section class="slide slide--centred">
      <.filename chapter={@slide.chapter} />
      <p class="slide__formula">parameters &times; bits to store each parameter</p>
      <p :if={@step == 1} class="slide__caption">That is bits. Divide by 8 for bytes.</p>

      <.step n={2} step={@step}>
        <p class="slide__working">30.5 billion &times; 4.8 bits</p>
      </.step>

      <.step n={3} step={@step}>
        <p class="slide__working">
          = 146.6 billion bits &divide; 8 = <span class="slide__working-answer">18.3 GB</span>
        </p>
      </.step>
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

  # The outlier example, worked rather than asserted. Four bits, a scale sized
  # to the largest weight in the group, values checked by hand: one 12.0 in
  # the group and every ordinary weight rounds to nothing.
  def slide(%{slide: %Slide{id: :why_blocks}} = assigns) do
    ~H"""
    <section class="slide">
      <.filename chapter={@slide.chapter} />
      <h2 class="slide__title slide__title--small">{@slide.title}</h2>

      <.comparison
        step={@step}
        lit="its own block of 32"
        variant="values"
        headers={["the weights", "0.13", "−0.42", "0.87", "−0.05", "12.0"]}
        rows={[
          ["one scale for everything", "0", "0", "1.71", "0", "12.0"],
          ["its own block of 32", "0.12", "−0.37", "0.87", "0", ""]
        ]}
      />

      <.step n={2} step={@step}>
        <p class="slide__caption">Small blocks keep the damage local.</p>
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
          {"Qwen3-30B BF16", "16", 61.1, 61.06},
          {"Qwen3-30B Q8_0", "8.5", 32.48, 32.44},
          {"Qwen3-30B Q4_K_M", "about 4.8", 18.56, 18.32}
        ]}
      />

      <.step n={3} step={@step}>
        <p class="slide__caption">
          Use the real bits for each weight and it lands within about 1%. For Q4_K_M that is about 4.8, not 4.
        </p>
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

  ## CHAPTER 2, Qwen3

  # Two words, arriving. The explanation is worth more said than read, so it
  # lives in the notes and the slide stays out of the way.
  def slide(%{slide: %Slide{id: :what_a_model_is}} = assigns) do
    ~H"""
    <section class="slide slide--centred">
      <.filename chapter={@slide.chapter} />

      <p class="slide__word">weights</p>

      <.step n={2} step={@step}>
        <p class="slide__word slide__word--second">architecture</p>
      </.step>
    </section>
    """
  end

  def slide(%{slide: %Slide{id: :lab_and_model}} = assigns) do
    ~H"""
    <section class="slide">
      <.filename chapter={@slide.chapter} />
      <h2 class="slide__title slide__title--small">{@slide.title}</h2>

      <.comparison
        step={@step}
        lit="Alibaba"
        headers={["the lab", "the family", "one model"]}
        rows={[
          ["Alibaba", "Qwen3", "Qwen3-30B-A3B"],
          ["Meta", "Llama", "Llama-3.3-70B"],
          ["Google", "Gemma, and Gemini", "Gemma-3-27B"]
        ]}
      />
    </section>
    """
  end

  def slide(%{slide: %Slide{id: :three_kinds}} = assigns) do
    ~H"""
    <section class="slide">
      <.filename chapter={@slide.chapter} />
      <h2 class="slide__title slide__title--small">{@slide.title}</h2>

      <.comparison
        step={@step}
        lit="open weights"
        headers={["", "what you get", "can you run it", "for example"]}
        rows={[
          ["closed", "an endpoint", "no, you rent it", "Claude, GPT"],
          ["open weights", "the numbers", "yes, forever", "Qwen3, Llama"],
          ["open source", "numbers, data, code", "yes, and rebuild it", "OLMo, Nemotron"]
        ]}
      />
    </section>
    """
  end

  ## CHAPTER 5, the kinds of model

  def slide(%{slide: %Slide{id: :kinds_of_model}} = assigns) do
    ~H"""
    <section class="slide">
      <.filename chapter={@slide.chapter} />
      <h2 class="slide__title slide__title--small">{@slide.title}</h2>

      <%!-- Base and Instruct arrive together, then one row a press. --%>
      <.comparison
        step={@step + 1}
        lit="Instruct"
        headers={["in the name", "what comes back"]}
        rows={[
          ["Base", "more text, continuing yours"],
          ["Instruct, it, Chat", "an answer"],
          ["Thinking", "reasoning first, then an answer"],
          ["Embedding", "a vector, not words at all"]
        ]}
      />
    </section>
    """
  end

  ## CHAPTER 7, what the labels cost

  # The same model saved smaller and smaller against a GPU that does not
  # move. Every size is a real file from docs/verify.md.
  def slide(%{slide: %Slide{id: :why_quantize}} = assigns) do
    ~H"""
    <section class="slide">
      <.filename chapter={@slide.chapter} />
      <h2 class="slide__title slide__title--small">{@slide.title}</h2>

      <.fit_chart
        step={@step}
        limit={12.0}
        limit_label="the GPU: 12 GB"
        rows={[{"BF16", 61.1}, {"Q8_0", 32.48}, {"Q4_K_M", 18.56}, {"Q2_K", 11.26}]}
      />

      <.step n={4} step={@step}>
        <p class="slide__caption">Quantization is that gap, and nothing else.</p>
      </.step>
    </section>
    """
  end

  def slide(%{slide: %Slide{id: :comparing_types}} = assigns) do
    ~H"""
    <section class="slide">
      <.filename chapter={@slide.chapter} />
      <h2 class="slide__title slide__title--small">{@slide.title}</h2>

      <.format_comparison
        step={@step}
        formats={[
          {"BF16", 16.0, 61.1},
          {"Q8_0", 8.51, 32.48},
          {"Q4_K_M", 4.86, 18.56},
          {"Q2_K", 2.95, 11.26}
        ]}
      />

      <.step n={5} step={@step}>
        <p class="slide__caption">One model. Same 30.5 billion parameters every time.</p>
      </.step>
    </section>
    """
  end

  ## QUANTIZATION, MEASURED

  # Real output from the toy model, quantized and generated from a fixed seed.
  # docs/experiments/quantise_toy.exs reproduces every number here.
  def slide(%{slide: %Slide{id: :quality_and_speed}} = assigns) do
    ~H"""
    <section class="slide">
      <.filename chapter={@slide.chapter} />
      <h2 class="slide__title slide__title--small">{@slide.title}</h2>

      <.comparison
        step={@step}
        variant="sentences"
        headers={["", "grammatical", "one sentence it wrote, same seed"]}
        rows={[
          ["full precision", "91%", "the small grumpy llamas are hungry ."],
          ["8 bits", "92%", "the small grumpy llamas are hungry ."],
          ["4 bits", "91%", "the small grumpy llamas are hungry ."],
          ["3 bits", "88%", "the hungry grumpy llamas are hungry ."],
          ["2 bits", "75%", "a goose who who is small ignores the hungry ."]
        ]}
      />

      <.step n={5} step={@step}>
        <p class="slide__caption">Fine to 4 bits. Drifting at 3. Broken at 2.</p>
      </.step>
    </section>
    """
  end

  ## TABLES THE ROOM SHOULD SEE

  # What each number format is, bit by bit. The ranges and the values 0.1
  # turns into were computed, not looked up; see docs/verify.md.
  def slide(%{slide: %Slide{id: :precision}} = assigns) do
    ~H"""
    <section class="slide">
      <.filename chapter={@slide.chapter} />
      <h2 class="slide__title slide__title--small">{@slide.title}</h2>

      <.bit_layout
        step={@step}
        lit="BF16"
        rows={[
          {"FP32", [sign: 1, exponent: 8, mantissa: 23], "±3.4 × 10³⁸", "0.10000000149"},
          {"FP16", [sign: 1, exponent: 5, mantissa: 10], "±65,504", "0.09998"},
          {"BF16", [sign: 1, exponent: 8, mantissa: 7], "±3.4 × 10³⁸", "0.1001"},
          {"INT8", [integer: 8], "−128 to 127", "a whole number, and a scale"},
          {"INT4", [integer: 4], "−8 to 7", "a whole number, and a scale"}
        ]}
      />
    </section>
    """
  end

  def slide(%{slide: %Slide{id: :which_program}} = assigns) do
    ~H"""
    <section class="slide">
      <.filename chapter={@slide.chapter} />
      <h2 class="slide__title slide__title--small">{@slide.title}</h2>

      <.comparison
        step={3}
        lit="GGUF"
        headers={["format", "read by"]}
        rows={[
          ["GGUF", "llama.cpp, Ollama, LM Studio"],
          ["safetensors", "Hugging Face Transformers, vLLM"],
          ["MLX", "MLX on Apple silicon"]
        ]}
      />
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

  # A question asked out loud. The room answers by voice or in the chat, and
  # the second press shows the answer.
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
            @step >= 2 and option == @round.answer and "slide__option--answer"
          ]}
        >
          {option}
        </li>
      </ul>

      <p :if={@step >= 2} class="slide__answer">{answer_line(@round)}</p>
    </section>
    """
  end

  ## EVERYTHING ELSE

  # A slide with no drawing of its own is its title, under the header, and
  # the speaker says the rest. It used to render hatched with its notes on
  # screen, which was useful while the deck was being written and is wrong in
  # front of a room.
  def slide(assigns) do
    ~H"""
    <section class="slide slide--centred">
      <.filename :if={@slide.chapter} chapter={@slide.chapter} />
      <h2 class="slide__title">{@slide.title}</h2>
    </section>
    """
  end

  ## PRIVATE FUNCTIONS

  # A function rather than an inline attribute: mix format rewrites a string
  # in braces into a plain HTML attribute, where a backslash n is two literal
  # characters, and the slide then showed one long line with "\n" printed in it.
  # Verbatim from the chat template in Qwen3-30B-A3B-Instruct-2507's
  # tokenizer_config.json: a line break after the role and after each
  # <|im_end|>, no default system message, no think tags. The reply itself is
  # illustrative. Kept in a function because mix format rewrites a braced
  # string into a plain HTML attribute, where a backslash n stops being a
  # line break.
  defp chat_template_text(step) when step < 2 do
    """
    <|im_start|>user
    What is the capital of France?<|im_end|>
    <|im_start|>assistant\
    """
  end

  defp chat_template_text(_step) do
    """
    <|im_start|>user
    What is the capital of France?<|im_end|>
    <|im_start|>assistant
    The capital of France is Paris.<|im_end|>\
    """
  end

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

  defp answer_line(%Round{type: :choice, answer: answer}), do: "The answer: #{answer}"

  defp answer_line(%Round{type: :numeric, answer: answer, band: {low, high}}) do
    "The answer: about #{answer}. Anything from #{low} to #{high} counted."
  end
end
