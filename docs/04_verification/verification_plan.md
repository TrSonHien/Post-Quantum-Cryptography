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

## M1 architecture-contract verification

`m1_architecture_verification_plan.md` defines vector-to-interface translation,
protocol/memory/domain assertions, exhaustive bank-schedule checks, reset
tests, and completion-ordering gates for future RTL. Existing asynchronous
memory RTL remains a legacy baseline and is not M1-contract evidence.
