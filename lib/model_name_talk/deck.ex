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
        minutes: 2,
        lands: "they know what they will be able to do in forty minutes",
        slides: [
          %Slide{
            id: :title,
            title: "How to Read a Model Name",
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
          }
        ]
      },
      %Section{
        number: 2,
        title: "Qwen3",
        minutes: 4.75,
        lands: "a model is a file of numbers plus a shape, and some vendors give you the file",
        slides: [
          %Slide{
            id: :qwen3_chapter,
            title: "Qwen3",
            chapter: 2,
            notes: """
            - Chapter title, segment very large
            - Qwen is the family, from the Qwen team at Alibaba. 3 is the generation
            - One family has many sizes sharing a design and a tokenizer
            """
          },
          %Slide{
            id: :what_a_model_is,
            title: "Numbers, plus a shape",
            chapter: 2,
            steps: 2,
            notes: """
            ! The weights are the numbers training moved
            ! The architecture is the program that knows what to do with them
            - Our toy model was both, and you could read all of it
            - A checkpoint is just a saved copy of the numbers at one moment
            """
          },
          %Slide{
            id: :open_or_closed,
            title: "A file, or an endpoint",
            chapter: 2,
            steps: 2,
            notes: """
            - Qwen ships you the weights. You can hold the file
            - Claude and GPT you reach through an API. There is no file
            ! Open weights is not open source
            ! The training data and the training code are almost never published
            """
          },
          %Slide{
            id: :tokens_again,
            title: "A token is not a word",
            chapter: 2,
            notes: """
            - Quick reminder, we did this properly last time
            - In the toy model one word was one token, because we chose 32 words
            - Real models use pieces of words
            - Qwen3's vocabulary is 151,936 tokens
            """
          },
          %Slide{
            id: :qwen3_terms,
            title: "Words so far",
            chapter: 2,
            notes: """
            = model: a set of trained numbers, plus an architecture that says how to use them
            = weights and parameters: the numbers training adjusts. The two words mean the same thing
            = checkpoint: a saved copy of the weights at one point in time
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
        minutes: 5.75,
        lands: "a parameter here is the same object as in the toy model, there are just more",
        slides: [
          %Slide{
            id: :thirty_b_chapter,
            title: "30B",
            chapter: 3,
            notes: """
            - Chapter title
            - B is billion. M is million. That is the whole of it
            """
          },
          %Slide{
            id: :how_big,
            title: "Ours, GPT-2, this one",
            chapter: 3,
            steps: 3,
            notes: """
            - Our toy model: 15,104 parameters. Counted, not estimated
            - GPT-2 small: 124 million
            - This one: 30,532,122,624
            ! Say out loud that the scale is logarithmic, or the chart lies
            ! Same kind of number as the toy model. About two million times as many
            """
          },
          %Slide{
            id: :what_it_buys,
            title: "Memory for certain, capability maybe",
            chapter: 3,
            steps: 2,
            notes: """
            ! Parameter count causes memory and cost directly. That is arithmetic
            ! It only suggests capability. That is a trend, not a promise
            - Closed vendors often do not publish a count at all
            - Which tells you the number is marketing as much as engineering
            """
          },
          %Slide{
            id: :thirty_b_terms,
            title: "Words so far",
            chapter: 3,
            notes: """
            = parameter count: how many trained numbers the model has
            = dense model: a model that uses all of its parameters for every token
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
        minutes: 6.75,
        lands: "total parameters set the memory, active parameters set the speed",
        slides: [
          %Slide{
            id: :a3b_chapter,
            title: "A3B",
            chapter: 4,
            notes: """
            - Chapter title
            - A is for active. This segment is the most useful one in the name
            - It tells you the model is a Mixture of Experts without saying so
            """
          },
          %Slide{
            id: :dense_or_sparse,
            title: "One big block, or many small ones",
            chapter: 4,
            steps: 3,
            notes: """
            - Left: a dense layer. One feed forward block, the MLP from last time
            - Right: the same layer as a Mixture of Experts. 128 small blocks and a router
            - For each token, in each layer, the router picks 8
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
            - No figure here on purpose. Drawing a thing to say it does not exist works against you
            """
          },
          %Slide{
            id: :memory_and_speed,
            title: "Total sets memory. Active sets speed.",
            chapter: 4,
            steps: 2,
            notes: """
            ! Every expert has to be in memory, because the next token may want a different one
            ! But only about 3B of arithmetic happens for each token
            - So it costs a 30B model to hold and runs near the speed of a 3B one
            - Attention is not split. Every token uses all of it
            - If a name has no A segment, assume dense
            """
          },
          %Slide{
            id: :a3b_terms,
            title: "Words so far",
            chapter: 4,
            notes: """
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
        minutes: 5.75,
        lands: "a base model continues text, and post-training is what makes it answer",
        slides: [
          %Slide{
            id: :instruct_chapter,
            title: "Instruct",
            chapter: 5,
            notes: """
            - Chapter title
            - This segment is about what was done to the model after it learned to read
            """
          },
          %Slide{
            id: :the_pipeline,
            title: "Corpus, base, then this",
            chapter: 5,
            steps: 3,
            notes: """
            - Pre-training is next token prediction over an enormous pile of text
            - The toy model did exactly this, on five sentences
            - What falls out is a base model. It continues text
            - Post-training is more training that makes it follow instructions. One sentence is enough
            """
          },
          %Slide{
            id: :base_continues,
            title: "A base model continues the document",
            chapter: 5,
            steps: 2,
            notes: """
            ! Ask a base model a question and it may answer with more questions
            ! It is not being unhelpful. It is doing its job exactly
            - It has seen a lot of documents that are lists of questions
            - Next slide is the demo
            """
          },
          %Slide{
            id: :demo_base_instruct,
            title: "DEMO",
            chapter: 5,
            notes: """
            - Same prompt to Qwen3-4B-Base and Qwen3-4B-Instruct-2507
            - Base continues, Instruct answers
            - Keep it short. Two outputs, then move
            - If it will not run, next slide has the screenshot
            """
          },
          %Slide{
            id: :demo_base_instruct_fallback,
            title: "If the demo will not run",
            chapter: 5,
            notes: """
            - The screenshot, taken during rehearsal
            - Say the same two sentences you would have said live
            """
          },
          %Slide{
            id: :chat_template,
            title: "The model only ever sees one string",
            chapter: 5,
            steps: 2,
            notes: """
            ! There is no such thing as a message as far as the model is concerned
            ! A chat template is text with special tokens around it, and nothing more
            - Step two lights the special tokens
            - This comes back in chapter 8, because the template ships inside the file
            """
          },
          %Slide{
            id: :other_words,
            title: "Base, Chat, it, Coder, VL, Distill",
            chapter: 5,
            notes: """
            - Names only, two or three words each
            - it is Gemma's word for instruction tuned
            - VL means it takes images. Distill means trained to copy a bigger model
            - Do not linger, this is a lookup table not a chapter
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
            - They have just seen the demo, so this should land
            ! The one that answers politely is the trap
            - A base model does not refuse and does not apologise. It continues
            """
          }
        ]
      },
      %Section{
        number: 6,
        title: "2507",
        minutes: 2,
        lands: "pin the version the way you pin a dependency",
        slides: [
          %Slide{
            id: :date_chapter,
            title: "2507",
            chapter: 6,
            notes: """
            - Chapter title. Year and month: July 2025
            - Cheapest segment in the name and the one that bites hardest
            """
          },
          %Slide{
            id: :same_name_different_model,
            title: "The name stayed. The model did not.",
            chapter: 6,
            steps: 3,
            notes: """
            - April 2025: one Qwen3-30B-A3B, with a switch between thinking and not
            - July 2025: that became two separate models, Instruct-2507 and Thinking-2507
            - Context went from 32K to 262,144, and natively rather than by extension
            ! Pin the model version like you pin a dependency
            ! The date stamp is not the knowledge cutoff. Different thing entirely
            """
          }
        ]
      },
      %Section{
        number: 7,
        title: "Q4_K_M",
        minutes: 9,
        lands: "the formula works, once you put the right number of bits into it",
        slides: [
          %Slide{
            id: :quant_chapter,
            title: "Q4_K_M",
            chapter: 7,
            notes: """
            - Chapter title. This is the technical centre of the talk
            - Nine minutes. If you are behind, this is not the chapter to rush
            """
          },
          %Slide{
            id: :precision,
            title: "Bits for each weight",
            chapter: 7,
            steps: 2,
            notes: """
            - FP32 is four bytes, BF16 two, INT8 one, four bit is half a byte
            - Vendors almost always release at 16 bits
            - Everything in this chapter is about spending fewer bits on each number
            """
          },
          %Slide{
            id: :the_formula,
            title: "parameters x bits / 8",
            chapter: 7,
            notes: """
            ! If they remember one thing from this talk, this is it
            - Parameters in billions, answer in gigabytes
            - Alone on the slide, as large as it will go
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
            notes: """
            ! Small blocks keep the damage local
            - One outlier in a block of 32 spoils 32 numbers, not 30 billion
            - This is the entire reason blocks exist
            """
          },
          %Slide{
            id: :the_label,
            title: "Q4, K, M",
            chapter: 7,
            steps: 3,
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
            id: :does_it_work,
            title: "The formula against real files",
            chapter: 7,
            steps: 3,
            notes: """
            ! Within about one percent, every time
            - These are real file sizes from Hugging Face, checked this week
            ! The gap is not overhead to apologise for. It is the wrong constant
            - Put 4.8 in for Q4_K_M rather than 4, and the formula is right
            - That is a better thing to remember than a rule with an excuse attached
            """
          },
          %Slide{
            id: :quality_and_speed,
            title: "Rules of thumb, and they are rules of thumb",
            chapter: 7,
            notes: """
            ! Say out loud that these are rules of thumb, not measurements
            - 8 bits is nearly lossless. 4 bits is the usual deal
            - Below about 3 bits quality falls off a cliff
            - Quantising also makes it faster. Generation is memory bandwidth bound, fewer bytes to move
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
            id: :other_labels,
            title: "Q8_0, Q5_K_M, IQ4_XS, FP8, AWQ, GPTQ, MLX 4bit",
            chapter: 7,
            notes: """
            - Names only. Do not compare them
            - The point is recognition: they all sit in this position of a name
            - If somebody asks which is best, that is a corridor conversation
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
            - 70 times 8.5 over 8. About 75 GB, and the real file is 74.98
            - Anything from 68 to 80 counts, including 70 if they used 8 bits flat
            """
          },
          %Slide{
            id: :round_two_bit,
            title: "Which one is 2 bit?",
            chapter: 7,
            round: :which_is_two_bit,
            steps: 2,
            notes: """
            - Three samples from our own toy model, quantised three ways
            - Below three bits it falls apart, and you can see it
            - This replaces a live demo. Safer, and it scores
            """
          }
        ]
      },
      %Section{
        number: 8,
        title: ".gguf",
        minutes: 3.75,
        lands: "the format says which program runs it, and the name has two authors",
        slides: [
          %Slide{
            id: :gguf_chapter,
            title: ".gguf",
            chapter: 8,
            notes: """
            - Chapter title. The last segment, and the easiest
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
            - 18.6 GB of model, a 12 GB card, 16 GB of system RAM
            ! Offload is the answer, and it is a good answer for an MoE
            - Only 3B is active for each token, so the traffic over PCIe is small
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
            id: :the_board,
            title: "The board",
            chapter: 9,
            notes: """
            - Read the top three out loud, by handle
            - Thank the room for playing
            - If the game broke, say what you learned anyway
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
