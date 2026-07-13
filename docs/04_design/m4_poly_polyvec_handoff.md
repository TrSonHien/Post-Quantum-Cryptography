# M4 Polynomial/Polyvec Handoff

## Scope

This is the integration contract for future M4 control and adapters. It does
not implement polynomial or polyvec RTL.

## Operations and domains

- `poly_ntt`: canonical normal-domain polynomial to canonical NTT-domain
  `polynomial_hat` through `ntt_core_pipe`.
- `polyvec_ntt`: apply `poly_ntt` independently to three polynomials for
  ML-KEM-768.
- `poly_invntt`: canonical NTT-domain polynomial to scaled canonical
  normal-domain polynomial through `intt_core_pipe`.
- Accumulated pointwise products remain in their explicitly documented
  NTT/product domain until inverse conversion. M4 must define the basemul and
  accumulator representation before connecting that path.

One polynomial contains 256 coefficients. One ML-KEM-768 polyvec contains
three polynomials.

## Ownership and sequencing

The baseline uses one reusable NTT engine unless a later architecture decision
duplicates it. For a polyvec, process element 0, then 1, then 2. For each
polynomial the M4 controller must:

1. obtain engine ownership while idle;
2. preload all 256 logical coefficients;
3. issue one `start`;
4. retain ownership and wait for `done`;
5. request and store all 256 logical results;
6. release or reuse the engine only after final readback.

No caller may mutate internal banks or preload/read while `busy`. Unread result
ownership must not be overwritten by a new operation unless the M4 controller
explicitly discards it.

## Required M4 adapters and metadata

- polynomial load adapter using logical indices;
- polynomial result-store adapter honoring one-cycle result latency;
- operation controller for preload/compute/readback phases;
- domain metadata distinguishing normal, NTT, and pointwise-product data;
- polyvec element index `0..2`;
- basemul/accumulate integration with a separately proven domain contract;
- error propagation and result-valid/overwrite tracking.

The coefficient interface is not a full streaming valid/ready protocol. The
current engine accepts an operation only while idle, so M4 must serialize load,
compute, and readback. A DMA or streaming adapter is separate future work.

## Error contract

M4 must capture NTT/INTT sticky `error` and additionally reject invalid domain
requests, start while busy, incomplete preload, and overwrite of unread
results. Recovery requires synchronous reset followed by a complete clean
preload; memory data left by a cancelled operation is invalid.

## Cycle-only estimates

Compute-only measured durations are 955 cycles for one forward polynomial and
1,090 cycles for one inverse polynomial including scaling. Three sequential
forward polynomials require 2,865 compute cycles; three sequential inverse
polynomials require 3,270 compute cycles. These figures exclude M4 control and
transfer overhead.

A serialized operation additionally needs at least 256 preload cycles and 256
result requests plus the final one-cycle response. Thus a minimal single-core
wrapper must budget these boundary transfers separately. No clock-frequency,
time, or operations-per-second estimate is frozen.

## Entry requirements

M4 may begin after the M3 unified regression passes, this engine contract is
frozen, canonical domains are tracked, and no memory/reset/control issue is
open. M2.3b may remain pending but must stay visible as the synthesis dependency.
