# M3.6 Unified Regression Report

## Checkpoint and tools

- Repository: `/home/hien/Projects/Post_Quantum_Cryptography`
- Branch: `test`
- Starting commit tested: `bff8143`
- Icarus Verilog: 13.0 stable (`v13_0-dirty`)
- VVP: 13.0 stable (`v13_0-dirty`)
- Python: 3.14.6
- Command: `timeout 180s ./sim/scripts/run_m3_regression.sh`
- Result: PASS, 22/22 test programs, 361656 internal checks, 21 seconds
- Per-simulation limits: 30-120 seconds inside the 180-second outer limit
- `DEBUG_WAVES=0`; no waveform was retained.

## Test-program matrix

| Program | Limit | Checks | Result |
|---|---:|---:|---|
| Layout proof | 30 s | 1800 | PASS |
| Forward scheduler | 30 s | 896 | PASS |
| Forward core | 45 s | 7168 | PASS |
| Inverse scheduler | 30 s | 896 | PASS |
| Inverse scaler | 30 s | 3336 | PASS |
| Inverse core | 60 s | 7936 | PASS |
| Pipelined NTT/INTT roundtrip | 60 s | 15360 | PASS |
| M2.1 primitives | 60 s | 5417 | PASS |
| M2.2 unified arithmetic | 120 s | 312935 | PASS |
| Legacy forward/inverse/roundtrip | 60 s each | 2304 | PASS |
| Poly add/sub | 60 s each | 2048 | PASS |
| Basemul/unit/address/poly | 60 s each | 1538 | PASS |
| Python selftest/foundations/schema | 30 s each | 19 | PASS |
| Smoke-vector compare | 30 s | 1 | PASS |
| Deterministic M3 regeneration | 30 s | 2 | PASS |

The script is fail-fast, preserves the first nonzero status, and prints one
machine-readable line per program plus:

```text
M3_REGRESSION_STATUS=PASS
TESTS_RUN=22
TESTS_PASSED=22
TESTS_FAILED=0
INTERNAL_CHECKS=361656
ELAPSED_SECONDS=21
```

## Differential and invariant evidence

- Forward differential: 28 polynomials, 7168 coefficient comparisons.
- Standalone inverse differential: 31 polynomials, 7936 comparisons.
- Roundtrip: 30 polynomials, 7680 Python forward-output comparisons and 7680
  final normal-domain comparisons.
- Forward structure: 896 reads/responses/butterfly inputs/outputs/pair writes,
  seven safe stage swaps, no pending traffic at done.
- Inverse stages: the same 896 transaction counts and seven safe stage swaps;
  no stage transaction enters scaling.
- Scaler: 128 pair reads, 256 coefficient inputs/outputs, 128 pair writes.
- Per-stage scoreboards prove 256 unique logical writes with no duplicates or
  omissions. Valid/metadata/write, pending-at-done, collision, zeta/index,
  reset cancellation, and clean restart checks pass.

## Deterministic vector audit

The forward and inverse generators identify schema, operation, canonical
unsigned representation, domains, `q=3329`, `N=256`, seeds/sources, vector IDs,
and input/output coefficient counts. Values are checked as Python integers in
`[0,3328]`; no JSON floats or host-order-dependent containers are used.

The unified runner generates forward, inverse, and roundtrip files twice into
separate temporary directories and compares exact bytes. Reproducibility PASS.
Generated files, simulator binaries, logs, and caches remain inside a temporary
tree that is removed by a trap on success, failure, or signal.

## Cycle accounting

Forward starts its first issue at cycle 3, issues 128 consecutive requests per
stage, has eight no-issue cycles between issue windows, and asserts done at
cycle 955. Issue utilization is `896/955 = 93.82%`; control/drain overhead over
896 ideal issue cycles is 59 cycles.

Inverse butterfly stages take 954 cycles with the same issue windows and eight
cycle inter-stage gaps. Utilization is `896/954 = 93.92%`; overhead is 58
cycles. Scaling issues cycles 955-1082, commits the final write at 1088, swaps
ownership at 1089, and asserts public done at 1090. Scaler utilization through
ownership is `128/135 = 94.81%` (`128/136 = 94.12%` through public done).

Butterfly issue-to-write latency is seven cycles in both directions. Scaler
issue-to-write latency is six cycles. Each active issue processes two
coefficients. Serialized preload and readback are excluded from compute cycles;
result read latency is one cycle with II=1.

## Quality gates

`git diff --check` PASS. No stale simulator process, VCD/FST, tracked simulator
binary, temporary vector, Python cache, or unexpected source artifact remained.
The frozen `PQC_main` worktree was not modified. M2.3b server synthesis remains
pending. No synthesis timing, Fmax, post-route, or full ML-KEM KAT claim is
made.
