# Source Provenance and Classification

## Purpose

This file records the status of local standards, supporting specifications, legacy reference code, and local KAT material used by the ML-KEM-768 project.

## Source priority

1. NIST FIPS 203 is the normative ML-KEM source.
2. NIST FIPS 202 is the normative SHA3/SHAKE/Keccak source.
3. NIST SP 800-185 is a supporting NIST source and is not currently required by the ML-KEM-768 core unless a later design uses a function from that recommendation.
4. Final NIST CAVP/ACVP ML-KEM vectors are the authoritative external test-vector source when obtained.
5. Kyber Round-3 material and the local Kyber 2020 package are legacy/supporting sources.

## Local standards

| File | Classification | Current use | Notes |
|---|---|---|---|
| `references/standards/NIST.FIPS.203.pdf` | Normative FIPS source | Primary ML-KEM algorithm source | PDF metadata: 56 pages; title `Module-Lattice-Based Key-Encapsulation Mechanism Standard`; modified 2024-08-22 minor corrections. |
| `references/standards/nist.fips.202.pdf` | Normative FIPS source | SHA3/SHAKE/Keccak dependency source | PDF metadata: 37 pages; defines SHA3-256, SHA3-512, SHAKE128, SHAKE256, and Keccak-p[1600,24]. |
| `references/standards/nist.sp.800-185.pdf` | Supporting NIST source | Reserved dependency source | Not currently a required ML-KEM-768 primitive; keep for SHA-3-derived function context. |
| `references/standards/kyber-specification-round3-20210804.pdf` | Supporting Kyber source | Legacy comparison and difference tracking | Not normative for final FIPS 203 ML-KEM. |

Hashes are recorded in `references/SHA256SUMS`.

## Local Kyber 2020 C package

Path:

```text
ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/
```

Classification:

```text
legacy reference
```

Reusable for M0:

- Kyber Round-3 algorithm structure;
- legacy Kyber768 parameter comparison;
- candidate C mappings for low-level polynomial, NTT, K-PKE, and KEM routines;
- local legacy KAT format examples;
- regression source for Kyber 2020 behavior.

Not automatically reusable as final FIPS 203 evidence:

- final ML-KEM KAT validation;
- final ML-KEM algorithm equivalence;
- CAVP/ACVP evidence;
- proof that the encapsulation/decapsulation derivations match FIPS 203;
- proof that byte encodings, domain separation, key checks, or implicit rejection behavior match final FIPS 203.

Generated-file rule:

Generated binaries and outputs must not be written into this imported source tree. Future generated files must use `ref_model/c_ref/build/` or a temporary directory.

## Local Kyber KAT files

Path:

```text
ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/KAT/
```

Classification:

```text
legacy Kyber regression vectors
```

The local `.rsp` files contain 100 records per variant and are labeled by the Kyber package, for example `# Kyber768`.

They must not be labeled final FIPS 203 validation vectors unless a later M0 task proves equivalence or replaces them with final NIST CAVP/ACVP ML-KEM vectors.

## Missing authoritative vector source

Final NIST CAVP/ACVP ML-KEM vectors are approved as the authoritative external test-vector source, but they are not present locally as of M0.1.

## Known FIPS/Kyber difference areas to track

FIPS 203 Appendix C identifies differences between CRYSTALS-Kyber and ML-KEM. M0 tracking must pay special attention to:

- encapsulation shared-secret derivation;
- decapsulation implicit-rejection derivation;
- input checks for encapsulation and decapsulation keys/ciphertexts;
- domain separation in K-PKE key generation;
- naming and parameter-set terminology;
- final validation vector provenance.
