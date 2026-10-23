defmodule ModelNameTalk.Round do
  @moduledoc """
  The questions the talk asks out loud, in the order it asks them.

  One round closes each chapter, so a round knows which segment of the file
  name it comes after. The room answers by voice or in the call's chat, and
  the second press on the slide shows the answer.

  A numeric round carries a band as well as an answer, and the slide says
  what the band was. Someone who used eight bits for each weight instead of
  eight and a half and landed on seventy applied the formula correctly, which
  is the thing being asked.
  """

  @enforce_keys [:id, :question, :type, :after_segment]
  defstruct [
    :id,
    :question,
    :type,
    :answer,
    :band,
    :after_segment,
    options: [],
    seconds: 20
  ]

  @type t :: %__MODULE__{
          id: atom(),
          question: String.t(),
          type: :choice | :numeric,
          answer: String.t() | number() | nil,
          band: {number(), number()} | nil,
          after_segment: String.t(),
          options: [String.t()],
          seconds: pos_integer()
        }

  @doc "Every round the talk asks, in order."
  @spec all() :: [t()]
  def all do
    [
      %__MODULE__{
        id: :open_weights,
        after_segment: "Qwen3",
        question: "Which of these can you actually download the weights for?",
        type: :choice,
        options: ["Claude", "GPT-4", "Qwen3", "Gemini"],
        answer: "Qwen3",
        seconds: 20
      },
      %__MODULE__{
        id: :how_many_gpt2s,
        after_segment: "30B",
        question: "GPT-2 small was 124M. How many of it fit inside 30.5B?",
        type: :choice,
        options: ["25", "246", "2,460", "24,600"],
        answer: "246",
        seconds: 20
      },
      %__MODULE__{
        id: :memory_versus_speed,
        after_segment: "A3B",
        question:
          "Llama-4-Scout-109B-A17B needs the memory of a ?B model and runs at the speed of a ?B model.",
        type: :choice,
        options: [
          "109B memory, 109B speed",
          "17B memory, 17B speed",
          "109B memory, 17B speed",
          "17B memory, 109B speed"
        ],
        answer: "109B memory, 17B speed",
        seconds: 20
      },
      %__MODULE__{
        id: :base_completion,
        after_segment: "Instruct",
        question: ~s(You send "What is the capital of France?" to a base model. What comes back?),
        type: :choice,
        options: [
          "Paris.",
          "The capital of France is Paris, a city of 2.1 million people.",
          "What is the capital of Germany? What is the capital of Spain?",
          "I am a language model and cannot browse the web."
        ],
        answer: "What is the capital of Germany? What is the capital of Spain?",
        seconds: 20
      },
      %__MODULE__{
        id: :how_many_gigabytes,
        after_segment: "Q4_K_M",
        question: "Llama-3.3-70B-Instruct-Q8_0.gguf. How many gigabytes?",
        type: :numeric,
        # The real file is 74.98 GB. 70 x 8.5 / 8 gives 74.4, and the true
        # parameter count of 70.55B gives 74.96. The band also takes 70,
        # which is what somebody gets who used 8 bits and forgot that Q8_0
        # carries a scale for every block of 32 weights. They applied the
        # formula, which is the thing being asked.
        answer: 75,
        band: {68, 80},
        seconds: 45
      },
      %__MODULE__{
        id: :does_it_fit,
        after_segment: ".gguf",
        question: "18.6 GB of model, a GPU with 12 GB and 16 GB of system RAM. What do you do?",
        type: :choice,
        options: [
          "Nothing. It cannot run.",
          "Offload part of it to system RAM",
          "Buy a second GPU",
          "Run it at BF16 instead"
        ],
        answer: "Offload part of it to system RAM",
        seconds: 20
      }
    ]
  end

  @doc "One round by identifier, or nil when there is no such round."
  @spec fetch(atom() | nil) :: t() | nil
  def fetch(nil), do: nil
  def fetch(identifier), do: Enum.find(all(), &(&1.id == identifier))
end
