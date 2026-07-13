# M5 Completion Report

## Status and audit

M5.0 through M5.6 are complete. The audit found no existing Keccak RTL in the
development or frozen baseline; imported Kyber C is supporting reference only.
State is frozen as 25 little-endian 64-bit lanes at index `x+5*y`, with stream
byte `b` at state bits `[8*b +:8]`. The dedicated proof passes all 200 bytes,
1,600 walking bits, 25 lanes, rate/capacity exclusion, and round-trip packing.

## Architecture and verification

One combinational round and one iterative 1600-bit permutation register execute
24 sequential rounds. Start-to-done is 24 rising-edge intervals. Round testing
passes 2,072 complete states plus 24 theta/rho/pi/chi/iota traces; permutation
testing passes 132 states and reset cancellation at all rounds.

The byte-serial context supports all four FIPS modes, arbitrary incremental
absorb boundaries, exact suffix/final-bit padding, full-block ownership, fixed
SHA3 output, and continuing multi-block SHAKE output. Direct and one-shot tests
each pass 320 vectors and 21,174 bytes. SHA3-256/512 pass 80 vectors and
2,560/5,120 bytes; SHAKE128/256 pass 80 and 6,747 bytes each. Incremental
testing uses 3,601 squeeze requests. Empty, exact-rate, and multi-rate cases,
backpressure, protocol errors, reset, and restart pass.

H/G/J pass 80 vectors each (2,560/5,120/2,560 bytes). PRF passes 128 vectors,
8,192 eta2 and 12,288 eta3 bytes. XOF passes 64 vectors, 5,561 bytes, and 1,155
requests. Sources are independent Python `hashlib` outputs and a separately
written pure-Python FIPS round/sponge model cross-checked against `hashlib`.
All three generators reproduce byte-identically in two directories.

## Measured cycles and resources

Permutation latency is 24. No-stall command-to-first/total cycles include:
SHA3-256 empty 35/70, SHA3-256 136-byte 231/266; SHA3-512 empty 35/110,
72-byte 151/226; SHAKE128 empty-to-168 35/240 and empty-to-169 35/267;
SHAKE256 33-to-32 77/112. PRF eta2 is 78/233 and eta3 78/338. XOF init to
active is 73; subsequent 3/168/171-byte request first/total values are 4/4,
5/236, and 5/240. These are simulation edge counts, not time or throughput.

Structurally each instantiated context contains one 1600-bit permutation state,
one combinational round, 24 sequential rounds, one 1600-bit sponge state, and
registered output staging. These are RTL facts, not synthesized area.

## Closure and limitations

The final unified regression passes 21/21 programs, 1,802,376 declared checks,
76,370 digest-byte comparisons, and 2,204 permutation-state comparisons. It
includes full M4 (33/33, 996,965) and M3 (22/22, 361,656) regressions plus M2
and Python/schema adjacency. Reset/backpressure and padding/suffix proofs pass.

M2.3b server synthesis and M5 focused synthesis are pending. There is no area,
timing-closure, or Fmax claim. No sampler, codec, K-PKE, KEM, cSHAKE, KMAC, or
M6 functional RTL is implemented. Final ML-KEM CAVP/ACVP validation remains
pending. The frozen M6 handoff defines the only permitted downstream contract.
