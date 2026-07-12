# M0.5 Comparison Tools and Vector Export

## Result

M0.5 implements a deterministic, strict vector path from the independent
ML-KEM-768 Python model to future RTL testbenches and comparison scripts.

## Schema and representation

`mlkem-vector-v1` is a JSON document with exactly `schema`, `metadata`, and
`vectors`. Metadata includes ML-KEM-768 parameters, source, 32-byte generation
seed, exact generation command, byte order, and coefficient/domain convention.
Each vector has exactly `id`, `category`, `operation`, `inputs`, and `expected`.

Bytes are lower-case hex in increasing address order. FIPS `ByteEncode` bit
packing is least-significant-bit first. Coefficients are canonical unsigned
integers in `[0,3328]`; normal-domain data is used unless a field is explicitly
named as NTT-domain (`*_hat`).

## Coverage

The curated smoke set covers `Compress`/`Decompress`, `ByteEncode`/`ByteDecode`,
NTT/INTT, `MultiplyNTTs`, `SampleNTT`, `SamplePolyCBD_eta2`, deterministic
K-PKE key generation/encryption/decryption, and deterministic internal ML-KEM
key generation/encapsulation/decapsulation including modified-ciphertext fallback.

## Strictness and storage

The loader rejects wrong root/metadata/case keys, unsupported schema or
category, duplicate IDs, malformed seed metadata, and invalid structural types.
The comparator recursively reports the first type, key, length, or value
mismatch with an exact path. Bulk output is ignored under
`ref_model/compare/generated/`; only the small curated smoke set is tracked.

## Validation boundary

Regeneration matches the curated file exactly, and unit tests cover export,
reload, malformed-input rejection, and mismatch diagnostics. These vectors are
derived from the independent Python oracle. Final NIST CAVP/ACVP ML-KEM vectors
are not present, so no authoritative KAT validation is claimed.
