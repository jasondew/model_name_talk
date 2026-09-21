# How to Read a Model Name: deck and audience game

A 45 minute technical talk for an internal AI Guild meeting, delivered fully
remote, that decodes one file name from left to right:

    Qwen3-30B-A3B-Instruct-2507-Q4_K_M.gguf

Each segment is a chapter. Each chapter ends with a scored question. The
audience plays along on their phones and a leaderboard runs through the talk.

The content brief is `docs/brief.md`. This document is the design of the
software that delivers it.

## 1. Origin

This is the second talk in a series. The first, "Attention, From Scratch", is
`~/src/tiny_llm_talk`: a Phoenix LiveView deck where every number on every
slide comes from a toy transformer in the sibling checkout. Its structure is
the starting point here.

That deck also contained a complete phone in audience: a `Room` GenServer, a
join page, a QR code and a scoreboard, with 316 lines of tests. All of it was
deleted four days before the talk, in commit `410b11a`, for one stated reason:

> The audience room, its join page, the QR code and the scoreboard go: no time
> left to rehearse them before the talk.

It was cut for want of rehearsal, not because it failed. The cut happened in
four steps over four days, from four audience moments down to zero. That
history sets two rules for this project, in section 3.

## 2. Decisions

| Question | Decision |
|---|---|
| Venue | Fully remote. Everyone on a call, speaker screenshares. |
| Audience view | Screenshare for slides, separate companion page for playing. |
| Interaction shape | Spine: a running decode game, one round per chapter. |
| Competition | Warm. Handles, not real names. Top 5 plus your own line. |
| Scoring | Correctness base plus a small speed bonus. First correct wins. |
| Answer types | Multiple choice and numeric entry with a tolerance band. |
| Round timer | 20 seconds, configurable per round. |
| Reuse | Recover the deleted code, then extend it. |
| Sequence | Game first, deck second. |

## 3. Two rules that come from the history

**Rule 1: the game is built and rehearsed before the deck is written.** The
failure mode of the previous talk was content first, interaction last,
rehearsal never. Interactivity is the spine here rather than a garnish, so
cutting it under deadline pressure would gut the talk instead of trimming it.
Building it first makes slide count the flexible variable, which is the
variable a speaker can compress live.

**Rule 2: every round degrades to a question asked out loud.** A round slide
with no participants is still a good slide. The recovered code states this
invariant as "The room is allowed to be empty", and it is kept: if the tunnel
dies or nobody joins, the speaker asks the question, the room answers in chat
or out loud, and the next step reveals the answer. The talk never depends on
the game working.

## 4. Architecture

One Phoenix application, three LiveViews.

| Route | Audience | Purpose |
|---|---|---|
| `/` | screenshared | the deck |
| `/presenter` | speaker's laptop | notes, clocks, controls, live answer count |
| `/play` | audience phones | handle entry, then the current question |

`/play` shows one of four states: waiting, question, locked, result. It never
renders slide content, so it cannot drift out of sync with the screenshare and
it stays readable on a phone in portrait.

No database. State lives in one supervised GenServer plus ETS, with an append
only log on disk for crash recovery. `tiny_llm_talk` has no Ecto and this does
not need it.

### 4.1 Activity lifecycle

Recovered unchanged from the old `Room`: which question is open is decided by
the slide on screen. Arriving at a round slide opens its round, leaving closes
it, and walking backwards re opens it. The speaker never manages the game as a
second thing while presenting.

### 4.2 Deployment

The deck runs on the speaker's laptop at `localhost:4000` and that is what gets
screenshared, so the slides depend on nothing but the speaker's machine. A
named `cloudflared` tunnel exposes only `/play` to the audience. If the tunnel
fails, the game stops and the talk continues untouched.

`cloudflared` is not currently installed on the speaker's machine. Installing
it and reserving a stable hostname is a talk day prerequisite, tracked in
section 10. A short hostname matters because a dense QR code does not survive
screenshare compression.

A Fly.io deployment is kept as a cold spare, deployed the day before and
probably never used. `tiny_llm_talk` already has a `fly.toml` to copy.

## 5. The game

Seven rounds. Each sits after its chapter's term card, so it tests what was
just taught and gives the chapter a clean boundary. The persistent file name
header lights the newly completed segment on the round slide.

| # | After | Question | Type |
|---|---|---|---|
| 1 | `Qwen3` | Which of these can you actually download the weights for? | MC |
| 2 | `30B` | GPT-2 small was 124M. How many fit inside 30.5B? | MC |
| 3 | `A3B` | `Llama-4-Scout-109B-A17B`: memory like a ?B model, speed like a ?B model | MC |
| 4 | `Instruct` | You send "What is the capital of France?" to a base model. What comes back? | MC |
| 5 | `Q4_K_M` | `Llama-3.3-70B-Instruct-Q8_0.gguf`: how many GB? | numeric |
| 6 | `Q4_K_M` | Three toy model outputs at 8, 4 and 2 bits. Which is the 2 bit one? | MC |
| 7 | `.gguf` | Finale: the full decode, then "does it fit on the 3060?" | MC + numeric |

Round 3 carries chapter 4 entirely: "109B memory, 17B speed" is the whole
lesson in one tap, and the wrong options are the two misconceptions people
actually hold. Round 5 is where the memory formula gets used rather than
shown. Round 6 replaces a live demo the brief itself flagged as risky.

Round 2 is the weakest of the seven and is the designated cut if the talk runs
long.

### 5.1 Round mechanics

A round opens on the deck and on every phone at once. The deck shows the
question, a countdown and **only the count of answers received**, never the
distribution. Showing a live bar chart before the reveal would bias everyone
who answers late, which matters now that answers are scored. This is a
deliberate change from the old `Room`, which broadcast the full tally
continuously.

On reveal the deck shows the distribution, the correct answer, who answered
first and the leaderboard top 5.

The timer defaults to 20 seconds and is set per round. The presenter view has
an **end round early** control, because 20 seconds of silence on a remote call
is long and there is no reason to burn 8 dead seconds once 28 of 31 people
have answered. The answer count ticking up gives the speaker something to
narrate over.

### 5.2 Scoring

- Correct answer: 10 points.
- Speed bonus: +5, +4, +3 for the first three correct answers, +1 for anyone
  else correct within the first half of the window.
- Wrong answer: 0.

The first correct answer wins the round outright, which is the requested
behaviour, but the bonus cannot overturn understanding: six correct answers
slowly (60) beats four correct answers quickly (56).

This matters because of remote latency. Screenshare delivery spreads the
moment people see a question across 1 to 3 seconds depending on their
connection. Decaying points from when the question opens would partly score
people's internet. Capping the bonus at 5 keeps latency noise inside the
bonus band instead of letting it decide the leaderboard.

**Numeric questions are exempt from the speed bonus:** a flat 10 for any
answer inside the band. This covers round 5 and the numeric half of the
finale. These are the only questions asking for arithmetic rather than
recognition, and turning them into a calculator race would penalise exactly
the careful reasoning the talk is trying to teach. The speaker says out loud
that round 5 is the no rush round. The speed bonus is per round configuration,
so rehearsal can change this with a one line edit.

### 5.3 Numeric answers

Each numeric round declares a tolerance band. Round 5's answer is about 74 GB
and the band accepts 70 to 78, so someone who used 8 bits per weight instead
of 8.5 and got 70 still scores. The question is whether they can apply the
formula, not whether they memorised the overhead constant.

### 5.4 Changing your mind

Free until the reveal, kept from the old `Room`. The last answer before lock
counts. Because the speed bonus is small and correctness is the base, there is
no reason to punish a correction. A changed answer keeps the timestamp of the
change, so a correction forfeits the speed bonus but not the 10 points.

## 6. Identity, scoring and persistence

### 6.1 Identity is a token, not a pid

The recovered `JoinLive` states an invariant that must now be inverted:

> This is the only route the audience touches, so it holds no state worth
> losing: closing the tab is a clean leave and re opening it is a clean join.

With a leaderboard, closing the tab must stop being a clean leave. The old
code keys participants by LiveView pid, which was invisible in person across
short activities. Across 40 minutes of a remote talk, phones lock and
background tabs get discarded, and every reconnect would mint a new
participant and silently drop that person's score.

`/play` mints a UUID into `localStorage` on first visit and asks for a handle.
Every reconnect replays the token. `Room.participants` is keyed by token;
pids are tracked separately and only answer the question "how many are
connected right now".

### 6.2 Scoring is a fold, not a counter

Every answer appends `{token, round, choice, correct?, answered_at}` to an ETS
table and to `priv/rounds/<date>.log`. The leaderboard is a fold over that
table, recomputed on demand. At roughly 30 people times 7 rounds there are
about 210 rows, so there is no performance reason to keep a running total, and
a derived board cannot drift out of sync with the answers that produced it.

A crash mid talk replays the log on boot and loses nothing. The log is also a
useful artifact after the talk: it says exactly which concept the room got
wrong, which is feedback a speaker rarely gets.

### 6.3 The leaderboard

Top 5 plus the viewer's own line: "you: 4 points, 6 of 7 rounds, 11th".
Everyone sees where they stand without putting 31 names on a screenshared
slide, and "6 of 7" makes a latecomer's position legible rather than
mysterious.

Ranking is by points, and a late joiner cannot reach the top 5. Ranking by
accuracy percentage was rejected: it would let someone who answered one
question correctly sit above someone who played every round. The speaker asks
people to join at the start, and the QR code is on every slide for those who
do not.

## 7. The deck

### 7.1 Recovered

`Room`, `JoinLive`, `join.css`, the `eqrcode` dependency, the `join_url`
configuration and all 316 lines of tests port over under `ModelNameTalk.*`.

### 7.2 Kept from tiny_llm_talk

Deck as data in `ModelNameTalk.Deck`; one `slide/1` clause per slide id with a
hatched stub fallback for unwritten slides; `Position` PubSub sync between the
deck and presenter windows; the presenter's section clock and pace indicator;
and the speaker notes format, where `-` is a cue, `!` is a point that must be
said out loud and `=` is a definition. That last one maps exactly onto the
brief's term cards.

### 7.3 New: the file name header

A persistent `<.filename>` component on every content slide, showing the whole
name with each segment in one of three states: done, current or pending. State
is derived from the slide's chapter rather than set by hand per slide.

Chapter 8's payoff is rendered on this same component: the vendor wrote
`Qwen3-30B-A3B-Instruct-2507` and a stranger on Hugging Face wrote
`Q4_K_M.gguf`. Showing that split on the header the audience has watched all
talk is the last insight before the close, which is why the component is worth
building properly once.

### 7.4 Typography

The delivery channel is a video codec, not a projector. Screenshare
compression destroys small monospace text, and the file name header is both
the core device of the talk and the thing that compresses worst. Type runs
substantially larger than in `tiny_llm_talk`, at heavy weight and maximum
contrast. This gets tested over a real screenshare early, not in the week of
the talk.

### 7.5 Persistent join chrome

The QR code and join URL sit bottom right on every slide, sized to survive
compression. A QR code under about 120px does not reliably scan off a shared
screen.

## 8. Testing

The recovered suite ports across and extends to the new surface:

- identity survives a reconnect, with score intact (the bug the old design hid)
- the leaderboard fold is correct across rounds and ties
- numeric tolerance bands, at and just outside the boundary
- speed bonus ordering, including a correction forfeiting the bonus
- log replay after a simulated crash restores every score
- every round slide renders with an empty room

## 9. Deviations from the brief

The brief says "Do not change the structure of the talk" and asks that any
recommended change be recorded separately. This is that record.

1. **A running game threads all eight chapters.** Requested after the brief was
   written. This is the largest change and the reason for the others.
2. **Exercise 1 moves from chapter 9 to round 5**, where the memory formula is
   still warm. Asking it 15 minutes later tests recall rather than
   understanding.
3. **Chapter 6 (`2507`) gets no round.** It is a 2 minute chapter and a date
   stamp question is free points costing 45 seconds.
4. **Demo 2 (quantise the toy model) is cut and becomes round 6.** The brief
   flags the demo as risky itself. A 13K parameter model produces near noise at
   full precision, so quantising it may demonstrate nothing legible. As a
   question, "which of these is the 2 bit output" keeps the point, removes a
   live demo risk and returns about 3 minutes to the budget.

### 9.1 Time budget

The brief's chapters sum to exactly 40 minutes with no slack.

| Item | Minutes |
|---|---|
| Brief content | 40.0 |
| Rounds 1 to 6, at 45s each | +4.5 |
| Round 7, the finale | +2.5 |
| Chapter 9 exercises, absorbed by round 7 | -2.5 |
| Demo 2, cut | -3.0 |
| **Total** | **41.5** |

That leaves about 3.5 minutes of the 45 for questions. If more is needed, cut
round 2 first.

## 10. Facts to verify

The brief marks 8 items as `[VERIFY]` and forbids inventing numbers. Several
are now load bearing for scored questions rather than slides alone: if Q8_0 is
not about 8.5 bits per weight, round 5's tolerance band scores people against
a fiction.

`docs/verify.md` holds one row per fact with a source URL and a date checked.
The deck renders an unverified fact with a visible `[VERIFY]` marker, so an
unchecked number cannot quietly reach a slide. Deliverable 3 of the brief
falls out of that file.

Talk day prerequisites tracked in the same file: install `cloudflared`,
reserve a stable hostname, and confirm QR legibility over a real screenshare.

## 11. Risks

| Risk | Mitigation |
|---|---|
| The game gets cut again under deadline pressure | Rule 1: build and rehearse it first, let slide count flex |
| Screenshare compression makes the header unreadable | Oversized type, tested over a real Zoom share early |
| Remote latency skews speed scoring | Bonus capped at 5 points, cannot overturn correctness |
| A phone locks and the participant loses their score | Token identity in localStorage, not pid |
| Server crash mid talk wipes the leaderboard | Append only log, replayed on boot |
| The tunnel fails during the talk | Every round degrades to a question asked out loud |
| An unverified number reaches a scored question | `docs/verify.md` plus a visible marker on the slide |
