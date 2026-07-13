# M5.6 Unified Regression Report

Command:

```text
timeout 2400s ./sim/scripts/run_m5_regression.sh
```

Final result:

```text
M5_REGRESSION_STATUS=PASS
TESTS_RUN=21
TESTS_PASSED=21
TESTS_FAILED=0
INTERNAL_CHECKS=1802376
DIGEST_BYTE_COMPARISONS=76370
PERMUTATION_STATE_COMPARISONS=2204
```

The 21 programs are the 14 required M5 functional/reproducibility gates, cycle
accounting, full M4 and M3 unified preservation, M2 memory and arithmetic
adjacency, and independent Python/schema checks. Every runner has a hard
timeout and trapped temporary build directory; the parent is fail-fast and
prints a machine-readable summary. The final source tree has no generated
binary, waveform, log, cache, or stale simulation process.
