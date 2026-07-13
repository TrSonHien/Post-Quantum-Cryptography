# M7.6 Unified Regression Report

Command:

```sh
timeout 9000s ./sim/scripts/run_m7_regression.sh
```

Result:

```text
M7_REGRESSION_STATUS=PASS
TESTS_RUN=13
TESTS_PASSED=13
TESTS_FAILED=0
INTERNAL_CHECKS=6102998
BYTE_COMPARISONS=150564
COEFFICIENT_COMPARISONS=324096
ELAPSED_SECONDS=1116
```

The 13 programs are matrix-row sampling, noise-vector sampling, standalone
KeyGen, Encrypt, Decrypt, actual-RTL chained roundtrip, protocol/reset stress,
deterministic vector regeneration, full M6, full M5, full M4, full M3, and the
independent Python suite. Program count is separate from internal comparisons.
Every runner uses a temporary build directory, cleanup trap, TB watchdog, and
hard timeout; no waveform is produced by default.

M6 remains 16/16 and 2,467,232 checks; M5 remains 21/21 and 1,802,376; M4
remains 33/33 and 996,965; M3 remains 22/22 and 361,656. M2 and model/schema
adjacency remain covered by the nested lower regressions. No synthesis, area,
timing-closure, or Fmax claim is made; M2.3b remains pending.
