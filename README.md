# What's in a name?

The slide deck for a 45 minute talk that reads one file name, left to right:

    Qwen3-30B-A3B-Instruct-2507-Q4_K_M.gguf

Each segment is a chapter, and each chapter ends with a question asked out
loud. By the end the room can read a name like this one and say whether the
model fits on their machine.

| Segment | What it says |
|---|---|
| `Qwen3` | the lab and the generation, and why open weights is not open source |
| `30B` | how many parameters, from a 15,104 parameter toy model to 2.8 trillion |
| `A3B` | a mixture of experts: 30.5B stored, 3.3B used for each token |
| `Instruct` | what post-training changes, and the chat template the model actually sees |
| `2507` | a date stamp, and why the same name can mean a different model |
| `Q4_K_M` | quantization, and the formula: parameters times bits, divided by 8 |
| `.gguf` | one file with weights, tokenizer and chat template, and the two authors of the name |

This is the second talk in a series. The first, [Transformers from Scratch, in
Elixir](https://github.com/jasondew/tiny_llm_talk), built a toy transformer in
pure Elixir ([`tiny_llm`](https://github.com/jasondew/tiny_llm)). This one
uses that model as the small end of every comparison and does not explain
transformers again.

## Running it

    mix setup
    mix phx.server

- <http://localhost:4000/> the deck, for the screen share
- <http://localhost:4000/presenter> the presenter view, for the laptop

Either window can hold the clicker; they follow each other over PubSub. Space
or the right arrow moves forward, the left arrow goes back. On the presenter
view, `t` pauses the clock and `r` resets it.

The presenter view shows the slide on screen, the next press at half size,
the speaker notes, the line the current section has to land, and a clock that
says whether the talk is ahead or behind.

## How the deck is built

- `lib/model_name_talk/deck.ex` is the running order as data: sections,
  slides, how many presses each slide takes, and the speaker notes. A note
  line starting `!` must be said, `-` is a cue, and `= term: meaning` is a
  glossary entry.
- `lib/model_name_talk_web/components/slide_components.ex` draws each slide,
  one function clause per slide id. A slide with no clause renders as its
  title.
- `lib/model_name_talk_web/components/figure_components.ex` holds the
  figures: the orders of magnitude chart, the expert grid, the bit layouts,
  the comparison tables.
- `mix talk.outline` prints the whole talk with timings. `--notes` adds the
  speaker notes, and `--markdown` writes [`docs/outline.md`](docs/outline.md).

The audience was remote, watching a screen share, so type is larger and
heavier than it would want to be in a room. Video compression ruins small
monospace text first, and the file name header is the core device of the
talk.

## The numbers

Every number on a slide is sourced in [`docs/verify.md`](docs/verify.md):
parameter counts from the model configs, file sizes from the Hugging Face
API, bits per weight from the llama.cpp block structs, and the few claims
that are still unchecked, marked as such.

The quantization quality slide is measured, not illustrated.
[`docs/experiments/quantise_toy.exs`](docs/experiments/quantise_toy.exs)
quantizes the trained `tiny_llm` model in blocks of 32 the way llama.cpp
does, at 8, 4, 3 and 2 bits, and scores what it writes. Run it from a
checkout of `tiny_llm_talk`, which holds the trained weights:

    mix run --no-start ../model_name_talk/docs/experiments/quantise_toy.exs

## Licence

MIT. See [LICENSE](LICENSE).
