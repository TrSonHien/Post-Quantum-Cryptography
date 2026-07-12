# M0.1 Source, Standards, and Provenance Audit

## Scope

M0.1 establishes the first milestone as:

```text
M0: Standards, algorithm tracking, KAT, and independent golden models
```

No RTL, testbench, simulation script, imported C source, Python model, KAT parser, or comparison tool was modified during this audit.

## Workspace

Required workspace:

```text
/home/hien/Projects/Post_Quantum_Cryptography
```

Required branch:

```text
test
```

Frozen baseline:

```text
/home/hien/Projects/PQC_main
```

The baseline is read-only and was not modified.

## Standards inventory

| File | SHA-256 manifest | Classification | Use |
|---|---|---|---|
| `references/standards/NIST.FIPS.203.pdf` | `references/SHA256SUMS` | normative FIPS source | Primary ML-KEM source. |
| `references/standards/nist.fips.202.pdf` | `references/SHA256SUMS` | normative FIPS source | SHA3/SHAKE/Keccak dependency source. |
| `references/standards/nist.sp.800-185.pdf` | `references/SHA256SUMS` | supporting NIST source | Reserved source for SHA-3-derived functions if needed later. |
| `references/standards/kyber-specification-round3-20210804.pdf` | `references/SHA256SUMS` | supporting Kyber source | Legacy comparison only; not final ML-KEM authority. |

## FIPS 203 extraction anchors used for M0.1

| Topic | Source anchor |
|---|---|
| Cryptographic functions `PRF`, `H`, `J` | FIPS 203 Section 4.1, equations 4.2-4.4, PDF page 27 |
| Function `G` | FIPS 203 Section 4.1, equation 4.5, PDF page 28 |
| XOF wrapper | FIPS 203 Section 4.1, PDF pages 28-29 |
| Compression/decompression | FIPS 203 Section 4.2.1, equations 4.7-4.8, PDF page 30 |
| Byte encoding/decoding | FIPS 203 Algorithms 5-6, Section 4.2.1, PDF page 31 |
| Sampling | FIPS 203 Algorithms 7-8, Section 4.2.2, PDF page 32 |
| NTT/INTT | FIPS 203 Algorithms 9-10, Section 4.3, PDF page 35 |
| MultiplyNTTs/BaseCaseMultiply | FIPS 203 Algorithms 11-12, Section 4.3.1, PDF page 36 |
| K-PKE | FIPS 203 Algorithms 13-15, Sections 5.1-5.3, PDF pages 38-40 |
| Internal ML-KEM | FIPS 203 Algorithms 16-18, Sections 6.1-6.3, PDF pages 41-43 |
| ML-KEM parameter tables | FIPS 203 Tables 2-3, Section 8, PDF page 44 |
| FIPS/Kyber differences | FIPS 203 Appendix C, PDF pages 53-54 |

## Local C and KAT provenance

Local package:

```text
ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/
```

Classification:

```text
legacy reference
```

Local KATs:

```text
ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/KAT/
```

Classification:

```text
legacy Kyber regression vectors
```

The local KAT response files have 100 records per variant and are generated for Kyber package variants such as `Kyber768`. They are not final NIST CAVP/ACVP ML-KEM validation vectors.

## Local model/tool gaps

| Area | M0.1 status |
|---|---|
| Final NIST CAVP/ACVP ML-KEM vectors | Missing locally. Approved as future authoritative external vector source. |
| Project-owned KAT parser | Missing. Not implemented in M0.1. |
| Project-owned Python golden model | Missing. Not implemented in M0.1. |
| Project-owned C harness | Missing. Not implemented in M0.1. |
| Project-owned comparison tools | Missing. Not implemented in M0.1. |

## Unresolved FIPS/Kyber differences

The following differences must remain open until M0.2/M0.3 resolves them with exact evidence:

- FIPS 203 encapsulation shared-secret derivation differs from CRYSTALS-Kyber Round 3.
- FIPS 203 decapsulation implicit rejection differs from CRYSTALS-Kyber Round 3.
- FIPS 203 input checks for encapsulation keys, decapsulation keys, and ciphertexts must be tracked separately from legacy Kyber C behavior.
- FIPS 203 domain separation in K-PKE key generation must be checked against local legacy C candidates.
- Local Kyber 2020 `.rsp` vectors are legacy regression vectors, not final ML-KEM validation vectors.

## M0.1 result

M0.1 source/provenance audit is complete when the modified files pass:

```sh
git diff --check
git status --short
sha256sum -c references/SHA256SUMS
```

This report does not claim FIPS compliance, KAT validation, C/Python equivalence, RTL correctness, synthesis success, or timing success.
