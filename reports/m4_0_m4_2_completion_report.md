# M4.0-M4.2 Completion Report

## Completed scope

- M4.0 freezes NORMAL, NTT, reserved POINTWISE, and INVALID domains; explicit
  ownership; indexed interfaces; and one-engine serialized polyvec baseline.
- M4.1 implements synchronous two-bank workspace and two-lane canonical add,
  subtract, and unsigned 32-bit reduction controllers.
- M4.2 implements logical-interface forward and scaled-inverse M3 adapters.

The existing asynchronous `poly_buffer` and legacy polynomial controllers are
retained for adjacency but are not the M4 workspace. M2 arithmetic leaves and
M3 cores remain semantically unchanged. No caller accesses physical NTT banks.

## Results

| Block | Vectors/checks | Comparisons | Cycles | Result |
|---|---:|---:|---:|---|
| Workspace | 524 checks | all 256 indices twice | n/a | PASS |
| Add | 32 vectors | 8192 | 132 | PASS |
| Subtract | 32 vectors | 8192 | 132 | PASS |
| Reduce | 32 vectors | 8192 | 134 | PASS |
| Forward adapter | 32 vectors | 8192 | 1473 | PASS |
| Inverse adapter | 32 vectors | 8192 | 1608 | PASS |
| Adapter roundtrip | 30 vectors | 7680 forward + 7680 final | 1473/1608 | PASS |

Domains are mandatory metadata. Add/sub preserve matching NORMAL or NTT;
reduce preserves valid semantic domain; forward maps NORMAL to NTT; inverse
maps NTT to canonical NORMAL after the M3 scaler. Reset, completeness,
ownership, mismatch, busy access, overwrite, pending-valid cancellation, and
restart checks pass.

## Unified regression

`timeout 360s ./sim/scripts/run_m4_0_m4_2_regression.sh` passed 19/19 programs,
741497 internal checks, in 45 seconds. It includes every new M4 test, exact
vector regeneration, M3 unified regression, repeated M2 memory/arithmetic,
legacy polynomial/basemul adjacency, and Python model/schema tests. Each program
has a hard timeout and runs in a trapped temporary source copy.

M4.3 pointwise/basemul orchestration and polyvec accumulation remain pending.
M2.3b server synthesis remains pending. No synthesis timing or Fmax claim is
made, and M4 overall is not complete.
