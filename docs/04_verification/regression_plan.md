# Regression Plan

Use this file for simulation regression structure, expected outputs, and pass/fail criteria.

## M0 model and vector regression

```sh
python3 -m py_compile ref_model/python_model/*.py ref_model/compare/*.py
python3 -m unittest discover -s ref_model -p 'test*.py'
python3 -m ref_model.compare.generate_vectors \
  --output ref_model/compare/generated/mlkem768_smoke.json
python3 -m ref_model.compare.compare_vectors \
  ref_model/compare/vectors/mlkem768_smoke.json \
  ref_model/compare/generated/mlkem768_smoke.json
```

Pass requires zero test failures and exact schema/value equality. Comparison
stops at the first mismatch and prints its structured path, expected value, and
actual value. RTL simulation regressions are outside M0.

## M1 documentation baseline check

M1 changes no RTL. The existing `poly_sub` regression is rerun to resolve its
stale dedicated report:

```sh
bash sim/scripts/run_poly_sub.sh
git diff --check
```

Future M2/M3 regressions must add exhaustive bank-map tests, protocol
assertions, synchronous-memory latency checks, and `mlkem-vector-v1` adapters
before claiming compliance with the M1 contracts.

## M7 regression

```sh
timeout 9000s ./sim/scripts/run_m7_regression.sh
```

Pass requires every focused M7 program, primitive-boundary cases, deterministic
regeneration, full M6/M5/M4/M3 preservation, Python tests, clean temporary
cleanup, and the final
`M7_REGRESSION_STATUS=PASS` machine-readable summary.

## M8 regression tiers

`run_m8_smoke.sh` runs nine M8 unit/block smoke programs with a hard timeout.
`run_m8_regression.sh` is nonrecursive and runs smoke; 2 KeyGen_internal, 2
Encaps_internal, 4 valid Decaps_internal, and 4 fallback cases; 2 public
chains; public input checks; deterministic-vector reproduction; and one M7
decrypt sanity test. Defaults may be overridden with `M8_KEYGEN_VECTORS`,
`M8_ENCAPS_VECTORS`, `M8_DECAPS_VECTORS`, `M8_FALLBACK_VECTORS`, and
`M8_PUBLIC_CHAINS`. `run_full_project_regression.sh` remains optional and is
reserved for a later manual overnight/M9 run.
