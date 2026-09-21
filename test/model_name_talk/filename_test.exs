defmodule ModelNameTalk.FilenameTest do
  use ExUnit.Case, async: true

  alias ModelNameTalk.Filename

  test "joins back into the name the talk decodes" do
    assert Filename.text() == "Qwen3-30B-A3B-Instruct-2507-Q4_K_M.gguf"
  end

  test "names a segment for each chapter that has one" do
    chapters = Filename.segments() |> Enum.map(& &1.chapter)

    assert chapters == [2, 3, 4, 5, 6, 7, 8]
  end

  test "gives every segment a one line label" do
    for segment <- Filename.segments() do
      assert segment.label != ""
      assert segment.text != ""
    end
  end

  test "splits the name between its two authors" do
    by_author = Enum.group_by(Filename.segments(), & &1.author, & &1.text)

    assert by_author.vendor == ~w(Qwen3 30B A3B Instruct 2507)
    assert by_author.converter == ["Q4_K_M", ".gguf"]
  end

  describe "state/2" do
    test "lights the chapter on screen and dims the ones behind it" do
      states = Enum.map(Filename.segments(), &Filename.state(&1, 4))

      assert states == [:done, :done, :current, :pending, :pending, :pending, :pending]
    end

    test "leaves everything pending before the first chapter with a segment" do
      states = Enum.map(Filename.segments(), &Filename.state(&1, 1))

      assert Enum.all?(states, &(&1 == :pending))
    end

    test "shows the whole name as done at the close" do
      states = Enum.map(Filename.segments(), &Filename.state(&1, 9))

      assert Enum.all?(states, &(&1 == :done))
    end

    test "treats a slide with no chapter as showing nothing yet" do
      states = Enum.map(Filename.segments(), &Filename.state(&1, nil))

      assert Enum.all?(states, &(&1 == :pending))
    end
  end
end
