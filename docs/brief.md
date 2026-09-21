# Handoff Brief: Slides for "How to Read a Model Name"

> **For Jason: fill in before you send this brief. Then delete this block.**
>
> 1. Output format for the slides: `[FILL IN: for example Livebook, Slidev, Marp, Keynote, pptx]`
> 2. Make sure that the audience saw "Attention, From Scratch". If not, remove the references to it.
> 3. Make sure of the parameter count of the toy model (this brief says approximately 13K).
> 4. Title: "How to Read a Model Name" is a working title. Change it if you have a better one.
> 5. Make a decision about the optional last slide (a preview of a later talk about harnesses and agents).

---

## 1. Your task

Build the slide deck for a 45-minute technical talk. This brief gives you the structure, the content, the definitions, and the design rules. You write the slides and the speaker notes.

Do not change the structure of the talk. If you think that a change is necessary, make the deck as specified and put your recommendation in a separate note.

## 2. Context

- **Speaker:** Jason Dew, a senior staff engineer. He has a strong background in backend systems, statistics, and machine learning.
- **Event:** an internal "AI Guild" meeting.
- **Audience:** software engineers who have an interest in AI. Most of them write Elixir. They are experienced engineers, but most are not machine learning specialists.
- **Slot:** 45 minutes. Plan 40 minutes of content and 5 minutes of questions.
- **Previous talk:** "Attention, From Scratch: a transformer in pure Elixir, no libraries". That talk built a toy transformer with a 32-word vocabulary, one attention head, one block, and approximately 13K parameters. The audience saw training, embeddings, attention, and inference. One word was one token.

Because of the previous talk, do not explain again how a transformer works. You can refer to the toy model as a known object. Use it as the small end of each comparison.

## 3. The main idea

The full talk decodes one real file name, from left to right:

```
Qwen3-30B-A3B-Instruct-2507-Q4_K_M.gguf
```

Each segment of the name is one chapter. Each chapter introduces a small set of AI terms that engineers hear frequently. At the end, the audience can read this name and other names like it. They can also estimate if a model fits on their hardware.

The talk must not feel like a glossary. The file name gives each term a position and a reason.

## 4. Scope

**In scope:** model, weights, parameters, checkpoint, model family, open weights, token, dense model, Mixture of Experts, active parameters, pre-training, post-training, base, instruct, thinking, chat template, version date stamps, numeric precision, quantization, context window, KV cache (one sentence only), file formats, inference engine.

**Out of scope. Do not include these subjects:**

- Harness, agent, tool call, MCP, RAG. The speaker keeps these for a different talk.
- Details of fine-tuning methods, RLHF, LoRA.
- A comparison of quantization formats. One slide can list other labels by name only.
- How attention works. The previous talk explained it.
- Benchmark scores or quality rankings of models.

## 5. Design rules

1. **Persistent header.** Show the full file name at the top of each content slide, in a monospace font. Highlight the segment of the current chapter. Show completed segments in a different, less bright style. The header is the progress indicator of the talk.
2. **One idea for each slide.** Keep the body text below approximately 15 words. Term cards are the only exception.
3. **Diagrams before bullets.** Section 6 specifies a visual for each chapter. Prefer simple diagrams to lists of text.
4. **Chapter pattern.** Each chapter has: one title slide with the segment in very large type, one to five content slides, and one term card.
5. **Term card.** The last slide of each chapter lists the new terms of that chapter. Each term has a definition of one line. Use the definitions from section 6 without a change of meaning.
6. **Speaker notes.** Write 2 to 5 sentences of notes for each slide, in a conversational tone. Put the detail in the notes, not on the slide.
7. **Legibility.** Use large type and high contrast. A person in the last row must be able to read each slide.
8. **Demo slides.** For each demo, make one placeholder slide with the title "DEMO" and a short description. Add a second slide with a space for a fallback screenshot.
9. **No decoration.** Do not use stock photographs, clip art, or decorative emoji.
10. **Language.** Use short sentences and plain words.

## 6. Talk structure

Target: approximately 34 slides.

| # | Chapter | Time | Slides |
|---|---|---|---|
| 1 | Opening | 2 min | 2 |
| 2 | `Qwen3` | 4 min | 4 |
| 3 | `30B` | 5 min | 4 |
| 4 | `A3B` | 6 min | 5 |
| 5 | `Instruct` | 5 min | 5 |
| 6 | `2507` | 2 min | 2 |
| 7 | `Q4_K_M` | 9 min | 7 |
| 8 | `.gguf` | 3 min | 3 |
| 9 | Close | 4 min | 3 |

### Chapter 1. Opening (2 min)

- Slide 1: the title.
- Slide 2: the file name only, very large, with no explanation. The speaker says: "In 40 minutes, you will be able to read each part of this name."

### Chapter 2. `Qwen3` (4 min)

**Main idea:** a model is a file of numbers plus an architecture. Some vendors give you the file. Other vendors give you only an API.

**Terms:**

- **Model:** a set of trained numbers, plus an architecture that tells a program how to use them.
- **Weights / parameters:** the numbers that training adjusts. In practice, the two words mean the same thing.
- **Checkpoint:** a saved copy of the weights at one point in time.
- **Family and generation:** Qwen is the family, from the Qwen team at Alibaba. 3 is the generation. One family has many sizes that share a design and a tokenizer.
- **Open weights:** the vendor publishes the weights file. This is not the same as open source, because the training data and training code are usually not public. A closed model (Claude, GPT) is available only through an API. You never see a file.
- **Token (short reminder):** the unit that the model reads and predicts. In the toy model, one word was one token. Real models use pieces of words. Qwen3 has a vocabulary of approximately 150K tokens. `[VERIFY]`

**Visual:** two columns. Left: "open weights", with a file icon and a download arrow. Right: "closed", with only an API endpoint.

### Chapter 3. `30B` (5 min)

**Main idea:** a parameter here is the same type of object as a parameter in the toy model. Only the quantity is different.

**Content:**

- B is billion. M is million. This model has approximately 30.5 billion parameters.
- The parameter count is a rough indication of capability. It is a direct cause of memory use and cost.
- Closed models frequently do not publish a parameter count.

**Terms:**

- **Parameter count:** the quantity of trained numbers in the model.
- **Dense model:** a model that uses all of its parameters for each token. This term prepares the next chapter.

**Visual:** a bar chart with a logarithmic scale. Three bars: the toy model (approximately 13K), GPT-2 small (124M), this model (30.5B). Add one caption: this model is more than 2 million times the size of the toy model.

### Chapter 4. `A3B` (6 min)

**Main idea:** total parameters set the memory. Active parameters set the speed.

**Content:**

- "A3B" means approximately 3 billion *active* parameters for each token. The segment tells you that the model is a Mixture of Experts (MoE).
- In a dense model, each layer has one feed-forward block (the MLP from the previous talk). In an MoE model, each layer has many small feed-forward blocks, which are the experts, plus a router.
- For each token, in each layer, the router selects a small number of experts. This model has 128 experts and uses 8 for each token. `[VERIFY]`
- All experts must be in memory, because the next token can use different experts. Thus the model needs the memory of a 30B model. But the compute for each token is that of a 3B model. Thus it runs at almost the speed of a 3B model.
- The attention layers are not divided. All tokens use them.
- If a name has no "A" segment, the model is usually dense.

**Speaker note about a common error:** the experts are not subject specialists. There is no "math expert" or "French expert". The model learns the routing for each token and each layer, and a person usually cannot read the result.

**Terms:**

- **Mixture of Experts (MoE):** a design in which each layer contains many small feed-forward blocks, and each token uses only some of them.
- **Expert:** one of those feed-forward blocks.
- **Router:** the small network that selects the experts for each token.
- **Active parameters:** the parameters that one token uses.

**Visuals:**

1. Two layers side by side. Left: a dense layer with one large FFN block. Right: an MoE layer with a router and a grid of 128 small blocks, with 8 highlighted.
2. One summary slide with two lines: "Total parameters → memory" and "Active parameters → speed".

### Chapter 5. `Instruct` (5 min)

**Main idea:** a base model only continues text. Post-training makes it follow instructions.

**Content:**

- Pre-training is the prediction of the next token on a very large quantity of text. The toy model did the same thing on a small scale. The result is a base model.
- If you give a question to a base model, it can continue with more questions. It continues the document. It does not answer you.
- Post-training is more training that makes the model follow instructions and use a chat format. One sentence is sufficient. Do not explain the methods.
- An **Instruct** variant answers directly. A **Thinking** variant first writes reasoning tokens and then answers. The Thinking variant is slower and uses more tokens, but it is better on difficult problems.
- The model always sees one flat sequence of tokens. A chat template puts special tokens around each message. Show the raw text for Qwen:

```
<|im_start|>user
What is the capital of France?<|im_end|>
<|im_start|>assistant
```

- Other words that you can see in this position of a name: `Base`, `Chat`, `it` (Gemma), `Coder`, `VL` (vision), `Distill`. Show the names only, with 2 or 3 words of explanation for each.

**Terms:**

- **Pre-training:** training to predict the next token on a very large text corpus.
- **Base model:** the result of pre-training. It continues text.
- **Post-training:** more training that makes the model follow instructions.
- **Instruct / Thinking:** post-trained variants. One answers directly. The other writes its reasoning first.
- **Chat template:** the text format, with special tokens, that puts a conversation into one token sequence.

**Visual:** a pipeline. "Text corpus → pre-training → Base → post-training → Instruct / Thinking".

**Demo 1:** see section 7.

### Chapter 6. `2507` (2 min)

**Main idea:** vendors update a model and keep the name. The date stamp identifies the version.

**Content:**

- 2507 is a year and a month: July 2025.
- A real example: the first Qwen3-30B-A3B (April 2025) was one model with a switch between thinking and non-thinking behavior. The 2507 update replaced it with two separate models, Instruct-2507 and Thinking-2507. The base name is the same, but the behavior is different. `[VERIFY]`
- The lesson for engineers: pin the model version, as you pin a dependency.
- The date stamp is not the knowledge cutoff of the model.

**Visual:** a simple timeline with the two releases.

### Chapter 7. `Q4_K_M` (9 min)

This chapter is the technical center of the talk.

**Main idea:** quantization stores each weight with fewer bits. The model becomes much smaller and loses a small amount of quality.

**Content, in this sequence:**

1. **Precision.** Vendors usually release weights at 16 bits for each weight.

   | Format | Bits | Bytes for each weight |
   |---|---|---|
   | FP32 | 32 | 4 |
   | FP16 / BF16 | 16 | 2 |
   | INT8 | 8 | 1 |
   | 4-bit | 4 | 0.5 |

2. **The formula.** Memory in GB ≈ parameters in billions × bits ÷ 8. Show it large, alone on a slide.

3. **The method.** Divide the weights into small blocks. For each block, store one scale value and one small integer for each weight. With 4 bits, each weight can have only 16 levels. To read a weight, multiply the integer by the scale. Show a worked example with 4 to 6 real numbers.

4. **Why blocks.** One very large weight would make the scale bad for the full tensor. Small blocks keep the damage local.

5. **The label.** Show the anatomy of `Q4_K_M`:
   - `Q4`: 4 bits for each weight.
   - `K`: the "k-quant" method from llama.cpp. It groups blocks into larger blocks and also quantizes the scales.
   - `M`: medium. The variants are S, M, and L. The more sensitive tensors keep more bits.
   - Because of the scales and the mixed precision, the real cost is approximately 4.8 bits for each weight. `[VERIFY]`

6. **The result for this model.** `[VERIFY all sizes against a GGUF repository on Hugging Face]`

   | Version | Approximate size |
   |---|---|
   | BF16 (the original release) | 61 GB |
   | Q8_0 | 32 GB |
   | Q4_K_M | 18.6 GB |

   The simple formula gives 15 GB for 4 bits. The real file is approximately 18.6 GB. Tell the audience why.

7. **Quality and speed.** These are rules of thumb. Label them as such. 8 bits is almost without loss. 4 bits is the usual compromise. Below approximately 3 bits, quality decreases quickly. Quantization also increases speed, because memory bandwidth limits token generation and there are fewer bytes to move.

8. **Memory is more than weights.** The KV cache also uses memory, and it becomes larger as the context becomes longer. Use one sentence for the KV cache: it stores the keys and values of all previous tokens, so that the model does not calculate them again.

9. **Other labels in this position:** `Q8_0`, `Q5_K_M`, `IQ4_XS`, `FP8`, `AWQ`, `GPTQ`, `MLX 4bit`. Show the names only. Do not compare them.

**Terms:**

- **Precision:** the number of bits that store each weight.
- **Quantization:** the conversion of weights to a lower precision after training.
- **Block and scale:** a small group of weights, and the one number that converts their integers back to real values.
- **Context window:** the maximum number of tokens that the model can use at one time. For this model it is 262,144 tokens. `[VERIFY]`
- **KV cache:** stored keys and values for previous tokens. It uses memory in proportion to the context length.

**Visuals:**

1. A number line. Weights at 16-bit precision move to the nearest of 16 levels.
2. A block diagram: one scale value plus a row of 4-bit integers.
3. The anatomy of the label `Q4_K_M`, with one callout for each part.
4. The size table as a bar chart.

**Demo 2:** see section 7.

### Chapter 8. `.gguf` (3 min)

**Main idea:** the file format tells you which program can run the file.

**Content:**

- GGUF is the single-file format of the llama.cpp project. One file contains the metadata (architecture and settings), the tokenizer, the chat template, and the tensors. Refer back to the chat template from chapter 5.
- An inference engine is the program that loads the weights and does the math.
- The usual path of a model: the vendor releases safetensors files at BF16. Then a person in the community converts and quantizes them to GGUF. Then you download the GGUF file.
- Thus the file name has two authors. The vendor wrote `Qwen3-30B-A3B-Instruct-2507`. The person who converted the model wrote `Q4_K_M.gguf`. Show this division on the header. It is a good last insight before the close.
- Ollama tags such as `qwen3:30b` hide the quantization. The default is usually Q4_K_M. `[VERIFY]`

| Format | Read by |
|---|---|
| GGUF | llama.cpp, Ollama, LM Studio |
| safetensors | Hugging Face Transformers, vLLM |
| MLX | MLX on Apple Silicon |

**Terms:**

- **Inference engine:** the program that loads the weights and runs the model.
- **GGUF:** the single-file model format of llama.cpp.
- **safetensors:** the Hugging Face format. Vendors usually use it for the original release.

**Visual:** one box for the file, divided into "metadata | tokenizer | chat template | tensors".

### Chapter 9. Close (4 min)

- **Slide 1: the annotated name.** Show the full name with a short label below each segment. This is the summary slide, and people will photograph it. Make it the best slide in the deck.

- **Slide 2: exercise 1.** Show `Llama-3.3-70B-Instruct-Q8_0.gguf`. The audience decodes it. Put the answer in the speaker notes and on a reveal step:
  - Llama family from Meta, generation 3.3.
  - 70B total parameters. There is no "A" segment, so the model is dense.
  - Instruct variant. There is no date stamp.
  - Q8_0: 8 bits, an older and simpler scheme, approximately 8.5 bits for each weight.
  - Memory: 70 × 8.5 ÷ 8 ≈ 74 GB.

- **Slide 3: exercise 2, "Does it fit?".** The model on the first slide is approximately 18.6 GB. The speaker has a GPU box with an RTX 3060 (12 GB VRAM) and 16 GB of system RAM. Ask the audience for the options. Put the answers on a reveal step:
  - A lower quantization. A 2-bit file is approximately 11 GB. It fits only barely, and the quality is poor. `[VERIFY]`
  - CPU offload. Keep part of the model in system RAM. This is acceptable for an MoE model, because only 3B parameters are active for each token.
  - A smaller model in the same family. Qwen3-4B-Instruct-2507 at Q4_K_M is approximately 2.5 GB. `[VERIFY]`

- **Optional slide 4:** one line that gives a preview of a later talk: "Next: from the file to the agent". Include it only if the speaker requests it.

## 7. Demos

The speaker does the demos live. You make only the placeholder slides and the fallback slides.

- **Demo 1 (chapter 5): base and instruct.** The speaker sends the same prompt to a base model and to an instruct model of the same family, for example Qwen3-4B-Base and Qwen3-4B-Instruct-2507. The base model continues the text. The instruct model answers.
- **Demo 2 (chapter 7): quantize the toy model.** The speaker quantizes the weights of the toy Elixir transformer to 8, 4, and 2 bits and shows the generated text at each level. Note for the speaker: a very small model can react differently than a large model. Do a test before the talk.

## 8. Facts to verify

Each item with the mark `[VERIFY]` comes from memory and not from a checked source. Before you finalize a slide that contains one of these items, check it against the primary source. The primary sources are the model card on Hugging Face, a GGUF repository for the model, and the llama.cpp documentation. If you cannot check an item, keep the `[VERIFY]` mark on the slide so that the speaker sees it.

- Qwen3 vocabulary size (approximately 150K tokens).
- Qwen3-30B-A3B: 30.5B total parameters, 3.3B active, 128 experts, 8 active for each token.
- The native context window of the Instruct-2507 variant (262,144 tokens).
- The history of the April 2025 release and the 2507 release.
- Q4_K_M at approximately 4.8 bits for each weight. Q8_0 at approximately 8.5 bits.
- All file sizes in chapter 7 and chapter 9.
- The default quantization of Ollama tags.
- The toy model parameter count (approximately 13K).

Do not invent numbers, dates, or quotations. If you need a fact that is not in this brief, find a primary source or omit the fact.

## 9. Deliverables

1. The slide deck, with speaker notes on each slide, in the output format from the top of this brief.
2. A one-page reference sheet for the audience. It contains the annotated file name, all the term definitions, and the memory formula.
3. A short list of the `[VERIFY]` items, each with a status: checked (with the source) or not checked.
