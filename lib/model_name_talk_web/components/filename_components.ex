defmodule ModelNameTalkWeb.FilenameComponents do
  @moduledoc """
  The file name, drawn.

  The header is the progress bar of this talk. It sits on every content slide,
  it never moves, and the only thing that changes is which segment is lit. By
  the close the room has looked at it thirty times, which is what makes the
  annotated version worth photographing.

  It is set in monospace at a size that looks excessive on a laptop. It is not
  excessive: this reaches people through a screen share, and a long monospace
  string is the first thing a video codec ruins.
  """

  use Phoenix.Component

  alias ModelNameTalk.Filename

  attr :chapter, :integer, default: nil
  attr :authors, :boolean, default: false

  @doc "The name across the top of a slide, with the current chapter lit."
  def filename(assigns) do
    assigns = assign(assigns, segments: Filename.segments())

    ~H"""
    <header class={["filename", @authors && "filename--authors"]}>
      <p :if={@authors} class="filename__author filename__author--vendor">Qwen wrote this</p>

      <p class="filename__name">
        <span
          :for={segment <- @segments}
          class={[
            "filename__segment",
            "filename__segment--#{Filename.state(segment, @chapter)}",
            @authors && "filename__segment--by-#{segment.author}"
          ]}
        >{prefix(segment)}{segment.text}</span>
      </p>

      <p :if={@authors} class="filename__author filename__author--converter">
        whoever converted it wrote this
      </p>
    </header>
    """
  end

  @doc """
  The close's summary: every segment with its label underneath.

  This is the slide people photograph, so it is the one slide in the deck
  allowed to be dense.
  """
  def annotated(assigns) do
    assigns = assign(assigns, segments: Filename.segments())

    ~H"""
    <div class="annotated">
      <div :for={segment <- @segments} class="annotated__column">
        <p class="annotated__segment">{prefix(segment)}{segment.text}</p>
        <p class="annotated__label">{segment.label}</p>
      </div>
    </div>
    """
  end

  ## PRIVATE FUNCTIONS

  defp prefix(segment) do
    if Filename.first?(segment), do: "", else: Filename.separator(segment)
  end
end
