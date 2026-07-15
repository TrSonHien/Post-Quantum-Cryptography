# M5 Keccak Service Zeroization Report

Date: 2026-07-16

The Keccak permutation, sponge context, fixed-output SHA3-256/SHA3-512 and
SHAKE256 stream wrappers, and ML-KEM H/G/J services implement the frozen
`zeroize_req`, `zeroize_busy`, `zeroize_done` protocol. H/G/J suppress normal
command, input, output, done, and error visibility while zeroization is active.
Reset cancels the protocol and invalidates completion; the focused test proves
that reset alone does not overwrite retained permutation or sponge payload.

The focused zeroize test writes nonzero values into H, G, and J sponge state,
permutation input/state/output, absorb staging, squeeze staging, and output
staging. It checks 19,200 permutation/sponge state bits plus the staging
registers, repeated zeroize, reset interruption, one-cycle completion, and a
clean SHA3-256(empty) oracle transaction after scrub.

Verification:

- `sim/scripts/run_m5_mlkem_zeroize.sh`: PASS, 123 checks.
- `RUN_LOWER_REGRESSIONS=0 sim/scripts/run_m5_regression.sh`: PASS, 16/16
  programs, 125,520 internal checks, 76,370 digest-byte comparisons, and 2,204
  permutation-state comparisons in 26 seconds.
- H/G/J ordinary oracle coverage within the regression: PASS, 240 vectors and
  10,240 output-byte checks.

This report does not claim that M6 PRF/XOF owners already propagate the M5
acknowledgement. That propagation remains a separate bottom-up M6 gate. No
synthesis, timing, Fmax, or physical-design claim is made.
