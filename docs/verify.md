# Facts to verify

The brief forbids inventing numbers. Every number the talk says out loud, and
every number a round scores against, belongs in this table with a source.

Some of these are now **load bearing for scoring**, not just for a slide. If
Q8_0 is not about 8.5 bits for each weight, round 5's tolerance band scores
the audience against a fiction and the leaderboard is wrong. Those rows are
marked.

Nothing below has been checked yet. The deck renders an unverified fact with
a visible `[VERIFY]` marker so that an unchecked number cannot quietly reach
a slide.

## The model in the title

| Fact | Value used | Used by | Source | Checked | Status |
|---|---|---|---|---|---|
| Qwen3 vocabulary size | approximately 150K tokens | chapter 2 | | | not checked |
| Qwen3-30B-A3B total parameters | 30.5B | chapter 3, round 2 | | | not checked |
| Qwen3-30B-A3B active parameters | 3.3B | chapter 4 | | | not checked |
| Qwen3-30B-A3B expert count | 128 | chapter 4 | | | not checked |
| Experts used for each token | 8 | chapter 4 | | | not checked |
| Instruct-2507 context window | 262,144 tokens | chapter 7 | | | not checked |
| The April 2025 release and the 2507 split | two models replaced one | chapter 6 | | | not checked |

## Quantization

| Fact | Value used | Used by | Source | Checked | Status |
|---|---|---|---|---|---|
| **Q8_0 bits for each weight** | **approximately 8.5** | **round 5 band** | | | **not checked, load bearing** |
| Q4_K_M bits for each weight | approximately 4.8 | chapter 7 | | | not checked |
| Qwen3-30B-A3B at BF16 | 61 GB | chapter 7 | | | not checked |
| Qwen3-30B-A3B at Q8_0 | 32 GB | chapter 7 | | | not checked |
| Qwen3-30B-A3B at Q4_K_M | 18.6 GB | chapter 7, round 7 | | | not checked |
| Qwen3-30B-A3B at 2 bit | approximately 11 GB | chapter 9 | | | not checked |
| Qwen3-4B-Instruct-2507 at Q4_K_M | approximately 2.5 GB | chapter 9 | | | not checked |
| Ollama tag default quantization | usually Q4_K_M | chapter 8 | | | not checked |

## Other models named in rounds

| Fact | Value used | Used by | Source | Checked | Status |
|---|---|---|---|---|---|
| GPT-2 small parameters | 124M | round 2 | | | not checked |
| **Llama-3.3-70B at Q8_0** | **approximately 74 GB** | **round 5 answer** | | | **not checked, load bearing** |
| Llama-4-Scout total parameters | 109B | round 3 | | | not checked |
| Llama-4-Scout active parameters | 17B | round 3 | | | not checked |
| The toy model's parameter count | approximately 13K | chapter 3 | | | not checked |

## The speaker's hardware

| Fact | Value used | Used by | Source | Checked | Status |
|---|---|---|---|---|---|
| RTX 3060 VRAM | 12 GB | round 7 | | | not checked |
| System RAM | 16 GB | round 7 | | | not checked |

## Round 5's tolerance band

The round accepts 68 to 80 against an answer of 74. The band exists so that
somebody who used 8 bits for each weight rather than 8.5, and got 70, still
scores: the question is whether they can apply the formula, not whether they
remembered the overhead constant.

If the real figure for Q8_0 moves, both the answer and the band move with it.
They live in one place, `ModelNameTalk.Round`, in the `:how_many_gigabytes`
entry.

## Talk day prerequisites

| Thing | Status |
|---|---|
| Install `cloudflared` | not done, not installed on this machine |
| Reserve a stable tunnel hostname | not done |
| Confirm the QR scans off a real screen share | not done |
| Confirm the file name header is legible over Zoom | not done |
| Rehearse the join flow on a real phone | not done |
| Rehearse round 5 and decide whether 45 seconds is right | not done |
