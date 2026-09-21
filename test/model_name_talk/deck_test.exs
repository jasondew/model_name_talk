defmodule ModelNameTalk.DeckTest do
  use ExUnit.Case, async: true

  alias ModelNameTalk.{Deck, Filename, Round, Slide}

  test "runs the nine chapters the brief names, in order" do
    assert Enum.map(Deck.sections(), & &1.number) == [1, 2, 3, 4, 5, 6, 7, 8, 9]
  end

  test "gives every section minutes and something it has to land" do
    for section <- Deck.sections() do
      assert section.minutes > 0
      assert section.lands != ""
      assert section.slides != []
    end
  end

  test "budgets about forty two minutes" do
    total = Deck.sections() |> Enum.map(& &1.minutes) |> Enum.sum()

    assert_in_delta total, 42, 1.5
  end

  test "gives every slide a unique id" do
    identifiers = Enum.map(Deck.slides(), & &1.id)

    assert length(identifiers) == length(Enum.uniq(identifiers))
  end

  test "gives every slide speaker notes" do
    for slide <- Deck.slides() do
      assert Slide.prose(slide) != "", "#{slide.id} has no notes"
    end
  end

  test "numbers every slide with its section and its place in the deck" do
    slides = Deck.slides()

    assert Enum.map(slides, & &1.index) == Enum.to_list(1..length(slides))
    assert Enum.all?(slides, &(&1.section != nil))
  end

  test "asks every round exactly once, in the order the rounds are written" do
    asked = Deck.slides() |> Enum.map(& &1.round) |> Enum.reject(&is_nil/1)

    assert asked == Enum.map(Round.all(), & &1.id)
  end

  test "gives every round slide two steps, so the answer waits for a press" do
    for slide <- Deck.slides(), slide.round do
      assert slide.steps == 2, "#{slide.id} does not wait before revealing"
    end
  end

  test "puts each round in the chapter whose segment it follows" do
    for slide <- Deck.slides(), slide.round do
      round = Round.fetch(slide.round)
      segment = Enum.find(Filename.segments(), &(&1.chapter == slide.chapter))

      assert segment.text == round.after_segment
    end
  end

  # The close carries chapter 9, which is past every segment, so the header
  # shows the whole name done while the annotated version is on screen.
  test "gives a chapter to every slide that should light a segment" do
    chapters = Deck.slides() |> Enum.map(& &1.chapter) |> Enum.reject(&is_nil/1) |> Enum.uniq()

    assert Enum.sort(chapters) == [2, 3, 4, 5, 6, 7, 8, 9]
  end

  test "shows the whole name as done through the close" do
    close = Enum.find(Deck.slides(), &(&1.id == :annotated_name))
    states = Enum.map(Filename.segments(), &Filename.state(&1, close.chapter))

    assert Enum.all?(states, &(&1 == :done))
  end

  test "ends each chapter that has terms with a term card" do
    cards = Enum.filter(Deck.slides(), &String.ends_with?(to_string(&1.id), "_terms"))

    assert length(cards) >= 5

    for card <- cards do
      refute Slide.definitions(card) == [], "#{card.id} is a term card with no definitions"
    end
  end

  test "collects at least twenty terms across the talk" do
    terms = Deck.slides() |> Enum.flat_map(&Slide.definitions/1) |> Enum.map(&elem(&1, 0))

    assert length(terms) >= 20
    assert length(terms) == length(Enum.uniq(terms)), "a term is defined twice"
  end

  test "finds the section a slide belongs to, and the minutes before it" do
    [first | _rest] = Deck.slides()

    assert Deck.section(first).number == 1
    assert Deck.minutes_before(Deck.section(first)) == 0
  end

  test "keeps the stub deck's navigation contract" do
    assert Deck.at(0).id == :title
    assert Deck.at(-5).id == :title
    assert Deck.at(9_999) == List.last(Deck.slides())
    assert Deck.length() == length(Deck.slides())
  end

  test "places a demo and its fallback together" do
    identifiers = Enum.map(Deck.slides(), & &1.id)

    demo = Enum.find_index(identifiers, &(&1 == :demo_base_instruct))
    fallback = Enum.find_index(identifiers, &(&1 == :demo_base_instruct_fallback))

    assert fallback == demo + 1
  end
end
