defmodule ModelNameTalkWeb.SheetLive do
  @moduledoc """
  One page for the room to take away.

  The annotated file name, the memory formula, and every term the talk
  defined. It is a route rather than a PDF because the link can go in the
  meeting chat next to the one they joined with, and because a page that
  needs regenerating is a page that goes stale.

  The terms are gathered from the slides' own speaker notes rather than typed
  again here. A term card, the speaker's glossary and this sheet are one
  piece of text read three ways, so they cannot come to disagree about what a
  word means.
  """

  use ModelNameTalkWeb, :live_view

  import ModelNameTalkWeb.FilenameComponents

  alias ModelNameTalk.{Deck, Slide}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(definitions: definitions())
     |> assign(page_title: "What's in a name?"), layout: false}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="sheet">
      <h1 class="sheet__title">What's in a name?</h1>

      <section class="sheet__block">
        <.annotated />
      </section>

      <section class="sheet__block">
        <h2 class="sheet__heading">How much memory</h2>
        <p class="sheet__formula">parameters in billions &times; bits for each weight &divide; 8</p>

        <table class="sheet__bits">
          <tbody>
            <tr :for={{format, bits} <- bits_for_each_weight()}>
              <th class="sheet__bits-format">{format}</th>
              <td class="sheet__bits-value">{bits}</td>
            </tr>
          </tbody>
        </table>

        <p class="sheet__note">
          Q8_0 is 8.5 rather than 8 because every block of 32 weights carries a
          2 byte scale. Use these and the answer lands within about one percent.
        </p>
      </section>

      <section class="sheet__block">
        <h2 class="sheet__heading">Every word we used</h2>

        <dl class="sheet__terms">
          <div :for={{term, meaning} <- @definitions} class="sheet__definition">
            <dt class="sheet__term">{term}</dt>
            <dd class="sheet__meaning">{meaning}</dd>
          </div>
        </dl>
      </section>
    </main>
    """
  end

  ## PRIVATE FUNCTIONS

  defp definitions do
    Deck.slides() |> Enum.flat_map(&Slide.definitions/1)
  end

  # From docs/verify.md, where each one has a source. Q4_K_M is measured
  # rather than derived, because it is a mixture of formats rather than one.
  defp bits_for_each_weight do
    [
      {"FP32", "32"},
      {"FP16 / BF16", "16"},
      {"Q8_0", "8.5"},
      {"Q6_K", "6.5625"},
      {"Q4_K_M", "about 4.8"},
      {"Q4_K", "4.5"}
    ]
  end
end
