defmodule ModelNameTalk.RoomTest do
  use ExUnit.Case, async: false

  alias ModelNameTalk.Room

  setup do
    Room.reset()
    :ok
  end

  defp elsewhere do
    spawn(fn -> Process.sleep(:infinity) end)
  end

  describe "joining" do
    test "registers a participant under their token" do
      Room.join("token-one", "ada", self())

      room = Room.state()

      assert Room.participant_count(room) == 1
      assert room.participants["token-one"].handle == "ada"
    end

    test "counts one participant however many tabs they open" do
      Room.join("token-one", "ada", self())
      Room.join("token-one", "ada", elsewhere())

      room = Room.state()

      assert Room.participant_count(room) == 1
      assert Room.connected_count(room) == 2
    end

    test "keeps a participant when one of their tabs closes" do
      other_tab = elsewhere()
      Room.join("token-one", "ada", self())
      Room.join("token-one", "ada", other_tab)

      Process.exit(other_tab, :kill)
      Process.sleep(50)

      room = Room.state()

      assert Room.participant_count(room) == 1
      assert Room.connected_count(room) == 1
    end

    test "keeps a participant after their last tab closes, so a locked phone can come back" do
      only_tab = elsewhere()
      Room.join("token-one", "ada", only_tab)

      Process.exit(only_tab, :kill)
      Process.sleep(50)

      room = Room.state()

      assert Room.participant_count(room) == 1
      assert Room.connected_count(room) == 0
    end

    test "lets a participant change their handle" do
      Room.join("token-one", "ada", self())
      Room.join("token-one", "grace", self())

      assert Room.state().participants["token-one"].handle == "grace"
    end

    test "tells subscribers when somebody joins" do
      Room.subscribe()
      Room.join("token-one", "ada", self())

      assert_receive {:room, %Room{}}
    end
  end

  describe "an empty room" do
    test "counts nothing and answers every question a slide asks" do
      room = Room.state()

      assert Room.participant_count(room) == 0
      assert Room.connected_count(room) == 0
      assert room.answers == %{}
      assert is_nil(room.round)
    end
  end

  describe "opening a round" do
    test "opens it, notes the time, and accepts answers" do
      Room.open(:open_weights)

      room = Room.state()

      assert room.round == :open_weights
      assert room.phase == :open
      assert is_integer(room.opened_at)
    end

    test "clears the answers of the round before it" do
      Room.open(:open_weights)
      Room.join("token-one", "ada", self())
      Room.answer("token-one", "Qwen3")

      Room.open(:how_many_gpt2s)

      assert Room.state().answers == %{}
    end

    test "opening the round already open changes nothing" do
      Room.open(:open_weights)
      Room.join("token-one", "ada", self())
      Room.answer("token-one", "Qwen3")

      opened_at = Room.state().opened_at
      Room.open(:open_weights)

      assert Room.state().opened_at == opened_at
      assert map_size(Room.state().answers) == 1
    end

    test "closes whatever is open when given nil" do
      Room.open(:open_weights)
      Room.open(nil)

      assert is_nil(Room.state().round)
    end
  end

  describe "answering" do
    setup do
      Room.open(:open_weights)
      Room.join("token-one", "ada", self())
      :ok
    end

    test "records an answer against the token that gave it" do
      Room.answer("token-one", "Qwen3")

      assert Room.state().answers["token-one"].value == "Qwen3"
      assert Room.state().answers["token-one"].correct?
    end

    test "marks a wrong answer wrong" do
      Room.answer("token-one", "Claude")

      refute Room.state().answers["token-one"].correct?
    end

    test "lets a participant change their mind, and takes the newer time" do
      Room.answer("token-one", "Claude")
      first = Room.state().answers["token-one"].at

      Process.sleep(5)
      Room.answer("token-one", "Qwen3")
      second = Room.state().answers["token-one"]

      assert second.value == "Qwen3"
      assert second.at > first
      assert Room.answered_count(Room.state()) == 1
    end

    test "ignores an answer once the round is locked" do
      Room.lock()
      Room.answer("token-one", "Qwen3")

      assert Room.state().answers == %{}
    end

    test "ignores an answer when no round is open" do
      Room.open(nil)
      Room.answer("token-one", "Qwen3")

      assert Room.state().answers == %{}
    end

    test "ignores a choice the round does not offer" do
      Room.answer("token-one", "Mistral")

      assert Room.state().answers == %{}
    end

    test "counts answers in the order the round lists its options" do
      Room.join("token-two", "grace", elsewhere())
      Room.answer("token-one", "Qwen3")
      Room.answer("token-two", "Claude")

      assert Room.tally(Room.state()) == [
               {"Claude", 1},
               {"GPT-4", 0},
               {"Qwen3", 1},
               {"Gemini", 0}
             ]
    end
  end

  describe "locking and revealing" do
    test "locks when the speaker ends the round early" do
      Room.open(:open_weights)
      Room.lock()

      assert Room.state().phase == :locked
    end

    test "locks on its own when the timer runs out" do
      Room.open(:fast_round_for_tests)

      Process.sleep(80)

      assert Room.state().phase == :locked
    end

    test "reveals from open without a separate lock" do
      Room.open(:open_weights)
      Room.reveal()

      assert Room.state().phase == :revealed
    end

    test "does not reveal when nothing is open" do
      Room.open(nil)
      Room.reveal()

      assert Room.state().phase != :revealed
    end

    test "an expiry belonging to an older round does not lock the current one" do
      Room.open(:fast_round_for_tests)
      Room.open(:open_weights)

      Process.sleep(80)

      assert Room.state().phase == :open
    end
  end
end
