# M7 Hierarchical Zeroization Report

Status: PASS for the M7 completion gate on 2026-07-16.

The K-PKE KeyGen, Encrypt, and Decrypt controllers retain their existing
mathematical interfaces and outputs. Explicit zeroization now scans every
controller-owned byte/coefficient array and waits for every stateful child:
7 KeyGen children, 11 Encrypt children, and 8 Decrypt children. Matrix-row and
noise-vector sampler parents also clear local staging and wait for SampleNTT or
noise-sampler completion.

Verification:

- `sim/scripts/run_m7_kpke_zeroize.sh`: PASS, 21,462 checks. This comprises
  21,408 controller-local locations, 16 representative child payload
  locations, 26 child acknowledgements, and 12 protocol checks. It covers all
  four NTT banks, transform preload/workspace, sampler, basemul/add state,
  repeated scrub, active abort, reset interruption, and clean restart.
- `sim/scripts/run_arithmetic_pipeline_zeroize.sh`: PASS, 59 checks across 34
  retained arithmetic locations, including Barrett and normal multiplication.
- `sim/scripts/run_poly_reduce_pipe.sh`: PASS, 8,709 checks including a
  516-location reduce-memory/workspace/lane scrub and post-scrub oracle run.
- `RUN_LOWER_REGRESSIONS=0 sim/scripts/run_m7_regression.sh`: PASS 11/11. The
  run reported 497,777 internal checks before the zeroize accounting correction;
  the corrected deterministic total is 497,775, with 151,716 byte comparisons
  and 324,096 coefficient comparisons in 766 seconds. Functional test content
  is unchanged by this two-check bookkeeping correction.

Reset invalidates control only. The reset-interruption test observes retained
payload, invalidates the interrupted completion, restarts explicit scrub from
address zero, and obtains exactly one later zeroize completion. No synthesis,
area, timing-closure, or Fmax claim is made.
