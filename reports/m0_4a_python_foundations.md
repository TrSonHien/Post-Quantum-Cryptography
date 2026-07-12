# M0.4a Python Golden Model Foundations Report

## Scope

M0.4a implements independent Python foundations for ML-KEM-768 only:

- ML-KEM-768 parameters;
- modular arithmetic helpers;
- `ByteEncode_d`, `ByteDecode_d`, `Compress_d`, `Decompress_d`;
- `NTT`, `NTT^-1`, `BaseCaseMultiply`, `MultiplyNTTs`;
- `SampleNTT`, `SamplePolyCBD_eta`;
- SHA3-256, SHA3-512, SHAKE128, SHAKE256, `H`, `G`, `J`, `PRF`, and XOF wrappers using Python `hashlib`;
- deterministic self-tests and unit tests.

M0.4a does not implement K-PKE, full ML-KEM, comparison tooling, RTL, testbench, or simulation collateral.

## Source basis

The Python behavior is based on:

- FIPS 203 Section 4.1 for hash/XOF wrappers;
- FIPS 203 Section 4.2.1 for conversion and compression;
- FIPS 203 Section 4.2.2 for sampling;
- FIPS 203 Section 4.3 and 4.3.1 for NTT and NTT-domain multiplication;
- FIPS 202 through Python `hashlib` SHA3/SHAKE implementations.

It is not a line-by-line translation of the legacy Kyber C implementation.

## Representation and domain conventions

| Area | M0.4a convention |
|---|---|
| Coefficients | Canonical unsigned integers in `[0, q-1]`, with `q=3329`. |
| Polynomial length | Exactly 256 coefficients. |
| Normal domain | `R_q = Z_q[X]/(X^256 + 1)`, represented as coefficient arrays. |
| NTT domain | FIPS 203 `T_q` representation, represented as 256 integers. |
| NTT scaling | FIPS 203 Algorithm 10 inverse scale `3303 = 128^-1 mod q`. |
| Montgomery domain | Not used in the Python foundation model. |
| Lazy/centered ranges | Not used; all public outputs are canonical modulo `q`. |
| Compression rounding | Integer-only nearest rounding; no floating point. |
| XOF | Byte-oriented SHAKE128 wrapper with explicit squeeze offset. |

## C cross-check boundary

No legacy C/Python differential check is claimed in M0.4a. The M0.2 tracking file still marks the relevant legacy C mappings as `legacy-candidate` with unresolved representation, rounding, and Montgomery-domain differences. Therefore, M0.4a only runs independent FIPS-based self-tests and unit tests.

## Validation commands

```sh
python3 -m py_compile ref_model/python_model/*.py
python3 -m ref_model.python_model.selftest
python3 -m unittest discover -s ref_model/python_model -p 'test*.py'
git diff --check
```

## Result

PASS:

- Python compile check passed.
- Deterministic self-tests passed.
- Unit tests passed: 8 tests.
- C/Python cross-checks intentionally skipped because no low-level legacy C
  equivalence is approved yet.

## Remaining work

- M0.4b or later: K-PKE and full ML-KEM are still not implemented.
- Final NIST CAVP/ACVP ML-KEM vectors are still missing locally.
- Legacy C candidate equivalence for codec, sampler, NTT, and base multiply
  remains unresolved until explicit harness evidence exists.
- M0.5 comparison tooling has not started.
