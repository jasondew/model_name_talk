# Facts to verify

The brief forbids inventing numbers. Every number the talk says out loud, and
every number a round scores against, belongs here with a source.

Checked on 2026-09-21. Two of the brief's figures were wrong and are corrected
below; everything else held up.

## Corrections to the brief

**The toy model has 15,104 parameters, not approximately 13K.** Counted from
`~/src/tiny_llm`, at the config the talk's checkpoint trains with
(`vocabulary_size: 32`, `d_model: 32`, `context_length: 16`, feed forward
width `4 * d_model`):

| Tensor | Parameters |
|---|---|
| `weight1`, `weight2` (feed forward) | 4,096 each |
| `query_weight`, `key_weight`, `value_weight`, `output_weight` | 1,024 each |
| `embeddings`, `projection` | 1,024 each |
| `positions` | 512 |
| `bias1` | 128 |
| `gain1`, `gain2`, `gain3`, `bias2` | 32 each |
| **Total** | **15,104** |

`tiny_llm_talk/README.md` already said "about fifteen thousand floats". The
brief's 13K was the figure that drifted. Chapter 3 should say 15K, which also
makes its comparison approximately 2.0 million times rather than 2.3 million.

**Round 5's answer is 75 GB, not 74.** The real file is 74.98 GB. The band
covers the whole reasonable spread either way; only the stated answer moved.

## Number formats

Computed with Python's struct module, rounding to nearest even for BF16.

| Format | Sign, exponent, mantissa | Largest value | Decimal digits | 0.1 becomes |
|---|---|---|---|---|
| FP32 | 1, 8, 23 | 3.40 x 10^38 | 7.2 | 0.10000000149011612 |
| FP16 | 1, 5, 10 | 65,504 | 3.3 | 0.0999755859375 |
| BF16 | 1, 8, 7 | 3.39 x 10^38 | 2.4 | 0.10009765625 |
| INT8 | whole number | -128 to 127 | | needs a scale |
| INT4 | whole number | -8 to 7 | | needs a scale |

## Quantization, from the llama.cpp source

Source: `ggml/src/ggml-common.h` at
<https://github.com/ggml-org/llama.cpp/blob/master/ggml/src/ggml-common.h>

| Format | Block | Bytes | Weights | Bits for each weight |
|---|---|---|---|---|
| Q8_0 | `sizeof(ggml_half) + QK8_0` | 34 | 32 | **8.5** |
| Q4_K | `2*sizeof(ggml_half) + K_SCALE_SIZE + QK_K/2` | 144 | 256 | **4.5** |
| Q6_K | `sizeof(ggml_half) + QK_K/16 + 3*QK_K/4` | 210 | 256 | **6.5625** |

The header's own comments say "Effectively 4.5 bits per weight" for Q4_K and
"Effectively 6.5625 bits per weight" for Q6_K.

**Q8_0 at 8.5 bits is verified and load bearing for round 5.** A web search
will tell you Q8_0 is 8 bits; that answer ignores the 2 byte scale carried by
every block of 32 weights. The struct is the primary source, and 34 bytes for
32 weights is 8.5 bits each. This is worth saying on the slide, because it is
exactly why the naive formula undershoots.

Q4_K_M is a mixture rather than a single format: the more sensitive tensors
are kept at Q6_K. Its effective cost is therefore model dependent, measured
below rather than derived.

## The formula against real files

`memory in GB = parameters in billions x bits for each weight / 8`

Sizes are the `size` field from the Hugging Face API, in bytes, converted at
1 GB = 1,000,000,000 bytes.

| File | Real size | Bits for each weight | Formula predicts | Error |
|---|---|---|---|---|
| Qwen3-30B-A3B-2507 BF16 | 61.10 GB | 16.008 | 61.06 GB | +0.05% |
| Qwen3-30B-A3B-2507 Q8_0 | 32.48 GB | 8.511 | 32.44 GB | +0.13% |
| Qwen3-30B-A3B-2507 Q4_K_M | 18.56 GB | 4.862 | 18.32 GB | +1.30% |
| Qwen3-30B-A3B-2507 Q2_K | 11.26 GB | 2.950 | | |
| Llama-3.3-70B Q8_0 | 74.98 GB | 8.501 | 74.96 GB | +0.02% |
| Llama-3.3-70B Q4_K_M | 42.52 GB | 4.821 | 42.33 GB | +0.44% |

The formula is accurate to within about one percent once the right bits for
each weight goes in. That is a better chapter 7 than the brief's version,
which framed the gap between 15 GB and 18.6 GB as something to explain away.
The gap is not overhead to apologise for; it is the wrong constant. Put 4.8
in rather than 4 and the formula lands.

Sources:
<https://huggingface.co/api/models/unsloth/Qwen3-30B-A3B-Instruct-2507-GGUF?blobs=true>,
<https://huggingface.co/api/models/unsloth/Llama-3.3-70B-Instruct-GGUF?blobs=true>

## The model in the title

Source: <https://huggingface.co/Qwen/Qwen3-30B-A3B-Instruct-2507/raw/main/config.json>

| Fact | Brief said | Actual | Status |
|---|---|---|---|
| `vocab_size` | approximately 150K | **151,936** | checked |
| Total parameters | 30.5B | **30,532,122,624** | checked |
| Activated parameters | 3.3B | 3.3B (model card) | checked |
| `num_experts` | 128 | **128** | checked |
| `num_experts_per_tok` | 8 | **8** | checked |
| `max_position_embeddings` | 262,144 | **262,144** | checked |
| `num_hidden_layers` | | 48 | checked |
| `architectures` | | `Qwen3MoeForCausalLM` | checked |

Two details worth a speaker note. `rope_scaling` is `null`, so the 256K
context is native to the 2507 refresh rather than YaRN extended as the
original was from 32K. And `decoder_sparse_step` is 1 with `mlp_only_layers`
empty, so every one of the 48 layers is an MoE layer, with no dense layers
interleaved. That is a cleaner story for chapter 4 than "some layers".

## Where 30.5B and 3.3B come from

Computed from the same config.json: hidden 2048, expert width 768, 48 layers,
128 experts, 8 used for each token, 32 attention heads, 4 key value heads,
head dimension 128, vocabulary 151,936, input and output embeddings untied.

| Part | Parameters |
|---|---|
| One expert, one layer (gate, up, down: 3 x 2048 x 768) | 4.72M |
| One expert across all 48 layers | 226M |
| All 128 experts | 28.99B, 95% of the model |
| Shared: attention, router, embeddings | 1.54B |
| **Total: shared + 128 experts** | **30.53B**, matches the config |
| **Active: shared + 8 experts** | **3.35B**, matches the model card |

The common misreading is that 3B is the size of one expert. It is the whole
of what one token uses.

## The 2507 release history

The brief's account holds. Qwen3 launched 2025-04-28 with hybrid thinking, a
single checkpoint that switched between reasoning and direct answers. The
2507 refresh split that into two models: Instruct-2507 on 2025-07-30 and
Thinking-2507 on 2025-07-31, and raised the context from 32K to 256K.

Sources: <https://huggingface.co/Qwen/Qwen3-30B-A3B>,
<https://simonwillison.net/2025/Jul/29/qwen3-30b-a3b-instruct-2507/>,
<https://www.theregister.com/software/2025/07/31/alibaba-admits-qwen3s-hybrid-thinking-mode-was-dumb/1284173>

## Other models named in rounds

| Fact | Value | Source | Status |
|---|---|---|---|
| Llama-3.3-70B-Instruct parameters | 70,553,706,560 | HF GGUF metadata | checked |
| Llama-4-Scout total parameters | 109B | Meta model card | checked |
| Llama-4-Scout activated parameters | 17B | Meta model card | checked |
| Llama-4-Scout experts | 16 | Meta model card | checked |
| GPT-2 small parameters | 124M | widely published, not re-checked | low risk |

Source for Llama 4 Scout:
<https://huggingface.co/meta-llama/Llama-4-Scout-17B-16E-Instruct>, spec table
row "Llama 4 Scout (17Bx16E)", Params column: "17B (Activated) 109B (Total)".

Worth a slide, and it sharpens round 3: Qwen and Meta name the opposite
quantity. `Qwen3-30B-A3B` is 30B total and 3B active. `Llama-4-Scout-17B-16E`
is 17B **active** with 16 experts, and its 109B total appears nowhere in the
name. The same leading number means different things in the two families.

## Still unchecked

| Fact | Used by | Why it is still open |
|---|---|---|
| Ollama tag default quantization | chapter 8 | Secondary sources agree it is Q4_K_M, but no primary source found. Say "usually" on the slide, or check one tag's manifest. |
| System RAM 16 GB | round 7 | Speaker's own machine. |
| Qwen3-4B-Instruct-2507 at Q4_K_M, approximately 2.5 GB | chapter 9 | Not fetched. |
| OLMo as the open source example | chapter 2, the three kinds table | AI2 publishes data and training code as well as weights, which is the distinction the slide draws, but the claim is not checked against their licence. |
| Gemma-3-27B, Llama-3.3-70B as family examples | chapter 2 | Names only, no numbers attached. |

A Q6_K row was cut from chapter 7's comparison because its file size was
predicted rather than measured. Every bar on that slide is a real file from
the table above. If Q6_K is wanted, fetch the size first.

## The speaker's hardware

| Fact | Value | Source | Status |
|---|---|---|---|
| RTX 3060 VRAM | **12 GB** | speaker confirmed 2026-09-21 | checked |
| System RAM | 16 GB | speaker's own machine | speaker to confirm |

The 3060 also ships in an 8 GB variant, which is why this was worth asking.
Round 7's premise is the 12 GB card.

## Talk day prerequisites

| Thing | Status |
|---|---|
| Install `cloudflared` | not done, not installed on this machine |
| Reserve a stable tunnel hostname | not done |
| Confirm the QR scans off a real screen share | not done |
| Confirm the file name header is legible over Zoom | not done |
| Rehearse the join flow on a real phone | not done |
| Rehearse round 5 and decide whether 45 seconds is right | not done |
| Produce the three toy model samples for round 6 | not done |
| Take the rehearsal screenshot for the base-and-instruct demo | not done |
| Walk the whole deck forwards, then backwards, against the clock | not done |

The last one matters most. The deck this grew out of lost its entire audience
game four days before the talk for want of a rehearsal, so a rehearsal is a
task here rather than an intention.
