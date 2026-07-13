# M7.4 Deterministic K-PKE.Decrypt Report

`timeout 900s ./sim/scripts/run_kpke_decrypt.sh` PASS for 20 independent
Python `(dkPKE,c)` vectors.  The test compares decoded/decompressed u and v,
decoded s_hat, u_hat, inverse-transformed product, w, and every recovered
message byte: 61,440 coefficient and 640 byte comparisons.

Per-vector counters prove one polyvec NTT, one NTT dot product, one polynomial
INTT, one canonical subtraction, and one poly-to-message conversion.  The
measured command-to-done result is 17,755 or 17,756 cycles under deterministic
output stalls.  Output stability and final accepted completion pass.

An initial full-vector run exposed only a generator serialization defect: the
nonsymmetric recovered message was written as big textual hex while the TB
consumed a little-endian packed word.  Correcting the temporary-vector writer
made all vectors pass without an RTL change.  D12 noncanonical evidence remains
informational by contract.  No CAVP/ACVP, synthesis, area, timing, or Fmax claim
is made.
