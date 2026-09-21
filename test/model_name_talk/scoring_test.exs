defmodule ModelNameTalk.ScoringTest do
  use ExUnit.Case, async: true

  alias ModelNameTalk.{Round, Scoring}

  defp answers(round, list) do
    Map.new(list, fn {token, value, at} ->
      {token, %{value: value, at: at, correct?: Round.correct?(round, value)}}
    end)
  end

  describe "a choice round" do
    setup do
      %{round: Round.fetch(:open_weights), opened_at: 0}
    end

    test "pays nothing for a wrong answer", context do
      scored =
        Scoring.score(
          context.round,
          context.opened_at,
          answers(context.round, [{"wrong", "Claude", 100}])
        )

      assert scored["wrong"].points == 0
      refute scored["wrong"].correct?
    end

    test "adds five, four and three to the first three right answers", context do
      scored =
        Scoring.score(
          context.round,
          context.opened_at,
          answers(context.round, [
            {"first", "Qwen3", 100},
            {"second", "Qwen3", 200},
            {"third", "Qwen3", 300},
            {"fourth", "Qwen3", 400}
          ])
        )

      assert scored["first"].points == 15
      assert scored["second"].points == 14
      assert scored["third"].points == 13
      assert scored["fourth"].points == 11
    end

    test "names the place a right answer came in", context do
      scored =
        Scoring.score(
          context.round,
          context.opened_at,
          answers(context.round, [
            {"first", "Qwen3", 100},
            {"second", "Qwen3", 200},
            {"wrong", "Claude", 50}
          ])
        )

      assert scored["first"].place == 1
      assert scored["second"].place == 2
      assert is_nil(scored["wrong"].place)
    end

    test "gives no late bonus past the halfway mark", context do
      halfway = trunc(context.round.seconds * 1000 / 2)

      scored =
        Scoring.score(
          context.round,
          context.opened_at,
          answers(context.round, [
            {"first", "Qwen3", 1},
            {"second", "Qwen3", 2},
            {"third", "Qwen3", 3},
            {"early", "Qwen3", halfway - 1},
            {"late", "Qwen3", halfway + 1}
          ])
        )

      assert scored["early"].points == 11
      assert scored["late"].points == 10
    end

    # The bonus exists to name who was first, not to decide the talk. The worst
    # case for that is somebody who answers only four rounds and takes first
    # place in every one: they draw level with six plain right answers and no
    # further. Any less perfect run of four loses to six outright.
    test "being fast at most draws level with being right more often", context do
      always_first =
        Scoring.score(
          context.round,
          context.opened_at,
          answers(context.round, [{"speedy", "Qwen3", 1}])
        )["speedy"].points

      assert always_first == 15
      assert 6 * 10 >= 4 * always_first

      realistic =
        Scoring.score(
          context.round,
          context.opened_at,
          answers(context.round, [
            {"other", "Qwen3", 1},
            {"speedy", "Qwen3", 2}
          ])
        )["speedy"].points

      assert realistic == 14
      assert 6 * 10 > 4 * realistic
    end

    test "scores an empty room without complaint", context do
      assert Scoring.score(context.round, context.opened_at, %{}) == %{}
    end
  end

  describe "a numeric round" do
    test "pays a flat ten, however fast, because it is the no rush round" do
      round = Round.fetch(:how_many_gigabytes)

      scored =
        Scoring.score(
          round,
          0,
          answers(round, [{"first", "74", 10}, {"second", "70", 20}, {"wrong", "15", 30}])
        )

      assert scored["first"].points == 10
      assert scored["second"].points == 10
      assert scored["wrong"].points == 0
    end
  end
end
