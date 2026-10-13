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

  describe "the brief's own rules" do
    # The brief says one idea for each slide with body text under about
    # fifteen words. A title that runs long is the first sign a slide is
    # carrying two ideas.
    test "no slide title carries more than ten words" do
      for slide <- Deck.slides() do
        words = slide.title |> String.split() |> length()

        assert words <= 10, "#{slide.id} has a #{words} word title"
      end
    end

    test "every chapter with a segment ends by asking about it" do
      # Chapter 6 is two minutes and a date stamp. A question there would be
      # free points costing forty five seconds.
      for chapter <- [2, 3, 4, 5, 7, 8] do
        slides = Enum.filter(Deck.slides(), &(&1.chapter == chapter))

        assert List.last(slides).round != nil, "chapter #{chapter} does not close on a round"
      end
    end

    test "no slide claims a number that docs/verify.md has not checked" do
      # The figures that carry numbers name them in one place each, so this
      # guards the one that would silently rot: round five's band against the
      # bits for each weight it is derived from.
      round = ModelNameTalk.Round.fetch(:how_many_gigabytes)
      {low, high} = round.band

      assert round.answer == 75
      assert low <= 70.553706560 * 8.5 / 8
      assert high >= 70.553706560 * 8.5 / 8
    end
  end
end
