# M6.3 Integrated Noise Sampler Report

The integrated sampler passes 128 hashlib/Python vectors: 64 eta2 and 64 eta3,
with 32,768 coefficient comparisons. It reuses `mlkem_prf`, connects its
ready/valid byte stream directly to CBD, and emits exactly 256 canonical NORMAL
coefficients. Seed and nonce order are exact; eta selects output length only.
The measured aggregate no-stall average is 385 cycles across the balanced eta
set; deterministic output stalls raise the focused average to 426. Stalled
coefficient/index signals remain stable. A mid-PRF reset cancels all validity,
and replay after reset compares all 256 coefficients. PRF/CBD errors propagate
and the parent remains busy through the final accepted coefficient. No SHAKE
logic is duplicated.
