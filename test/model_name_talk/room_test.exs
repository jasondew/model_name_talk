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
end
