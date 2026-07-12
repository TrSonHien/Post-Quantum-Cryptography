# M0 Plan: Standards, Provenance, KAT, and Golden Models

## Purpose

M0 is the first project milestone. It replaces the older `M1: Algorithm and Verification Foundation` wording as the start of the roadmap.

M0 exists to establish trusted sources, FIPS 203 algorithm tracking, legacy-source boundaries, future C/Python/KAT harness rules, and completion gates before any new RTL architecture work.

## M0 scope

M0 covers:

- local standards and source provenance;
- FIPS 203 algorithm tracking for ML-KEM-768;
- future C reference harness planning;
- future KAT parsing and vector provenance planning;
- future independent Python golden-model planning;
- future comparison-tool planning;
- final M0 report and readiness gate for M1.

M0 does not include:

- RTL edits;
- new RTL architecture design;
- Python model implementation;
- KAT parser implementation;
- C harness implementation;
- comparison-script implementation;
- synthesis, place-and-route, or timing claims.

## Approved source policy

Source priority for M0:

1. NIST FIPS 203 for ML-KEM algorithms.
2. NIST FIPS 202 for SHA3/SHAKE and Keccak.
3. NIST SP 800-185 only if a SHA-3-derived function is explicitly needed.
4. Final NIST CAVP/ACVP ML-KEM vectors when obtained.
5. Kyber Round-3 specification and Kyber 2020 package as supporting legacy sources only.

The local Kyber 2020 C implementation and KATs are not final FIPS 203 validation evidence unless a later documented comparison proves equivalence for a specific algorithm or vector class.

## Generated-file rule

Generated C binaries, logs, `.req`, `.rsp`, intermediate vectors, and comparison outputs must not be written into the imported Kyber source package:

```text
ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/
```

Future generated C-reference outputs must use an ignored build/output directory under:

```text
ref_model/c_ref/build/
```

or a temporary directory.

## Sub-milestones

### M0.1 Source, standards, and provenance audit

Gate:

- official M0-M9 roadmap established;
- local standards classified;
- source SHA-256 manifest created for standards;
- Kyber 2020 C/KAT package labeled legacy;
- initial FIPS 203 algorithm tracking table created;
- M0 source audit report created;
- `TODO.md` and milestone status updated.

### M0.2 FIPS 203 algorithm tracking

Gate:

- every ML-KEM-768 algorithm and dependency used by the project has a row in `docs/00_project_spec/fips203_algorithm_tracking.md`;
- each row records normative source, inputs/outputs, ML-KEM-768 parameters, C candidate, future Python function, planned RTL milestone, vector source, current status, and unresolved differences;
- all FIPS/Kyber differences that affect implementation or vectors are explicitly tracked.

### M0.3 C/KAT harness

Gate:

- build/run flow for the selected local legacy Kyber768 C reference uses `ref_model/c_ref/build/` or `/tmp` — complete for Kyber768 via `ref_model/c_ref/run_kyber768_kat.sh`;
- local Kyber 2020 KAT parser preserves provenance and labels output as legacy Kyber regression material — complete via `ref_model/kat/parse_legacy_kyber_kat.py` and `ref_model/kat/kyber768_legacy_provenance.md`;
- no generated files are written into the imported source package — verified by Git status/diff checks against `ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001`;
- final NIST CAVP/ACVP ML-KEM vector acquisition path is documented as still missing external validation material.

M0.3 result:

- copied, built, and ran the local Kyber768 2020 reference implementation from ignored `ref_model/c_ref/build/kyber768_ref/`;
- reproduced `PQCkemKAT_2400.req` and `PQCkemKAT_2400.rsp` exactly against the local legacy KAT files;
- parsed and validated all 100 Kyber768 records for `count`, `seed`, `pk`, `sk`, `ct`, and `ss`;
- did not implement Python models, comparison tools, RTL, testbenches, or simulation collateral.

### M0.4 Independent Python golden model

Gate:

- Python model targets ML-KEM-768 first;
- parameters are cleanly structured for possible later 512/1024 extension but only 768 is in current validation scope;
- model is derived from FIPS 203 tracking, not copied blindly from Kyber C;
- low-level functions have self-checks and documented source references.

### M0.5 Comparison tools and final M0 report

Gate:

- comparison schema exists for C/Python/KAT/module vectors;
- C/Python equivalence is checked only for algorithms whose FIPS/Kyber differences are resolved;
- final M0 report identifies trusted sources, legacy sources, missing authoritative vectors, unresolved differences, and readiness for M1.

## M0 completion criteria

M0 is complete only when:

- FIPS 203 is the documented normative authority for ML-KEM-768;
- final NIST CAVP/ACVP ML-KEM vectors are either present or explicitly listed as missing external validation material;
- local Kyber 2020 vectors remain labeled legacy unless proven otherwise;
- an independent Python ML-KEM-768 model exists and is cross-checked against approved vectors or reviewed C candidates;
- comparison tooling can produce reproducible PASS/FAIL reports;
- no RTL changes were made during M0 unless a later user instruction explicitly expands scope.
