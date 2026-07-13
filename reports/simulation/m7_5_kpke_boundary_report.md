# M7.5 K-PKE Primitive-Boundary Report

Command: `sim/scripts/run_kpke_boundary.sh`

Result: PASS, three transactions and 1,152 exact output-byte comparisons.

- Encrypt decoded an ekPKE whose first d12 segment was 4095, asserted
  `noncanonical_seen`, did not assert `error`, and matched Python ciphertext.
- Decrypt decoded a dkPKE whose first d12 segment was 4095, asserted
  `noncanonical_seen`, did not assert `error`, and matched Python message bytes.
- Decrypt accepted 1,088 deterministic arbitrary ciphertext bytes with a
  canonical dkPKE and matched Python message bytes.

This is primitive K-PKE evidence only. It is not an M8 ML-KEM public-key or
ciphertext input-check claim.
