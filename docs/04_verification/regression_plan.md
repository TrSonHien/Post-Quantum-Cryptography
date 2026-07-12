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
