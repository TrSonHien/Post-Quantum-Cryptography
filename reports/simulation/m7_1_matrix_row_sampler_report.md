# M7.1 Matrix and Noise Orchestration Report

Commands:

```sh
timeout 420s ./sim/scripts/run_kpke_matrix_row_sampler.sh
timeout 300s ./sim/scripts/run_kpke_noise_vector_sampler.sh
```

Both commands PASS.  The matrix test covers 16 deterministic rho values, all
three logical rows, and both orientations: 96 complete row transactions and
77,568 coefficient comparisons including reset/restart and busy-start reruns.
It checks 10,404 seed/index bytes at child launch.  Every non-transposed element
uses `(index0,index1)=(col,row)` and every transposed element uses
`(row,col)`.  Each row launches exactly three SampleNTT operations and emits
elements 0,1,2 without swapping.

The noise-vector test covers 16 complete K=3 vectors, eta2 and eta3, distinct
start nonces including modulo-256 progression, 16,128 coefficient comparisons,
and 66 checked child nonce launches including reset/restart and busy-start
reruns.  `next_nonce=start_nonce+3` and element `i` uses `start_nonce+i`.

Both tests apply output backpressure and prove stable stalled payload.  Each
resets during child element 0, 1, and 2, verifies cancellation, and completes a
clean restart.  Bounded cycle watchdogs and runner wall-clock timeouts pass.
No waveform, binary, vector, log, or process artifact remains.  These are
simulation cycle/function results only; no synthesis, area, timing, or Fmax
claim is made.
