# Test Vector Plan

Use this file to track KAT and directed/random test-vector sources.

Record source, format, license status, and exact conversion scripts when created.

## Deterministic project vectors

- Schema: `mlkem-vector-v1`, one JSON object containing strict metadata and an
  ordered vector list.
- Metadata records parameter set and values, source, deterministic 32-byte seed,
  generation command, byte order, and coefficient/domain representation.
- Each case records a unique ID, category, operation, structured inputs, and
  structured expected outputs.
- Tracked smoke set: `ref_model/compare/vectors/mlkem768_smoke.json`.
- Bulk output: `ref_model/compare/generated/` (ignored).
- Generator: `python3 -m ref_model.compare.generate_vectors --output PATH`.

Covered categories are arithmetic, codec, NTT/INTT, `MultiplyNTTs`, sampling,
K-PKE, and deterministic internal ML-KEM. The source is the independent Python
model, so these are project golden vectors, not authoritative external KATs.

Final NIST CAVP/ACVP ML-KEM vectors remain pending. Legacy Kyber 2020 vectors
remain separate regression inputs and must not be relabeled as FIPS validation.
