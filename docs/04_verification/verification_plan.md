# Verification Plan

Use this file to define unit, block, and system verification strategy.

Required before correctness claims:

- Golden model source
- KAT source
- Input/output formats
- Pass/fail comparison method
- Regression command

## M0 reference-model verification baseline

- Golden model: independent FIPS 203-derived ML-KEM-768 Python model under
  `ref_model/python_model/`.
- Shared vector format: strict `mlkem-vector-v1` JSON, validated by
  `ref_model/compare/vector_schema.py`.
- Exact comparator: `python3 -m ref_model.compare.compare_vectors EXPECTED ACTUAL`.
- Model regression: `python3 -m unittest discover -s ref_model -p 'test*.py'`.
- Regeneration check: generate into ignored `ref_model/compare/generated/`, then
  compare against the tracked curated smoke set.

This baseline proves deterministic internal consistency and catches exact data
divergence. It is not final NIST CAVP/ACVP ML-KEM validation.

## M6 codec and sampler verification

M6 uses the unchanged independent Python codec/sampling model plus hashlib
SHAKE. Exhaustive compression/decompression and CBD pair spaces, full packed
transactions, synthetic rejection streams, 64 integrated SampleNTT vectors,
two-directory regeneration, and complete M2--M5 preservation are run by
`sim/scripts/run_m6_regression.sh`.

## M1 architecture-contract verification

`m1_architecture_verification_plan.md` defines vector-to-interface translation,
protocol/memory/domain assertions, exhaustive bank-schedule checks, reset
tests, and completion-ordering gates for future RTL. Existing asynchronous
memory RTL remains a legacy baseline and is not M1-contract evidence.

## M7 deterministic K-PKE verification

`sim/scripts/run_m7_regression.sh` runs matrix/transpose and nonce helpers, 20
standalone vectors for each Algorithm 13--15 controller, 20 actual-RTL chained
roundtrips, protocol/reset stress, two-directory vector reproduction, full
M3--M6 preservation, and Python model/schema tests. Roundtrips include selected
walking-one messages. A focused primitive-boundary test covers informational
noncanonical ek/dk decoding and arbitrary ciphertext processing. Expected
values come from
the unchanged independent FIPS-first Python model. This is not final NIST
CAVP/ACVP validation.

## M8 academic functional verification

M8 uses deterministic `mlkem-vector-v1` data from the unchanged independent
Python model. The academic functional suite covers exact DK layout, EK modulus
and DK hash checks, fixed 1088/32 compare/select work, exact implicit-rejection
K, reduced indexed internal vectors, two public RBG chains, basic failure
handling, reset/restart, and M7 preservation. This is basic differential
verification, not final NIST CAVP/ACVP validation or a side-channel claim.
