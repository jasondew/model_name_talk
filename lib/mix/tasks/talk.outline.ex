defmodule Mix.Tasks.Talk.Outline do
  @shortdoc "Prints the running order, for reading and for editing against"

  @moduledoc """
  The talk as an outline, generated from `ModelNameTalk.Deck`.

  A hand written outline drifts from the deck the first time a slide moves.
  This one cannot: it is the deck, printed. Read it to decide what the talk
  says, then change `lib/model_name_talk/deck.ex`, which is the only place
  the running order lives.

      mix talk.outline           the whole talk
      mix talk.outline --notes   with every speaker note
      mix talk.outline 7         one chapter

  A slide marked `[stub]` has no drawing of its own yet and renders hatched,
  showing its title and notes. That is deliberate while the deck is written:
  an unwritten slide announces itself rather than looking finished.
  """

  use Mix.Task

  import Phoenix.LiveViewTest, only: [render_component: 2]

  alias ModelNameTalk.{Deck, Round, Slide}

  @impl Mix.Task
  def run(arguments) do
    Mix.Task.run("app.start")

    {options, chapters, _invalid} = OptionParser.parse(arguments, switches: [notes: :boolean])
    wanted = Enum.map(chapters, &String.to_integer/1)

    Deck.sections()
    |> Enum.filter(&(wanted == [] or &1.number in wanted))
    |> Enum.each(&print_section(&1, options))

    print_summary()
  end

  ## PRIVATE FUNCTIONS

  defp print_section(section, options) do
    Mix.shell().info("")

    Mix.shell().info(
      IO.ANSI.bright() <>
        "#{section.number}. #{section.title}" <>
        IO.ANSI.reset() <>
        IO.ANSI.faint() <>
        "  #{section.minutes} min, #{length(section.slides)} slides" <> IO.ANSI.reset()
    )

    Mix.shell().info(IO.ANSI.faint() <> "   lands: #{section.lands}" <> IO.ANSI.reset())
    Mix.shell().info("")

    section.slides
    |> Enum.map(&%{&1 | section: section.number})
    |> Enum.each(&print_slide(&1, options))
  end

  defp print_slide(slide, options) do
    Mix.shell().info("   " <> title_line(slide))

    if Keyword.get(options, :notes, false) do
      slide |> Slide.blocks() |> Enum.each(&print_block/1)
      Mix.shell().info("")
    end
  end

  defp title_line(slide) do
    [
      IO.ANSI.faint(),
      String.pad_trailing(to_string(slide.id), 28),
      IO.ANSI.reset(),
      slide.title,
      marks(slide)
    ]
    |> Enum.join()
  end

  defp marks(slide) do
    [steps_mark(slide), round_mark(slide), stub_mark(slide)]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join()
  end

  defp steps_mark(%Slide{steps: 1}), do: ""

  defp steps_mark(%Slide{steps: steps}),
    do: IO.ANSI.faint() <> "  #{steps} steps" <> IO.ANSI.reset()

  defp round_mark(%Slide{round: nil}), do: ""

  defp round_mark(%Slide{round: identifier}) do
    round = Round.fetch(identifier)

    IO.ANSI.yellow() <>
      "  ROUND #{round.seconds}s #{round.type}" <> IO.ANSI.reset()
  end

  # Rendering is the only honest way to ask whether a slide has a drawing of
  # its own: the clause it would match lives in the component, not the data.
  defp stub_mark(slide) do
    drawn =
      render_component(&ModelNameTalkWeb.SlideComponents.slide/1,
        slide: slide,
        step: 1,
        room: %ModelNameTalk.Room{}
      )

    if String.contains?(drawn, "slide--stub") do
      IO.ANSI.faint() <> "  [stub]" <> IO.ANSI.reset()
    else
      ""
    end
  rescue
    _error -> ""
  end

  defp print_block({:cues, cues}) do
    Enum.each(cues, &Mix.shell().info(IO.ANSI.faint() <> "       - #{&1}" <> IO.ANSI.reset()))
  end

  defp print_block({:musts, musts}) do
    Enum.each(musts, &Mix.shell().info("       ! #{&1}"))
  end

  defp print_block({:definitions, pairs}) do
    Enum.each(pairs, fn {term, meaning} ->
      Mix.shell().info(
        IO.ANSI.yellow() <>
          "       #{term}: " <>
          IO.ANSI.reset() <>
          IO.ANSI.faint() <>
          meaning <> IO.ANSI.reset()
      )
    end)
  end

  defp print_summary do
    slides = Deck.slides()
    minutes = Deck.sections() |> Enum.map(& &1.minutes) |> Enum.sum()
    presses = slides |> Enum.map(& &1.steps) |> Enum.sum()
    rounds = Enum.count(slides, & &1.round)
    terms = slides |> Enum.flat_map(&Slide.definitions/1) |> length()

    Mix.shell().info("")

    Mix.shell().info(
      IO.ANSI.bright() <>
        "#{minutes} minutes, #{length(slides)} slides, #{presses} presses, " <>
        "#{rounds} rounds, #{terms} terms" <> IO.ANSI.reset()
    )

    Mix.shell().info("")
  end
end
