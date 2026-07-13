# M5 to M6 Sampler/Codec Handoff

## Entry state

M5 provides verified byte-stream SHA3/SHAKE primitives and ML-KEM H/G/J/PRF/
XOF wrappers. M5 does not implement rejection sampling, CBD, codecs,
compression, decompression, K-PKE, or KEM control.

## SampleNTT-facing XOF

`mlkem_xof` owns an incremental SHAKE128 context. Its convenience init absorbs
exactly `seed[0..31] || index0 || index1`; the generic input is the same 34
bytes packed with the earliest byte in bits `[7:0]`. M5 assigns no row/column
meaning to the two indices. M6 supplies the FIPS-required caller order.

After context-valid, any positive squeeze length is legal. Three-byte requests
are explicitly verified. Repeated requests continue at the next byte, including
across the 168-byte rate boundary; M6 must not reinitialize between SampleNTT
rejection batches. Ready/valid and output keep/last must be honored. M5 does
not parse 12-bit candidates and does not perform rejection sampling.

## CBD-facing PRF

`mlkem_prf` accepts a complete 32-byte seed, one nonce byte, and eta 2 or 3.
It absorbs exactly `seed||nonce`. Eta is never absorbed and controls only the
output length: 128 bytes for eta2, 192 for eta3. Earliest output is
`out_data[7:0]`; the final partial/full beat is marked by keep/last. Output is
stable under backpressure. M5 performs no CBD bit counting or coefficient
conversion.

## Codec/KEM-facing hashes

`mlkem_h`, `mlkem_g`, and `mlkem_j` use bounded byte streams. H emits exactly
32 SHA3-256 bytes. G emits 64 SHA3-512 bytes, with bytes 0..31 first and bytes
32..63 second, never reversed. J emits exactly 32 SHAKE256 bytes and is not
interchangeable with H. M5 does no message/key/ciphertext encoding or decoding.

## Prohibited M6 assumptions

- Do not access or depend on internal Keccak state, lane layout, or core FSM.
- Do not assume zero permutation latency or absorb-ready during permutation.
- Honor every input ready and output valid/ready transfer.
- Do not restart XOF between incremental squeeze calls.
- Do not reverse seed, index, digest, or G-half byte order.
- Do not treat eta as PRF absorbed data.
- Do not substitute cSHAKE, KMAC, AES/SHA2, or another suffix.
- After reset, do not consume output or issue squeeze without a fresh init.
- Do not infer sampler or codec completion from M5 hash-wrapper completion.

## M6 entry criteria

M6 may start only from the clean M5.6 checkpoint with the unified regression,
mapping, suffix/padding, differential SHA3/SHAKE, continuing squeeze,
H/G/J/PRF/XOF, reset/backpressure, and deterministic regeneration gates PASS.
M2.3b synthesis remains independently pending.
