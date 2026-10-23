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
      for round <- Round.all() do
        assert round.question != ""
        assert round.after_segment != ""
        assert round.seconds >= 0
      end
    end

    test "gives every choice round at least two options and an answer among them" do
      for round <- Round.all(), round.type == :choice do
        assert length(round.options) >= 2
        assert round.answer in round.options
      end
    end

    test "gives every numeric round a band that contains its answer" do
      for round <- Round.all(), round.type == :numeric do
        {low, high} = round.band

        assert low <= round.answer and round.answer <= high
      end
    end

    test "fetches a round by identifier, and nothing for an unknown one" do
      assert Round.fetch(:open_weights).type == :choice
      assert is_nil(Round.fetch(:not_a_round))
      assert is_nil(Round.fetch(nil))
    end
  end
end
