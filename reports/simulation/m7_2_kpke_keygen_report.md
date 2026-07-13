# M7.2 Deterministic K-PKE.KeyGen Report

Command:

```sh
timeout 900s ./sim/scripts/run_kpke_keygen.sh
```

Result: PASS for 20 complete independent Python vectors.  Inputs include zero,
all-ff, sequential, alternating, and 16 deterministic random d values.  The TB
compares rho, sigma, all s/e/s_hat/e_hat/t_hat coefficients, all 1184 ekPKE
bytes, and all 1152 dkPKE bytes.  Totals are 76,800 intermediate coefficient
comparisons and 48,000 byte comparisons including 1,280 G-output bytes.

The controller hashes exactly 33 bytes `d||03`.  Counters prove one G, nine
SampleNTT, six noise samples using nonces 0..5, two K=3 NTTs, three NTT dot
products, and three NTT additions per vector.  Matrix ordering is independently
covered by the M7.1 sampler test.  Command-to-done cycles under deterministic
output stalls range from 46,486 to 46,787 in this set; the last vector is
46,486 cycles.  Output stalls preserve data/type/last and done follows the
accepted final dkPKE word.

The first integration run exposed a controller response-mux error at polyvec
coefficient 255: advancing `result_poly_idx` before the synchronous response
selected the next workspace.  The correction holds the poly index through an
explicit per-polynomial drain state.  No M4 RTL or semantics changed.

This is independent project-Python differential evidence, not final
authoritative CAVP/ACVP validation.  No synthesis, area, timing, or Fmax claim
is made.
