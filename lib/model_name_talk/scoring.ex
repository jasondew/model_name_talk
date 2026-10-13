defmodule ModelNameTalk.Scoring do
  @moduledoc """
  What a round is worth.

  Ten points for a right answer. The first three right answers take five, four
  and three more, and anyone else right in the first half of the window takes
  one. A wrong answer is worth nothing.

  The bonus is small on purpose. The audience is remote and watching a shared
  screen, and a video call spreads the moment people see a question across a
  second or three depending on their connection. A bonus that decayed steeply
  from the moment a round opened would be scoring their internet. Capped at
  five, latency moves somebody between first and third place in a round and
  never between winning and losing the talk. The worst case is somebody who
  answers four rounds and takes first place in all four: that draws level with
  six plain right answers and goes no further. Any less perfect run of four
  loses to six outright.

  Numeric rounds pay a flat ten. They are the only questions asking for
  arithmetic rather than recognition, and a calculator race would punish
  exactly the careful reasoning the talk is trying to teach.
  """

  alias ModelNameTalk.Round

  @correct 10
  @podium [5, 4, 3]
  @early 1

  @type scored :: %{points: non_neg_integer(), correct?: boolean(), place: pos_integer() | nil}

  @doc "Every answer to one round, with what it earned and where it came in."
  @spec score(Round.t(), integer(), %{String.t() => map()}) :: %{String.t() => scored()}
  def score(%Round{} = round, opened_at, answers) do
    places =
      answers
      |> Enum.filter(fn {_token, answer} -> answer.correct? end)
      |> Enum.sort_by(fn {_token, answer} -> answer.at end)
      |> Enum.with_index(1)
      |> Map.new(fn {{token, _answer}, place} -> {token, place} end)

    Map.new(answers, fn {token, answer} ->
      place = Map.get(places, token)

      {token,
       %{
         correct?: answer.correct?,
         place: place,
         points: points(round, opened_at, answer, place)
       }}
    end)
  end

  ## PRIVATE FUNCTIONS

  defp points(_round, _opened_at, %{correct?: false}, _place), do: 0

  defp points(%Round{speed_bonus: false}, _opened_at, _answer, _place), do: @correct

  defp points(round, opened_at, answer, place) do
    @correct + bonus(round, opened_at, answer, place)
  end

  defp bonus(_round, _opened_at, _answer, place) when place <= 3, do: Enum.at(@podium, place - 1)

  defp bonus(round, opened_at, answer, _place) do
    halfway = opened_at + round.seconds * 1000 / 2

    if answer.at < halfway, do: @early, else: 0
  end
end
