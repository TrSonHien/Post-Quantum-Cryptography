# Reference Model

Use this folder for golden models, known-answer tests, and RTL comparison tools.

- `c_ref/` stores C reference implementations.
- `python_model/` stores Python models, wrappers, or generators.
- `kat/` stores known-answer test vectors.
- `compare/` stores scripts that compare RTL output against golden output.

No RTL correctness claim should be made until comparisons against a trusted reference are passing.
