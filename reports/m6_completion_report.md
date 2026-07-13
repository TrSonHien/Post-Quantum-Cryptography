# M6 Completion Report

## Status and architecture

M6.0 through M6.6 are complete. The audit found no pre-existing codec/sampler
RTL. FIPS byte order is increasing-address with LSB-first bits and low-byte-first
32-bit streams. Raw d-bit codes remain distinct from NORMAL/NTT polynomial
domains. ByteEncode/Decode use bounded 64-bit reservoirs; d12 decoding reduces
modulo q while retaining informational noncanonical evidence.

Compression uses reciprocal 5039 at shift 24 and one exact correction;
decompression is multiply/add/shift. Both are latency two, II one. Exhaustive
checks cover 9,987 compression and 1,042 decompression inputs, including the
roundtrip property. D1/d4/d10/d12 packers compare 58,752 bytes and 69,888
decoded values. Message, polynomial, K=3 polyvec, and encoded key/ciphertext
formats preserve exact FIPS order and lengths.

## Sampling verification

CBD pair testing exhausts 4,352 groups and 8,704 coefficients. Complete eta2
and eta3 tests each use 128 polynomials/32,768 coefficients; outputs are
canonical NORMAL. The PRF noise sampler passes 64 eta2 and 64 eta3 vectors,
32,768 coefficients, and averages 385 no-stall cycles across the balanced set.
Eta controls length only and nonce is the final absorbed byte.

The parser passes eight synthetic rejection streams/2,048 coefficients.
Integrated SampleNTT passes 64 polynomials/16,384 coefficients, using 148--169
groups (integer average 157) and 1124--1256 cycles (integer average 1172).
Every three-byte request continues one SHAKE128 context. No functional
iteration bound exists; only verification watchdogs are bounded.

## Closure and limitations

Unified regression passes 16/16, 2,467,232 checks, 276,992 byte comparisons,
and 376,576 coefficient comparisons in 164 seconds. Deterministic regeneration,
codec and integrated-sampler backpressure, stalled output stability,
mid-PRF/mid-XOF reset cancellation and restart, canonical ranges, exact padding
dependencies, and previous M2--M5 preservation gates pass.

M7 K-PKE and later KEM control are not implemented. Encoded format adapters
compose with coefficient codecs; they do no K-PKE arithmetic. Final CAVP/ACVP,
M2.3b server synthesis, and focused M5/M6 synthesis remain pending. There is no
synthesis, area, timing-closure, or Fmax claim.

M7 entry criteria are satisfied: Algorithms 3--8, rounding, d12 evidence,
formats, eta2/eta3 CBD, integrated noise, continuing-XOF SampleNTT, unified
regression, reproducibility, and handoff contracts are frozen. M7 is entry-ready
but not started.
