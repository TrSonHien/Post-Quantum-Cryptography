# M6 to M7 K-PKE Handoff

## Entry state

M6 provides verified FIPS 203 Algorithms 3--8, canonical codec adapters,
message/poly/polyvec conversion, encoded K-PKE format boundaries, CBD noise,
and continuing-XOF SampleNTT. M7 owns all K-PKE arithmetic and scheduling.

## Matrix sampling

M7 supplies exactly `rho||index0||index1`. M6 returns one complete canonical
NTT-domain polynomial. M6 assigns no row/column, transpose, KeyGen, or Encrypt
meaning; M7 must supply the FIPS-required order. The XOF is initialized once
and continues across every three-byte request. SampleNTT has no fixed cycle or
rejection bound.

## Noise and message conversion

M7 supplies a 32-byte seed, explicit nonce, and eta. M6 returns one canonical
NORMAL polynomial. M7 owns nonce sequence, vector assignment, and eta1/eta2
selection. Eta is never absorbed. Message conversion accepts exactly 32 bytes;
message-to-poly returns NORMAL and poly-to-message emits exactly 32 bytes.

## Key and ciphertext formats

The verified segment codecs produce d12 NTT polyvec bytes, d10 compressed
NORMAL polyvec bytes, and d4 compressed NORMAL polynomial bytes. Registered
format adapters enforce `ekPKE=d12(t_hat[0..2])||rho` (1184 bytes),
`dkPKE=d12(s_hat[0..2])` (1152 bytes), and `c=d10(u[0..2])||d4(v)` (1088
bytes). Unpack preserves element order and exposes d12 noncanonical evidence.
M6 does not perform final ML-KEM input checking.

## Prohibited M7 assumptions

- Do not infer NORMAL or NTT semantics from encoded bytes.
- Do not ignore ByteDecode12 noncanonical evidence.
- Do not reverse polyvec, rho, seed, nonce, or index order.
- Do not restart XOF during SampleNTT or assume bounded rejection/cycles.
- Explicitly manage every noise nonce; do not absorb eta into PRF input.
- Honor busy/ready/valid, output stalls, and final committed completion.
- Do not access internal codec reservoirs, Keccak state, or sampler queues.
- Do not call M6 K-PKE arithmetic; none exists. M7 is not started by this handoff.
