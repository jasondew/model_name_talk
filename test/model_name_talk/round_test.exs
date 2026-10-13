defmodule ModelNameTalk.RoundTest do
  use ExUnit.Case, async: true

  alias ModelNameTalk.Round

  describe "the catalogue" do
    # Round six went when the talk became slides only: it needed three real
    # samples from the toy model that were never produced.
    test "lists six rounds in talk order" do
      identifiers = Enum.map(Round.all(), & &1.id)

      assert identifiers == [
               :open_weights,
               :how_many_gpt2s,
               :memory_versus_speed,
               :base_completion,
               :how_many_gigabytes,
               :does_it_fit
             ]
    end

    test "gives every round a question, a segment and a timer" do
      for round <- Round.every() do
        assert round.question != ""
        assert round.after_segment != ""
        assert round.seconds >= 0
      end
    end

    test "gives every choice round at least two options and an answer among them" do
      for round <- Round.every(), round.type == :choice do
        assert length(round.options) >= 2
        assert round.answer in round.options
      end
    end

    test "gives every numeric round a band that contains its answer" do
      for round <- Round.every(), round.type == :numeric do
        {low, high} = round.band

        assert low <= round.answer and round.answer <= high
      end
    end

    test "exempts numeric rounds from the speed bonus" do
      for round <- Round.every(), round.type == :numeric do
        refute round.speed_bonus
      end
    end

    test "fetches a round by identifier, and nothing for an unknown one" do
      assert Round.fetch(:open_weights).type == :choice
      assert is_nil(Round.fetch(:not_a_round))
      assert is_nil(Round.fetch(nil))
    end

    test "keeps the test-only round out of the talk" do
      refute :fast_round_for_tests in Enum.map(Round.all(), & &1.id)
      assert Round.fetch(:fast_round_for_tests)
    end
  end

  describe "correct?/2" do
    test "compares a choice exactly" do
      round = Round.fetch(:open_weights)

      assert Round.correct?(round, round.answer)
      refute Round.correct?(round, "Claude")
    end

    test "accepts a number anywhere inside the band" do
      round = Round.fetch(:how_many_gigabytes)
      {low, high} = round.band

      assert Round.correct?(round, to_string(low))
      assert Round.correct?(round, to_string(high))
      assert Round.correct?(round, to_string(round.answer))
    end

    test "rejects a number outside the band" do
      round = Round.fetch(:how_many_gigabytes)
      {low, high} = round.band

      refute Round.correct?(round, to_string(low - 1))
      refute Round.correct?(round, to_string(high + 1))
    end

    test "accepts a decimal and a number wearing its unit" do
      round = Round.fetch(:how_many_gigabytes)

      assert Round.correct?(round, "74.4")
      assert Round.correct?(round, "74 GB")
      assert Round.correct?(round, "about 70")
    end

    test "rejects text that holds no number" do
      round = Round.fetch(:how_many_gigabytes)

      refute Round.correct?(round, "lots")
      refute Round.correct?(round, "")
    end
  end
end
