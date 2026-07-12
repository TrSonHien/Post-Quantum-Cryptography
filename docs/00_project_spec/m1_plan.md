# M1 Plan: Architecture Freeze v0.1

## Purpose

M1 freezes the interface, representation, reset, timing, pipeline-metadata, and
memory contracts required before new RTL implementation. M1 is documentation
only and does not redesign or validate the legacy RTL.

## Approved baseline

- architectural coefficients are canonical unsigned integers in `[0,q-1]`;
- NTT-domain objects use explicit `*_hat` naming and metadata;
- Montgomery representation is private to documented multiplier internals;
- engines use `valid/ready`; fixed-latency internal lanes may use valid-only;
- internal `rst_n` is synchronous active-low;
- memories and payload registers are not reset;
- NTT/INTT accept one butterfly per cycle at II=1;
- polynomial storage is out-of-place ping-pong synchronous memory with a
  one-cycle read latency and two source plus two destination banks;
- illegal collisions are never used; completion follows the committed final write;
- multi-lane NTT variants are deferred to M3.

## Deliverables and gates

1. Interface, representation/domain, reset/control, memory, and pipeline
   contracts are explicit and mutually consistent.
2. NTT/INTT cycle and bandwidth tables are recorded.
3. The two-bank-per-side mapping is proven conflict-free for every stage.
4. `mlkem-vector-v1` fields are mapped to future RTL transactions.
5. Required assertions and verification gates are documented.
6. The architecture-freeze report lists legacy mismatches and deferred work.

## Exclusions

No RTL, testbench, simulation-script, or reference-model changes are part of
M1. M2 must not begin without explicit approval.

## Completion criteria

M1 is complete when all approved decisions above are documented, the banking
proof covers all forward and inverse stages, cycle/bandwidth accounting is
closed, verification obligations are defined, documentation passes
`git diff --check`, and the existing `poly_sub` status discrepancy is resolved
from a live regression.
