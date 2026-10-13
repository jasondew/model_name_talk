defmodule ModelNameTalk.SlideTest do
  use ExUnit.Case, async: true

  alias ModelNameTalk.Slide

  defp slide(notes), do: %Slide{id: :example, title: "Example", notes: notes}

  test "reads a run of cues" do
    assert Slide.blocks(slide("- first\n- second\n")) == [{:cues, ["first", "second"]}]
  end

  test "reads a point that must be said out loud" do
    assert Slide.blocks(slide("! say this\n")) == [{:musts, ["say this"]}]
  end

  test "reads a definition as a term and its meaning" do
    blocks = Slide.blocks(slide("= token: what the model reads\n"))

    assert blocks == [{:definitions, [{"token", "what the model reads"}]}]
  end

  test "keeps a colon inside a definition's meaning" do
    blocks = Slide.blocks(slide("= ratio: one thing: another\n"))

    assert blocks == [{:definitions, [{"ratio", "one thing: another"}]}]
  end

  test "groups consecutive lines of one kind and keeps their order" do
    blocks = Slide.blocks(slide("- a\n! b\n- c\n= d: e\n"))

    assert blocks == [
             {:cues, ["a"]},
             {:musts, ["b"]},
             {:cues, ["c"]},
             {:definitions, [{"d", "e"}]}
           ]
  end

  test "continues an item on the line after it" do
    assert Slide.blocks(slide("- a long cue\n  that wrapped\n")) == [
             {:cues, ["a long cue that wrapped"]}
           ]
  end

  test "continues a definition's meaning on the line after it" do
    blocks = Slide.blocks(slide("= term: a meaning\n  that wrapped\n"))

    assert blocks == [{:definitions, [{"term", "a meaning that wrapped"}]}]
  end

  test "ignores blank lines" do
    assert Slide.blocks(slide("\n\n- a\n\n")) == [{:cues, ["a"]}]
  end

  test "has no blocks when there are no notes" do
    assert Slide.blocks(slide("")) == []
  end

  test "flattens to one paragraph for the stub" do
    assert Slide.prose(slide("- a\n! b\n= c: d\n")) == "a b c: d"
  end

  test "collects the definitions a slide carries" do
    card = slide("- a cue\n= one: first\n= two: second\n")

    assert Slide.definitions(card) == [{"one", "first"}, {"two", "second"}]
    assert Slide.definitions(slide("- just a cue\n")) == []
  end
end
