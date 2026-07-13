# M4 Completion Report

## Status and architecture

M4.0 through M4.6 are complete. Architectural coefficients are canonical
unsigned residues while semantic metadata distinguishes INVALID, NORMAL, NTT,
and internal-reserved POINTWISE. Synchronous polynomial workspaces use even/
odd banks; K=3 polyvec storage composes three such workspaces. Memory payload
is not reset, while ownership, completeness, domains, and validity are.

M3 logical adapters remain unchanged and inaccessible at their physical-bank
boundary. One shared child serializes K=3 add/sub/reduce/NTT/INTT. Measured
cycles are 2731, 2731, 1963, 5980, and 6385 respectively.

## Exact multiplication

`mod_mul_normal_pipe` registers a full product and uses exact Barrett reduction:
latency 4, II=1. BaseCaseMultiply has latency 9, II=1, with five exact multiply
instances and two add lanes. ROM `gamma*R` is explicitly converted by
MontgomeryReduce with one, proving no extra `R` factor. Polynomial
MultiplyNTTs performs 128 requests/writes in 142 cycles with positive/negative
zetas 64..127.

The K=3 dot product shares one polynomial engine, performs three products and
two canonical accumulation passes, and completes in 2757 cycles: 384
BaseCaseMultiply requests, 384 product pair writes, and 512 accumulator writes.
Its public result is canonical NTT, never POINTWISE.

## Verification and handoff

Independent coverage includes 100000 exact products, 50000 BaseCaseMultiply
tuples, 32 polynomial products/8192 comparisons, 16 vectors and 12288
comparisons for each polyvec operation, 16 roundtrips with 24576 comparisons,
and 32 dot products/8192 comparisons. Reset, cancellation, restart, ownership,
completeness, domain, invalid index, busy access, and overwrite checks pass.

Unified regression passed 33/33 programs and 996965 declared checks in 103
seconds. The M4-to-K-PKE row contract is frozen, but K-PKE is not implemented.
M5 entry requires this PASS, clean worktree, canonical/domain contracts, no
Montgomery or memory collision ambiguity, verified K=3 behavior, and the frozen
handoff. M2.3b remains pending. No synthesis/Fmax or full ML-KEM KAT claim is
made.
