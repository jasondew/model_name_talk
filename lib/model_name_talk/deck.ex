defmodule ModelNameTalk.Deck do
  @moduledoc """
  The talk, as data.

  Nothing here draws anything. A slide is a title, some notes, a count of
  reveal steps and the chapter whose segment it lights;
  `ModelNameTalkWeb.SlideComponents` matches on the id to draw it. Keeping the
  arc as a list means the running order is one readable file that can be
  diffed against the brief rather than something recovered by reading
  templates.

  The arc is one file name, read left to right. Every chapter takes one
  segment, explains it, and ends by asking the room a question about it.

  Notes use three kinds of line: `-` is a cue, `!` is a point that must be
  said out loud, and `=` is `term: what it means`. The definitions are also
  the term cards and the audience's reference sheet.
  """

  alias ModelNameTalk.{Section, Slide}

  @doc "The nine chapters, in order."
  @spec sections() :: [Section.t()]
  def sections do
    [
      %Section{
        number: 1,
        title: "Opening",
        minutes: 3,
        lands:
          "the file is a pile of numbers, and they know what they will be able to do with the name",
        slides: [
          %Slide{
            id: :title,
            title: "What's in a name?",
            notes: """
            - Say the title once, then stop
            ! By the end you can read any of these and say whether it fits on your machine
            - Point at the QR. It is on every slide, join whenever
            """
          },
          %Slide{
            id: :the_name,
            title: "One file name",
            notes: """
            ! In forty minutes you will be able to read every part of this
            - Do not explain anything yet
            - Let it sit for a beat. It should look like noise
            - This is a real file you can download today
            """
          },
          %Slide{
            id: :what_a_model_is,
            title: "What is in the file",
            steps: 2,
            notes: """
            ! That file is a pile of numbers. That is nearly all it is
            ! The weights are the numbers training moved
            ! The architecture is the small amount of structure that says how to use them
            - Our toy model was both, and you could read all of it in an afternoon
            - Everything the name tells you is a fact about those numbers
            - So the rest of the talk is reading the label on a box of numbers
            """
          }
        ]
      },
      %Section{
        number: 2,
        title: "Qwen3",
        minutes: 4,
        lands: "the lab is not the model, and open weights is not open source",
        slides: [
          %Slide{
            id: :qwen3_chapter,
            title: "Qwen3",
            chapter: 2,
            notes: """
            - Read the segment out, then pause
            - Two things in five characters: who made it, and which generation
            """
          },
          %Slide{
            id: :lab_and_model,
            title: "The lab is not the model",
            chapter: 2,
            steps: 3,
            notes: """
            ! Qwen is a team at Alibaba. Qwen3 is a generation. Qwen3-30B-A3B is one model
            - People say "Qwen" meaning all three and you have to work out which
            - Same shape everywhere: Meta ships Llama, Google ships Gemma and Gemini
            - A family shares a design and a tokenizer, not a size
            """
          },
          %Slide{
            id: :three_kinds,
            title: "Three different things people call open",
            chapter: 2,
            steps: 3,
            notes: """
            ! Open weights is not open source. This is the slide people get wrong
            - Closed: you rent it. There is no file and there never will be
            - Open weights: you get the numbers. Not the data, not the training code
            - Open source: the recipe too. Rare. OLMo from AI2, and NVIDIA's Nemotron, which ships its training data and recipes
            - Qwen3 is open weights. You can run it forever, but you could not rebuild it
            """
          },
          %Slide{
            id: :qwen3_terms,
            title: "Words so far",
            chapter: 2,
            notes: """
            = model: a set of trained numbers, plus an architecture that says how to use them
            = weights and parameters: the numbers training adjusts. The two words mean the same thing
            = family and generation: Qwen is the family, 3 is the generation
            = open weights: the vendor publishes the file. Not the same as open source
            = token: the unit the model reads and predicts, usually a piece of a word
            """
          },
          %Slide{
            id: :round_open_weights,
            title: "Which one ships you a file?",
            chapter: 2,
            round: :open_weights,
            steps: 2,
            notes: """
            - Twenty seconds. Read the options out while they answer
            - Narrate the count going up, it fills the silence
            ! The other three you can only rent
            """
          }
        ]
      },
      %Section{
        number: 3,
        title: "30B",
        minutes: 4,
        lands: "a parameter here is the same object as in the toy model, there are just more",
        slides: [
          %Slide{
            id: :thirty_b_chapter,
            title: "30B",
            chapter: 3,
            notes: """
            - B is billion. M is million. That is the whole of it
            - The easiest segment in the name, and the one people over-read
            """
          },
          %Slide{
            id: :how_big,
            title: "TinyLLM, GPT-2, this one",
            chapter: 3,
            steps: 4,
            notes: """
            - Our toy model: 15,104 parameters. Counted, not estimated
            - GPT-2 small: 124 million
            - This one: 30,532,122,624
            ! Say out loud that the scale is logarithmic, or the chart lies
            ! Same kind of number as the toy model. About two million times as many
            ! It causes memory directly. It only suggests capability
            """
          },
          %Slide{
            id: :thirty_b_terms,
            title: "Words so far",
            chapter: 3,
            notes: """
            = parameter count: how many trained numbers the model has
            """
          },
          %Slide{
            id: :round_how_many,
            title: "How many GPT-2s fit inside?",
            chapter: 3,
            round: :how_many_gpt2s,
            steps: 2,
            notes: """
            - The easy one. Let them get it fast
            - 30.5 billion over 124 million
            ! 246. The jump from M to B is the thing being tested
            """
          }
        ]
      },
      %Section{
        number: 4,
        title: "A3B",
        minutes: 6.5,
        lands: "total parameters set the memory, active parameters set the speed",
        slides: [
          %Slide{
            id: :a3b_chapter,
            title: "A3B",
            chapter: 4,
            notes: """
            ! A3B means 3 billion active parameters: the ones each token actually uses
            - Same unit as the 30B. 30B is how many it has, 3B is how many one token uses
            - This is the most useful segment in the name
            - It tells you the model is a Mixture of Experts without using the words
            """
          },
          %Slide{
            id: :dense_or_sparse,
            title: "One big block, or many small ones",
            chapter: 4,
            steps: 5,
            notes: """
            - Left: a dense layer. One feed forward block, the MLP from last time
            - Right: the same layer as a Mixture of Experts. 128 small blocks and a router
            - For each token, in each layer, the router picks 8
            - Next press: the second token picks a different 8. Then a third
            ! This is why all 30B have to be in memory: you cannot know in advance which experts the next token needs
            - Faint ones were used by earlier tokens. Expert 19 got picked twice, which happens
            - In this model all 48 layers are like this. No dense layers mixed in
            """
          },
          %Slide{
            id: :not_specialists,
            title: "They are not subject specialists",
            chapter: 4,
            notes: """
            ! There is no maths expert and no French expert
            ! Routing is learned for each token and each layer, and a person usually cannot read it
            - This is the most common wrong idea about MoE, so say it plainly
            - If somebody asks what expert 47 does, the honest answer is that nobody knows
            """
          },
          %Slide{
            id: :memory_and_speed,
            title: "Total sets memory. Active sets speed.",
            chapter: 4,
            steps: 4,
            notes: """
            - First press: the shared part. Attention, embeddings, the router. Every token uses all of it
            - Second press: the experts. 128 of them stored, only 8 used for any one token
            - Third press: add it up. 30.5B stored, 3.3B used. That 3.3B is the A3B in the name
            ! 3B is not one expert. It is 8 small experts plus the shared part every token uses
            ! Every expert has to be in memory, because the next token may want a different one
            - Fourth press: total sets memory, active sets speed. That is the whole chapter
            - If a name has no A segment, assume dense
            """
          },
          %Slide{
            id: :a3b_terms,
            title: "Words so far",
            chapter: 4,
            notes: """
            = dense model: a model that uses all of its parameters for every token
            = Mixture of Experts: a design where each layer has many small feed forward blocks and each token uses only some
            = expert: one of those feed forward blocks
            = router: the small network that picks the experts for each token
            = active parameters: the parameters one token actually uses
            """
          },
          %Slide{
            id: :round_memory_speed,
            title: "Scout: memory like what, speed like what?",
            chapter: 4,
            round: :memory_versus_speed,
            steps: 2,
            notes: """
            - This is the round that carries the chapter
            ! 109B of memory, 17B of speed
            - The two wrong answers are the two misconceptions people actually hold
            - Note Meta names the active count and Qwen names the total. Opposite conventions
            """
          }
        ]
      },
      %Section{
        number: 5,
        title: "Instruct",
        minutes: 5.5,
        lands: "what a model produces is decided after pre-training, not during it",
        slides: [
          %Slide{
            id: :instruct_chapter,
            title: "Instruct",
            chapter: 5,
            notes: """
            - This one is about what was done to the model after it learned to read
            - And therefore about what comes out when you talk to it
            """
          },
          %Slide{
            id: :the_pipeline,
            title: "Corpus, base, then this",
            chapter: 5,
            steps: 5,
            notes: """
            - Pre-training is next token prediction over an enormous pile of text
            - The toy model did exactly this, on five sentences
            - What falls out is a base model. It continues text
            - Post-training is more training that makes it follow instructions. One sentence is enough
            """
          },
          %Slide{
            id: :kinds_of_model,
            title: "What each one gives you back",
            chapter: 5,
            steps: 3,
            notes: """
            ! Every one of these started as the same base model
            - Base continues your text. Instruct answers you
            - Thinking writes its reasoning first, then answers. Slower, more tokens, better on hard problems
            - Embedding is the odd one: it gives you a vector, not words
            - it is Gemma's word for instruct, and Chat is the older word
            """
          },
          %Slide{
            id: :base_continues,
            title: "One question, four kinds of model",
            chapter: 5,
            steps: 5,
            notes: """
            - First press: the question. Every model on this slide started as the same base model
            ! Base: it continues the document. A page of questions is a likely document, so it writes more questions
            - It is not being unhelpful. It is doing its job exactly
            - Instruct: post-training taught it that a question wants an answer
            - Thinking: it writes its reasoning between think tags first, then answers. Slower, better on hard problems
            - Embedding: no words at all. A list of numbers that places the question near others that mean the same thing
            - These replies are illustrative, written to show the shape of each. They are not captured output
            """
          },
          %Slide{
            id: :chat_template,
            title: "The model only ever sees one string",
            chapter: 5,
            steps: 3,
            notes: """
            ! There is no such thing as a message as far as the model is concerned
            ! A chat template is text with special tokens around it, and nothing more
            - First press: this is everything you send. It stops at the assistant's turn
            - Second press: the model writes the rest, and ends it with <|im_end|> itself
            - Third press: the special tokens light up. Each is one token, ids 151644 and 151645
            - This comes back in chapter 8, because the template ships inside the file
            """
          },
          %Slide{
            id: :instruct_terms,
            title: "Words so far",
            chapter: 5,
            notes: """
            = pre-training: training to predict the next token over a very large corpus
            = base model: what pre-training produces. It continues text
            = post-training: further training that makes a model follow instructions
            = Instruct and Thinking: post-trained variants. One answers, the other reasons first
            = chat template: the text format, with special tokens, that flattens a conversation into one sequence
            """
          },
          %Slide{
            id: :round_base_completion,
            title: "What comes back from a base model?",
            chapter: 5,
            round: :base_completion,
            steps: 2,
            notes: """
            - They have just heard why, so this should land
            ! The one that answers politely is the trap
            - A base model does not refuse and does not apologise. It continues
            """
          }
        ]
      },
      %Section{
        number: 6,
        title: "2507",
        minutes: 1.5,
        lands: "pin the version the way you pin a dependency",
        slides: [
          %Slide{
            id: :date_chapter,
            title: "2507",
            chapter: 6,
            notes: """
            - Year and month. July 2025
            - Quickest chapter in the talk. Do not linger
            """
          },
          %Slide{
            id: :same_name_different_model,
            title: "The name stayed. The model did not.",
            chapter: 6,
            steps: 2,
            notes: """
            - April 2025: one Qwen3-30B-A3B, with a switch between thinking and not
            - July 2025: that became two separate models, and the context went from 32K to 262,144
            ! Pin the model version like you pin a dependency
            ! The date stamp is not the knowledge cutoff. Different thing entirely
            """
          }
        ]
      },
      %Section{
        number: 7,
        title: "Q4_K_M",
        minutes: 12,
        lands:
          "quantization is why the model fits at all, and the formula works once you use the right bits",
        slides: [
          %Slide{
            id: :quant_chapter,
            title: "Q4_K_M",
            chapter: 7,
            notes: """
            - The technical centre of the talk. Slow down here
            - Twelve minutes. If you are behind, take it from chapter 8, not from this
            """
          },
          %Slide{
            id: :why_quantize,
            title: "61 GB, and a 12 GB GPU",
            chapter: 7,
            steps: 4,
            notes: """
            ! This is why quantization exists. Not to be clever, to make it fit
            - First press: the model as Qwen released it, BF16, 2 bytes each: 61 GB. The line is my GPU, an RTX 3060, 12 GB
            - Then the same model saved smaller: Q8_0, then Q4_K_M, the usual choice
            - Last press: Q2_K, 11.3 GB, finally inside the line
            - It fits only just. The context needs memory too, and 2 bits is a big quality hit. More on both shortly
            - Every bar is a real file on Hugging Face
            """
          },
          %Slide{
            id: :precision,
            title: "Bits for each weight",
            chapter: 7,
            steps: 5,
            notes: """
            - Each bar is the bits themselves, as wide as the format has bits
            - A float spends its bits three ways: a sign, an exponent for how big, a mantissa for how many digits
            - FP32: 8 bits of exponent, 23 of mantissa. Huge range, about 7 digits. 0.1 comes back as 0.10000000149
            - FP16: half the bits, but it takes them out of both. Only reaches 65,504, about 3 digits
            ! BF16 keeps FP32's exponent and throws away mantissa. Same range, only 2 or 3 digits
            - That is the right trade for weights: range matters, the third digit barely does. It is what Qwen ships
            ! Vendors release at 16 bits. That is why it is 61 GB and not 122
            - INT8 and INT4 are not floats at all: just a whole number. On their own they cannot say 0.1
            - They need a scale from outside to mean anything, and that is the next few slides
            """
          },
          %Slide{
            id: :the_formula,
            title: "parameters x bits",
            chapter: 7,
            steps: 3,
            notes: """
            ! If they remember one thing from this talk, this is it
            - Say it once, slowly, and let it sit
            - Second press: use it on the file in the title. 30.5 billion parameters, Q4_K_M is about 4.8 bits each
            - Third press: 146.6 billion bits, divide by 8 for bytes, 18.3 GB
            - The real file is 18.56 GB. We come back to how close that is
            """
          },
          %Slide{
            id: :the_method,
            title: "A scale, and sixteen levels",
            chapter: 7,
            steps: 3,
            notes: """
            - Cut the weights into small blocks, 32 of them at a time
            - Store one scale for the block, then a small integer for each weight
            - Four bits gives you sixteen levels to land on. That is the whole trick
            - Walk the worked example. Multiply the integer by the scale to read a weight back
            """
          },
          %Slide{
            id: :why_blocks,
            title: "One huge weight would ruin a whole tensor",
            chapter: 7,
            steps: 2,
            notes: """
            ! The scale has to fit the biggest weight in its group
            - Four bits is 16 levels. The scale stretches them from the most negative weight to the most positive
            - First press: one scale for everything. One 12.0 stretches the levels so wide that every ordinary weight rounds to 0
            - Second press: give them their own block and they keep their values
            ! An outlier in a block of 32 spoils 32 numbers, not 30 billion. That is the whole reason blocks exist
            - The numbers are illustrative: symmetric 4 bit, scale is the largest value over 7
            """
          },
          %Slide{
            id: :the_label,
            title: "Q4, K, M",
            chapter: 7,
            steps: 4,
            notes: """
            - Q4: four bits for each weight
            - K: llama.cpp's k-quant, which also quantises the scales
            - M: medium. S, M and L exist. The sensitive tensors keep more bits
            - So the label is three separate decisions stuck together
            """
          },
          %Slide{
            id: :the_real_cost,
            title: "34 bytes for 32 weights",
            chapter: 7,
            steps: 2,
            notes: """
            ! Q8_0 is not 8 bits for each weight. It is 8.5
            ! Every block of 32 carries a 2 byte scale, and that scale is not free
            - Four lines of C from ggml-common.h. This is the primary source
            - 34 times 8 over 32 is 8.5. Do the arithmetic on the slide
            - This is exactly why the naive formula comes out low
            """
          },
          %Slide{
            id: :comparing_types,
            title: "What the labels actually cost",
            chapter: 7,
            steps: 5,
            notes: """
            - Same model, same 30.5 billion parameters, four real files
            - BF16 is what Qwen released. Everything below it is somebody else's conversion
            ! Q4_K_M is the usual deal and it is under a third the size
            - Q2_K does fit the 12 GB GPU, and you would not enjoy it
            - The bar is bits for each weight, the number beside it is the file on disk
            """
          },
          %Slide{
            id: :does_it_work,
            title: "The formula against real files",
            chapter: 7,
            steps: 3,
            notes: """
            ! Run the formula, check it against the real file on Hugging Face. Within about 1% every time
            - Read the bits column first, then the formula, then the real file
            - 16 and 8.5 are known in advance: one is the format, the other is the llama.cpp struct
            ! For Q4_K_M, assume about 4.8 bits, not 4. It mixes formats, so that number comes from measuring real files
            - The file is always a little bigger: it also holds metadata, the tokenizer and the chat template
            """
          },
          %Slide{
            id: :quality_and_speed,
            title: "Our model, quantized",
            chapter: 7,
            steps: 5,
            notes: """
            - This is the toy model from last time, really quantized and really measured. Not a mock up
            - Blocks of 32, a scale and a minimum each, the same idea llama.cpp uses
            - Same seed every row, so the only thing that changes is the bits
            ! Down to 4 bits it writes the exact same sentence
            - At 3 it starts to drift: hungry where it said small
            ! At 2 it falls apart: "a goose who who is small ignores the hungry"
            - The percentage is how many of 500 sentences were grammatical. 8 bits beating full precision is noise
            - Caveat: 15 thousand parameters. Big models degrade differently, but the rule of thumb has the same shape
            - Smaller is also faster. Generating is limited by moving weights from memory, and there are fewer bytes to move
            """
          },
          %Slide{
            id: :not_just_weights,
            title: "The weights are not the whole bill",
            chapter: 7,
            notes: """
            - The KV cache stores keys and values for every previous token so they are not recomputed
            - It grows with the context length
            - One sentence only. This is a whole talk on its own and not this one
            """
          },
          %Slide{
            id: :quant_terms,
            title: "Words so far",
            chapter: 7,
            notes: """
            = precision: how many bits store each weight
            = quantization: converting weights to lower precision after training
            = block and scale: a small group of weights, and the number that converts their integers back
            = context window: the most tokens the model can use at once. 262,144 for this one
            = KV cache: stored keys and values for previous tokens. Grows with context length
            """
          },
          %Slide{
            id: :round_gigabytes,
            title: "How many gigabytes?",
            chapter: 7,
            round: :how_many_gigabytes,
            steps: 2,
            notes: """
            ! Say out loud that this is the no rush round. No speed bonus on this one
            - Forty five seconds. Let them actually do the arithmetic
            - 70 times 8.5 bits is 595 billion bits, over 8 is about 75 GB. The real file is 74.98
            - Anything from 68 to 80 counts, including 70 if they used 8 bits flat
            """
          }
        ]
      },
      %Section{
        number: 8,
        title: ".gguf",
        minutes: 3.5,
        lands: "the format says which program runs it, and the name has two authors",
        slides: [
          %Slide{
            id: :gguf_chapter,
            title: ".gguf",
            chapter: 8,
            notes: """
            - The last segment, and the easiest
            - GGUF is the single file format of the llama.cpp project
            """
          },
          %Slide{
            id: :one_file,
            title: "Metadata, tokenizer, chat template, tensors",
            chapter: 8,
            steps: 2,
            notes: """
            - One file holds all four. That is the point of the format
            - The chat template from chapter 5 is in there, shipped with the weights
            - So the file knows how to be talked to, not just what the numbers are
            """
          },
          %Slide{
            id: :which_program,
            title: "Which program can open it",
            chapter: 8,
            notes: """
            - GGUF: llama.cpp, Ollama, LM Studio
            - safetensors: Hugging Face Transformers, vLLM
            - MLX: Apple silicon
            - An inference engine is just the program that loads the weights and does the maths
            """
          },
          %Slide{
            id: :two_authors,
            title: "This name has two authors",
            chapter: 8,
            steps: 3,
            notes: """
            ! Qwen wrote everything up to the date stamp
            ! Somebody in the community converted it and wrote the rest
            - The usual path: vendor releases safetensors at BF16, a person converts and quantises to GGUF
            - Show it on the header they have been reading for forty minutes
            - Ollama tags like qwen3:30b hide the quantisation. Usually Q4_K_M
            """
          },
          %Slide{
            id: :gguf_terms,
            title: "Words so far",
            chapter: 8,
            notes: """
            = inference engine: the program that loads the weights and runs the model
            = GGUF: the single file model format of llama.cpp
            = safetensors: the Hugging Face format, what vendors usually release first
            """
          },
          %Slide{
            id: :round_does_it_fit,
            title: "Does it fit?",
            chapter: 8,
            round: :does_it_fit,
            steps: 2,
            notes: """
            - 18.6 GB of model, a 12 GB GPU, 16 GB of system RAM
            ! Offload is the answer, and it is a good answer for an MoE
            - Each token only uses 3B of the parameters, so little has to cross from system RAM
            - Mention the other options exist: smaller quant, smaller model
            """
          }
        ]
      },
      %Section{
        number: 9,
        title: "Close",
        minutes: 2,
        lands: "they can read the name, and the board says who read it best",
        slides: [
          %Slide{
            id: :annotated_name,
            title: "All of it",
            chapter: 9,
            notes: """
            ! This is the slide to photograph. Say so
            - Leave it up while you talk. Do not move on quickly
            - Every segment with its label underneath
            - Read it left to right once, out loud, at normal speed
            """
          },
          %Slide{
            id: :whats_next,
            title: "Next: from the file to the agent",
            chapter: 9,
            notes: """
            - One line. Do not start the next talk here
            - Cut this slide entirely if you are over time
            - Then take questions
            """
          }
        ]
      }
    ]
  end

  @doc "Every slide, flattened, numbered, and told which section it belongs to."
  @spec slides() :: [Slide.t()]
  def slides do
    sections()
    |> Enum.flat_map(fn section ->
      Enum.map(section.slides, &%{&1 | section: section.number})
    end)
    |> Enum.with_index(1)
    |> Enum.map(fn {slide, index} -> %{slide | index: index} end)
  end

  @doc "The slide at an index, clamped to the deck."
  @spec at(integer()) :: Slide.t()
  def at(index), do: Enum.at(slides(), clamp(index))

  @doc "How many slides there are."
  @spec length() :: pos_integer()
  def length, do: Kernel.length(slides())

  @doc "An index brought back inside the deck."
  @spec clamp(integer()) :: non_neg_integer()
  def clamp(index), do: index |> max(0) |> min(__MODULE__.length() - 1)

  @doc "The section a slide belongs to."
  @spec section(Slide.t()) :: Section.t()
  def section(%Slide{section: number}), do: Enum.find(sections(), &(&1.number == number))

  @doc "Minutes the talk should have spent before this section starts."
  @spec minutes_before(Section.t()) :: number()
  def minutes_before(%Section{number: number}) do
    sections() |> Enum.filter(&(&1.number < number)) |> Enum.map(& &1.minutes) |> Enum.sum()
  end
end
