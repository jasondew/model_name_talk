defmodule ModelNameTalk.LedgerTest do
  use ExUnit.Case, async: false

  alias ModelNameTalk.Ledger

  setup do
    Ledger.forget()
    :ok
  end

  defp scored(list) do
    Map.new(list, fn {token, points} ->
      {token, %{points: points, correct?: points > 0, place: nil}}
    end)
  end

  describe "standings" do
    test "add a participant's points across rounds" do
      Ledger.record(:open_weights, scored([{"ada", 15}, {"grace", 10}]))
      Ledger.record(:how_many_gpt2s, scored([{"ada", 10}, {"grace", 0}]))

      standings = Ledger.standings(%{"ada" => "ada", "grace" => "grace"})

      assert [first, second] = standings
      assert first.handle == "ada"
      assert first.points == 25
      assert first.rounds == 2
      assert first.place == 1
      assert second.handle == "grace"
      assert second.points == 10
      assert second.rounds == 2
    end

    test "count a round answered even when it scored nothing" do
      Ledger.record(:open_weights, scored([{"ada", 0}]))

      assert [only] = Ledger.standings(%{"ada" => "ada"})
      assert only.rounds == 1
      assert only.points == 0
    end

    test "leave out somebody who never answered" do
      Ledger.record(:open_weights, scored([{"ada", 10}]))

      standings = Ledger.standings(%{"ada" => "ada", "absent" => "absent"})

      assert Enum.map(standings, & &1.handle) == ["ada"]
    end

    test "fall back to the token when a handle is not known" do
      Ledger.record(:open_weights, scored([{"ada", 10}]))

      assert [only] = Ledger.standings(%{})
      assert only.handle == "ada"
    end

    test "replace a round asked twice rather than paying for it twice" do
      Ledger.record(:open_weights, scored([{"ada", 15}]))
      Ledger.record(:open_weights, scored([{"ada", 10}]))

      assert [only] = Ledger.standings(%{"ada" => "ada"})
      assert only.points == 10
      assert only.rounds == 1
    end

    test "break a tie on points by handle, so the order is stable" do
      Ledger.record(:open_weights, scored([{"zoe", 10}, {"ada", 10}]))

      standings = Ledger.standings(%{"zoe" => "zoe", "ada" => "ada"})

      assert Enum.map(standings, & &1.handle) == ["ada", "zoe"]
      assert Enum.map(standings, & &1.place) == [1, 2]
    end

    test "are empty for a room that never answered anything" do
      assert Ledger.standings(%{}) == []
      assert Ledger.rounds_asked() == 0
    end

    test "count the distinct rounds asked" do
      Ledger.record(:open_weights, scored([{"ada", 10}]))
      Ledger.record(:open_weights, scored([{"ada", 10}]))
      Ledger.record(:how_many_gpt2s, scored([{"ada", 10}]))

      assert Ledger.rounds_asked() == 2
    end
  end

  describe "the log" do
    test "replays every score after a restart" do
      Ledger.record(:open_weights, scored([{"ada", 15}]))
      Ledger.record(:how_many_gpt2s, scored([{"ada", 10}]))

      path = Ledger.path()
      GenServer.stop(Ledger)
      wait_for_restart()

      assert [only] = Ledger.standings(%{"ada" => "ada"})
      assert only.points == 25
      assert only.rounds == 2
      assert File.exists?(path)
    end

    test "replays a round asked twice as its later answer only" do
      Ledger.record(:open_weights, scored([{"ada", 15}]))
      Ledger.record(:open_weights, scored([{"ada", 10}]))

      GenServer.stop(Ledger)
      wait_for_restart()

      assert [only] = Ledger.standings(%{"ada" => "ada"})
      assert only.points == 10
      assert only.rounds == 1
    end
  end

  ## PRIVATE FUNCTIONS

  defp wait_for_restart, do: wait_for_restart(200)

  defp wait_for_restart(0), do: flunk("the ledger did not come back")

  defp wait_for_restart(attempts) do
    case Process.whereis(Ledger) do
      nil ->
        Process.sleep(10)
        wait_for_restart(attempts - 1)

      pid ->
        if Process.alive?(pid), do: :ok, else: wait_for_restart(attempts - 1)
    end
  end
end
