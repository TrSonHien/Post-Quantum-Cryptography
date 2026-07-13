# M7.3 Deterministic K-PKE.Encrypt Report

`timeout 1200s ./sim/scripts/run_kpke_encrypt.sh` PASS for 20 independent
Python vectors.  The test compares decoded `t_hat`, rho, y/e1/e2, y_hat, u,
v, and every ciphertext byte: 92,160 coefficient and 22,400 byte comparisons.
Keys come from independent Python KeyGen; messages include zero, all-ff,
alternating, sequential, and deterministic random values; r includes zero,
all-ff, and deterministic random values.

Per-vector counters prove nine transpose-row SampleNTT operations, seven noise
samples with nonces 0..6, one polyvec NTT, four dot products, four polynomial
INTTs, five canonical additions, and one message conversion.  The matrix helper
uses `(index0,index1)=(output_row,matrix_element)` for all u branches.
Command-to-done is 54,533--54,832 cycles under deterministic stalls.  Output
backpressure stability and final accepted completion pass.  Noncanonical d12
metadata is informational by contract.  No CAVP/ACVP, synthesis, area, timing,
or Fmax claim is made.
