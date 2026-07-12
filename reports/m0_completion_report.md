# Milestone M0 Completion Report

## Status

M0.1 through M0.5 are complete. M0 established standards/provenance control,
detailed FIPS 203 algorithm tracking, a reproducible legacy Kyber768 C/KAT
harness, an independent deterministic internal ML-KEM-768 Python model, and
strict shared vector export/comparison infrastructure.

## Evidence

- Normative source hashes and provenance: `references/SHA256SUMS` and
  `docs/01_standard/source_provenance.md`.
- Algorithm traceability: `docs/00_project_spec/fips203_algorithm_tracking.md`.
- Legacy regression: 100 Kyber 2020 KAT cases reproduced and parsed by M0.3;
  explicitly not final FIPS 203 validation.
- Python oracle: deterministic foundation, K-PKE, ML-KEM internal algorithms,
  successful roundtrip, input checks, implicit rejection, and fallback tests.
- Vector infrastructure: `mlkem-vector-v1`, curated seven-category smoke set,
  strict malformed-input rejection, and exact first-mismatch diagnostics.

## Remaining external validation

Final NIST CAVP/ACVP ML-KEM vectors are not present locally. Importing their
authoritative provenance, manifesting hashes, parsing them, and comparing the
Python model remains mandatory before any final standards-validation claim.
The local Kyber 2020 C implementation and KATs remain legacy supporting sources.

## Readiness and boundary

M0 is closed as an algorithm/model/tooling foundation. It does not validate any
RTL and does not approve an M1 RTL architecture. M1 must begin only after
explicit authorization and must lock representations, interfaces, memory
latency, pipeline contracts, and independent vector use before RTL changes.
