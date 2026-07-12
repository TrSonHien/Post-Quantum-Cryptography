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
