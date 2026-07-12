# Kyber768 Legacy KAT Provenance Manifest

## Classification

These vectors are **legacy Kyber 2020 regression vectors** from the local
`NIST-PQ-Submission-Kyber-20201001` package.

They are **not** final FIPS 203 ML-KEM validation vectors and must not be used
as proof of FIPS 203 compliance.

## Source files

| File | SHA-256 | Classification |
|---|---|---|
| `ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/KAT/kyber768/PQCkemKAT_2400.req` | `36c27b6089b8910733a01fea1136469769b3ca3c35f2b375cfcc592f2112cfaa` | Legacy Kyber 2020 request vectors. |
| `ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/KAT/kyber768/PQCkemKAT_2400.rsp` | `a1e122cad3c24bc51622e4c242d8b8acbcd3f618fee4220400605ca8f9ea02c2` | Legacy Kyber 2020 response vectors. |

## Expected profile

| Field | Expected value |
|---|---:|
| Variant | Kyber768, non-90s |
| Records | 100 |
| `seed` length | 48 bytes |
| `pk` length | 1184 bytes |
| `sk` length | 2400 bytes |
| `ct` length | 1088 bytes |
| `ss` length | 32 bytes |

## Reproducibility rule

The imported source tree is read-only for project work:

```text
ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/
```

M0.3 builds copy the Kyber768 reference source into the ignored directory:

```text
ref_model/c_ref/build/kyber768_ref/
```

Generated binaries, logs, `.req`, and `.rsp` files remain under
`ref_model/c_ref/build/` and are not tracked.

## Validation command

```sh
bash ref_model/c_ref/run_kyber768_kat.sh
```

The command must:

1. copy the local Kyber768 2020 reference implementation into the ignored build
   directory;
2. build `PQCgenKAT_kem` from the copy;
3. run `PQCgenKAT_kem` from the copy;
4. compare generated `.req` and `.rsp` files exactly against the local legacy
   KAT files;
5. parse all 100 records strictly with
   `ref_model/kat/parse_legacy_kyber_kat.py`;
6. leave the imported C source tree unchanged.
