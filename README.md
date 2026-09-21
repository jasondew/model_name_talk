# How to Read a Model Name

The deck for a 45 minute talk that decodes one file name, left to right:

    Qwen3-30B-A3B-Instruct-2507-Q4_K_M.gguf

Each segment is a chapter, and each chapter ends with a question the audience
answers on their phones. A leaderboard runs through the talk.

This is the second talk in a series. The first, "Attention, From Scratch",
lives in `../tiny_llm_talk` and built a toy transformer in pure Elixir. This
one refers to that model as the small end of every comparison and does not
explain transformers again.

## Running it

    mix setup
    mix phx.server

- <http://localhost:4000/> the deck, for the screen share
- <http://localhost:4000/presenter> the presenter view, for the laptop
- <http://localhost:4000/play> what the audience plays on

Either of the first two windows can hold the clicker; they follow each other
over PubSub. Arrows or space move, and the left arrow goes back.

## The audience is remote

Everyone is on a call watching a screen share, which decides two things.

The slides reach people through a video codec rather than a projector, so
type here is larger and heavier than it would want to be in a room. The long
monospace file name is the core device of the talk and is exactly what
compression ruins first. Check it over a real screen share before the talk,
not the week of it.

And the audience needs to reach `/play` from wherever they are. The deck runs
on the speaker's laptop so that the slides depend on nothing but that
machine, and a tunnel exposes only the audience's path:

    cloudflared tunnel --url http://localhost:4000

Then set the URL the QR code points at:

    JOIN_URL=https://the-tunnel-host/play mix phx.server

`cloudflared` is not yet installed on the speaker's machine. See
`docs/verify.md` for the rest of the talk day list.

If the tunnel fails, the talk continues. Every round is a question that works
asked out loud, and every page renders correctly with nobody playing.

## The game

Seven rounds, one closing each chapter. They live in `ModelNameTalk.Round`,
which is also the only place that decides what a right answer is.

Ten points for a right answer. Five, four and three more for the first three
right, and one for anyone else right in the first half of the window. Numeric
rounds pay a flat ten: they ask for arithmetic rather than recognition, and a
calculator race would punish the one habit the talk wants to leave behind.

The bonus is small because a video call hands people the question one to
three seconds apart depending on their connection. A steeper curve would rank
their internet. See `ModelNameTalk.Scoring` for what that cap does and does
not buy.

Which round is open is decided by the slide on screen. Arriving opens it, the
second press reveals the answer, leaving closes it, and walking back asks it
again. There is no separate control, because the one thing a speaker cannot
do while talking is remember a second thing.

## Why the game was built first

`tiny_llm_talk` had all of this once: a room, a join page, a QR code and a
scoreboard, with 316 lines of tests. It was deleted four days before that
talk, in commit `410b11a`, for one stated reason:

> no time left to rehearse them before the talk

It was cut for want of rehearsal, not because it failed, and it went in four
steps over four days from four audience moments down to none. Here the game
is the spine rather than a garnish, so cutting it would gut the talk instead
of trimming it. It is therefore built and rehearsed before the slides are
written, which makes slide count the thing that flexes under a deadline.

Identity is the one place this deliberately departs from the recovered code.
That version keyed the audience by LiveView pid, which was invisible in a
room across short activities. Over forty minutes of a remote talk, phones
sleep and background tabs get discarded, and every reconnect would mint a new
player and drop the old one's score. The token lives in the phone's local
storage instead.

## State

No database. One supervised `Room` GenServer holds who is here and what is
open. `ModelNameTalk.Ledger` keeps the scores in ETS and appends them to
`priv/rounds/<date>.log`, so a crash in the middle of a talk costs nothing.

That log is worth reading afterwards. It says exactly which idea the room got
wrong, which is feedback a speaker rarely gets.

## Documents

- `docs/brief.md` the content brief the talk is built from
- `docs/superpowers/specs/2026-09-21-model-name-talk-design.md` the design,
  including where it knowingly departs from the brief
- `docs/superpowers/plans/2026-09-21-audience-game.md` the plan this followed
- `docs/verify.md` every number that still needs a source

## Still to do

The deck is a stub: a title slide and one slide per round. The chapters are
plan 2, and they get written against a game that already works.
