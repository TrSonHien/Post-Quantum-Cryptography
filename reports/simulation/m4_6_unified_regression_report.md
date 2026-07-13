# M4.6 Unified Regression Report

## Environment and command

Tested source snapshot: `2799fd3` plus the reviewed M4.6 regression/report
changes. Tools: Icarus Verilog/vvp 13.0 stable (`v13_0-dirty`) and Python
3.14.6. Exact command:

```text
timeout 900s ./sim/scripts/run_m4_regression.sh
```

The runner copies sources to a trapped temporary directory, applies a hard
timeout to every program, fails fast with nonzero status, and leaves no binary,
log, vector, or waveform in the source tree. `DEBUG_WAVES` defaults to zero.

## Result

```text
M4_REGRESSION_STATUS=PASS
TESTS_RUN=33
TESTS_PASSED=33
TESTS_FAILED=0
INTERNAL_CHECKS=996965
ELAPSED_SECONDS=103
```

The matrix covers exact multiply (100000), BaseCaseMultiply (50000), polynomial
MultiplyNTTs, K=3 workspace and five elementwise operations, polyvec transform
roundtrip, polyvec dot product, all M4.0-M4.2 tests, M3 unified (22/22), M2
memory/arithmetic, legacy polynomial/basemul/NTT adjacency, Python model/schema,
and byte-identical regeneration of all four M4 generators. Coefficient checks
are not counted as programs. Structural request/write counts, domain/reset/
restart checks, and all minimum vector counts pass. No stale process or
unexpected artifact remained; final `git diff --check` is recorded at commit.
