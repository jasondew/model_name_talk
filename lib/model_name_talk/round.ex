defmodule ModelNameTalk.Round do
  @moduledoc """
  The questions the talk asks, in the order it asks them.

  One round closes each chapter, so a round knows which segment of the file
  name it comes after and the deck can light that segment as it asks.

  A round is also the only place that decides what "right" means. A phone
  sends a string either way, so a numeric round carries a tolerance band and
  parses what it is given: round five asks for gigabytes, and someone who used
  eight bits for each weight instead of eight and a half and landed on seventy
  has applied the formula correctly, which is the thing being tested.

  Numeric rounds carry no speed bonus. They are the only questions that ask
  for arithmetic rather than recognition, and a calculator race would punish
  exactly the careful reasoning the talk is trying to teach.
  """

  @enforce_keys [:id, :question, :type, :after_segment]
  defstruct [
    :id,
    :question,
    :hint,
    :type,
    :answer,
    :band,
    :after_segment,
    options: [],
    seconds: 20,
    speed_bonus: true
  ]

  @type t :: %__MODULE__{
          id: atom(),
          question: String.t(),
          hint: String.t() | nil,
          type: :choice | :numeric,
          answer: String.t() | number() | nil,
          band: {number(), number()} | nil,
          after_segment: String.t(),
          options: [String.t()],
          seconds: pos_integer(),
          speed_bonus: boolean()
        }

  @test_only :fast_round_for_tests

  @doc "Every round the talk asks, in order."
  @spec all() :: [t()]
  def all, do: Enum.reject(every(), &(&1.id == @test_only))

  @doc """
  Every round, including the one that exists only so a test need not sleep.

  The list lives in a function rather than a module attribute because a struct
  cannot be built in an attribute of the module that defines it.
  """
  @spec every() :: [t()]
  def every do
    [
      %__MODULE__{
        id: :open_weights,
        after_segment: "Qwen3",
        question: "Which of these can you actually download the weights for?",
        hint: "one of them ships you a file",
        type: :choice,
        options: ["Claude", "GPT-4", "Qwen3", "Gemini"],
        answer: "Qwen3",
        seconds: 20
      },
      %__MODULE__{
        id: :how_many_gpt2s,
        after_segment: "30B",
        question: "GPT-2 small was 124M. How many of it fit inside 30.5B?",
        hint: "B is billion, M is million",
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
        hint: "the A is the clue",
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
        hint: "it has had no post-training",
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
        hint: "no rush on this one. parameters times bits over eight",
        type: :numeric,
        # The real file is 74.98 GB. 70 x 8.5 / 8 gives 74.4, and the true
        # parameter count of 70.55B gives 74.96. The band also takes 70,
        # which is what somebody gets who used 8 bits and forgot that Q8_0
        # carries a scale for every block of 32 weights. They applied the
        # formula, which is the thing being asked.
        answer: 75,
        band: {68, 80},
        seconds: 45,
        speed_bonus: false
      },
      %__MODULE__{
        id: :which_is_two_bit,
        after_segment: "Q4_K_M",
        question:
          "Three samples from the toy model, quantised to 8, 4 and 2 bits. Which one is 2 bit?",
        hint: "below three bits it falls apart quickly",
        type: :choice,
        options: ["A", "B", "C"],
        answer: "C",
        seconds: 20
      },
      %__MODULE__{
        id: :does_it_fit,
        after_segment: ".gguf",
        question: "18.6 GB of model, a 12 GB card and 16 GB of system RAM. What do you do?",
        hint: "more than one of these works",
        type: :choice,
        options: [
          "Nothing. It cannot run.",
          "Offload part of it to system RAM",
          "Buy a second card",
          "Run it at BF16 instead"
        ],
        answer: "Offload part of it to system RAM",
        seconds: 20
      },
      %__MODULE__{
        id: :fast_round_for_tests,
        after_segment: "none",
        question: "A round whose timer runs out immediately, so the test does not sleep.",
        type: :choice,
        options: ["yes", "no"],
        answer: "yes",
        seconds: 0
      }
    ]
  end

  @doc "One round by identifier, or nil when there is no such round."
  @spec fetch(atom() | nil) :: t() | nil
  def fetch(nil), do: nil
  def fetch(identifier), do: Enum.find(every(), &(&1.id == identifier))

  @doc """
  Whether an answer is right. A choice must match exactly. A number need only
  land inside the band, because the band is the width of a reasonable rounding.
  """
  @spec correct?(t(), String.t()) :: boolean()
  def correct?(%__MODULE__{type: :choice, answer: answer}, given), do: given == answer

  def correct?(%__MODULE__{type: :numeric, band: {low, high}}, given) do
    case number(given) do
      nil -> false
      number -> low <= number and number <= high
    end
  end

  ## PRIVATE FUNCTIONS

  # A phone sends a string, and somebody will type "74 GB" or "74.4". Take the
  # first number in what arrived and ignore the rest.
  defp number(given) when is_binary(given) do
    case Regex.run(~r/-?\d+(\.\d+)?/, given) do
      nil -> nil
      [matched | _rest] -> String.to_float(ensure_decimal(matched))
    end
  end

  defp number(_given), do: nil

  defp ensure_decimal(text) do
    if String.contains?(text, "."), do: text, else: text <> ".0"
  end
end
