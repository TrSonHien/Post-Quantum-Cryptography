# Reference Model

Use this folder for golden models, known-answer tests, and RTL comparison tools.

- `c_ref/` stores C reference implementations.
- `python_model/` stores Python models, wrappers, or generators.
- `kat/` stores known-answer test vectors.
- `compare/` stores scripts that compare RTL output against golden output.

## Deterministic vector interface

`compare/vector_schema.py` defines strict `mlkem-vector-v1` JSON for the Python
oracle, future RTL testbenches, and comparison scripts. `compare/generate_vectors.py`
exports deterministic ML-KEM-768 cases, and `compare/compare_vectors.py` reports
the first exact mismatch. The tracked smoke set is
`compare/vectors/mlkem768_smoke.json`; bulk/regenerated vectors belong in the
ignored `compare/generated/` directory.

Run:

```sh
python3 -m ref_model.compare.generate_vectors --output ref_model/compare/generated/mlkem768_smoke.json
python3 -m ref_model.compare.compare_vectors ref_model/compare/vectors/mlkem768_smoke.json ref_model/compare/generated/mlkem768_smoke.json
```

These project-generated vectors are not final NIST CAVP/ACVP KAT evidence.

No RTL correctness claim should be made until comparisons against a trusted reference are passing.
