defmodule ModelNameTalk.Section do
  @moduledoc """
  One chapter, with the minutes the brief gives it and the one thing it has to
  land. The presenter view shows both, because the only two questions a
  speaker asks mid-talk are where am I and am I behind.
  """

  @enforce_keys [:number, :title, :minutes, :lands, :slides]
  defstruct [:number, :title, :minutes, :lands, :slides]

  @type t :: %__MODULE__{
          number: pos_integer(),
          title: String.t(),
          minutes: number(),
          lands: String.t(),
          slides: [ModelNameTalk.Slide.t()]
        }
end
