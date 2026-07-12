# M0.3 Legacy Kyber768 C and KAT Harness Report

## Scope

M0.3 builds and runs the local Kyber768 2020 reference implementation and
checks its generated KAT files against the local legacy Kyber768 KAT package.

This report does not claim FIPS 203 ML-KEM validation.

## Classification

The local Kyber768 KATs are classified as:

```text
legacy Kyber 2020 regression vectors
```

They are not final NIST CAVP/ACVP ML-KEM vectors.

## Source and generated-output policy

Imported source package:

```text
ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/
```

Generated-output directory:

```text
ref_model/c_ref/build/
```

The imported source package must remain unchanged. The build script copies the
selected Kyber768 reference implementation to:

```text
ref_model/c_ref/build/kyber768_ref/
```

and builds/runs `PQCgenKAT_kem` there.

## Implemented M0.3 artifacts

| File | Purpose |
|---|---|
| `ref_model/c_ref/run_kyber768_kat.sh` | Reproducible copy/build/run/compare harness for legacy Kyber768. |
| `ref_model/kat/parse_legacy_kyber_kat.py` | Strict parser for Kyber768 `.req` and `.rsp` records. |
| `ref_model/kat/kyber768_legacy_provenance.md` | Provenance manifest and legacy-vector classification. |

## Checks performed by the harness

The harness must pass all of the following:

1. Build copied Kyber768 reference code under `ref_model/c_ref/build/`.
2. Run copied `PQCgenKAT_kem`.
3. Compare generated `PQCkemKAT_2400.req` exactly against the local legacy
   request file.
4. Compare generated `PQCkemKAT_2400.rsp` exactly against the local legacy
   response file.
5. Parse 100 request records and 100 response records.
6. Validate sequential `count` fields and matching request/response `seed`
   fields.
7. Validate field presence and byte lengths for `seed`, `pk`, `sk`, `ct`, and
   `ss`.

## Commands

```sh
bash ref_model/c_ref/run_kyber768_kat.sh
python3 ref_model/kat/parse_legacy_kyber_kat.py \
  --expect kyber768-2020 \
  --req ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/KAT/kyber768/PQCkemKAT_2400.req \
  --rsp ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/KAT/kyber768/PQCkemKAT_2400.rsp
git diff --check
git status --short -- ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001
```

## Result

PASS.

Observed output from `bash ref_model/c_ref/run_kyber768_kat.sh`:

```text
legacy_profile=kyber768-2020
classification=legacy Kyber 2020 regression vectors; not FIPS 203 ML-KEM validation
exact_req_compare=PASS
exact_rsp_compare=PASS
parser_check=PASS
```

Observed output from the standalone parser check:

```text
legacy_profile=kyber768-2020
classification=legacy Kyber 2020 regression vectors; not FIPS 203 ML-KEM validation
req_records=100
rsp_records=100
fields=count,seed,pk,sk,ct,ss
status=PASS
```

Observed SHA-256 equality between local legacy KATs and regenerated files:

| File class | SHA-256 |
|---|---|
| local/generated `.req` | `36c27b6089b8910733a01fea1136469769b3ca3c35f2b375cfcc592f2112cfaa` |
| local/generated `.rsp` | `a1e122cad3c24bc51622e4c242d8b8acbcd3f618fee4220400605ca8f9ea02c2` |

Imported-tree check:

```sh
git status --short -- ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001
git diff -- ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001
```

Both commands produced no output during the M0.3 validation run.

Final hygiene checks:

```text
git diff --check: PASS
git check-ignore ref_model/c_ref/build/...: PASS
disallowed implementation path status check: PASS
```

## Remaining limitations

- These vectors remain legacy Kyber 2020 regression vectors.
- Final NIST CAVP/ACVP ML-KEM vectors are still missing locally.
- No Python model, comparison tool, RTL, testbench, or simulation artifact was
  implemented in M0.3.
