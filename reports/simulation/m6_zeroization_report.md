# M6 Physical Zeroization Report

## Scope

This report closes explicit physical destruction for the M6 codec and sampler
services without changing their mathematical results. Reset behavior remains
independent: reset cancels control and invalidates completion, while only an
accepted `zeroize_req` establishes payload destruction.

## Implemented ownership paths

- PRF and XOF clear seed/input, nonce/index, counters, and local ownership,
  hold their Keccak child request until acknowledgement, and suppress squeeze
  output during cleanup.
- Scalar codec pipelines clear every registered payload, valid, error, and
  output-holding stage in two cycles.
- Byte encode/decode clear reservoirs, sequential temporaries, counters,
  output payload, and noncanonical metadata in two cycles.
- K-PKE format adapters clear held stream payload and metadata in two cycles.
- Polyvec codecs clear wrapper ownership and wait for the serialized child
  codec acknowledgement before pulsing `zeroize_done`.
- CBD pair/poly samplers and the SampleNTT parser directly clear retained
  coefficient, reservoir, candidate, counter, and output state in two cycles.
- The noise sampler joins PRF and CBD acknowledgements; integrated SampleNTT
  joins XOF and parser acknowledgements. Both abort normal ownership and emit
  no normal completion or output during cleanup.

Primitive direct-clear latency is fixed at two clocks from request sampling to
the one-cycle completion pulse. Hierarchical parents complete in bounded
`max(child latency)+2` clocks. Requests remain asserted internally until each
child acknowledgement is observed, so unequal child latencies cannot lose an
acknowledgement.

## Verification

Commands and results:

```text
sim/scripts/run_m6_prf_xof_zeroize.sh       PASS (32 checks, 14 state objects)
sim/scripts/run_m6_codec_zeroize.sh         PASS (17 checks, 8 owner types)
sim/scripts/run_m6_sampler_zeroize.sh       PASS (13 checks, 5 owner types)
sim/scripts/run_m6_zeroize.sh               PASS (3/3, 62 checks)
RUN_LOWER_REGRESSIONS=0 \
  sim/scripts/run_m6_regression.sh          PASS (15/15, 664,856 checks)
```

The zeroize tests first install distinguishable nonzero payload, confirm it is
present, verify busy/no-premature-done behavior, inspect all listed state after
completion, verify the completion pulse clears, interrupt cleanup with reset,
repeat explicit cleanup, and run a clean ordinary transaction. The ordinary
regression preserves 276,992 byte and 376,576 coefficient comparisons,
including 128 noise vectors and 64 SampleNTT vectors.

## Boundary

M6 owner-level zeroization is complete. This does not claim M7 or M8
hierarchical destruction: K-PKE controllers must still propagate requests
through transform/workspace/arithmetic owners, and the public top still needs
boot, abort, explicit, and automatic scrub orchestration.
