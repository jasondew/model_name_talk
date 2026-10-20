# Run from ~/src/tiny_llm_talk, which holds the trained checkpoint:
#
#     mix run --no-start ../model_name_talk/docs/experiments/quantise_toy.exs
#
# Quantise the toy transformer's trained weights the way llama.cpp does, in
# blocks of 32 with a scale and a minimum each, and measure what survives.
# Only matrices are quantised; one-row gains and biases stay full precision,
# as llama.cpp keeps norm weights in F32.

alias TinyLlm.{Eval, Grammar, Sampler}

checkpoint = :erlang.binary_to_term(File.read!("priv/checkpoints/transformer.bin"))
params = checkpoint.params

quantise_block = fn block, bits ->
  levels = Integer.pow(2, bits) - 1
  {low, high} = Enum.min_max(block)
  scale = if high == low, do: 1.0, else: (high - low) / levels
  Enum.map(block, fn value -> low + round((value - low) / scale) * scale end)
end

quantise_row = fn row, bits ->
  row |> Enum.chunk_every(32) |> Enum.flat_map(&quantise_block.(&1, bits))
end

quantise = fn bits ->
  Map.new(params, fn
    {name, [_single_row] = tensor} -> {name, tensor}
    {name, rows} -> {name, Enum.map(rows, &quantise_row.(&1, bits))}
  end)
end

Grammar.seed(7)
probes = Eval.probes(Grammar.corpus(2_000))

measure = fn label, quantised ->
  Sampler.seed(42)
  sentences = Enum.map(1..500, fn _ -> Sampler.sentence(quantised, temperature: 1.0) end)
  Sampler.seed(1)
  samples = Enum.map(1..4, fn _ -> Enum.join(Sampler.sentence(quantised, temperature: 1.0), " ") end)

  %{
    label: label,
    grammatical: Eval.grammaticality(sentences),
    agreement: Eval.agreement(Eval.model_predictor(quantised), probes),
    samples: samples
  }
end

results =
  [measure.("full precision", params)] ++
    Enum.map([8, 6, 4, 3, 2], fn bits -> measure.("#{bits} bits", quantise.(bits)) end)

for result <- results do
  IO.puts("\n#{result.label}: #{Float.round(result.grammatical * 100, 1)}% grammatical, " <>
            "#{Float.round(result.agreement * 100, 1)}% agreement on #{length(probes)} probes")
  for sample <- result.samples, do: IO.puts("    #{sample}")
end
