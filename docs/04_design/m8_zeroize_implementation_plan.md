# M8 Hierarchical Zeroization Implementation Plan v0.1

## Frozen objective

Close every `missing` entry in
`reports/security/m8_retained_state_inventory.md` without changing FIPS 203
mathematical outputs or the verified ordinary reset contract.  Work is
bottom-up and every layer waits for its owned children.

## Z0: Protocol alignment and evidence

- Rename/adapt the current M5 `zeroize` request port to the frozen
  `zeroize_req`, preserving ordinary ports and outputs.
- Add assertions for one-cycle `zeroize_done`, no normal done/output during
  scrub, request rejection while busy, and final-state zero.
- Extend `tb_m5_mlkem_zeroize.v` to cover idle, mid-absorb, mid-permutation,
  mid-squeeze, repeated zeroize, reset interruption, and clean restart.
- Run `run_mlkem_hgj.sh`, the dedicated zeroize test, then M5 focused.
- M5 is commit-ready only after these protocol checks pass on an isolated diff.

## Z1: Polynomial storage owners

Files:

- `rtl/poly/poly_workspace.v`
- `rtl/poly/polyvec_workspace.v`
- new `tb/unit/tb_poly_workspace_zeroize.v`
- new `tb/unit/tb_polyvec_workspace_zeroize.v`
- focused runners and coverage-manifest entries

`poly_workspace` blocks every normal port, clears both banks in parallel for
addresses 0 through 127, clears scalar payload/metadata, and pulses done after
address 127 writes commit.  Fixed latency is 130 cycles.  A reset interruption
invalidates completion; the next accepted request restarts at address zero.
`polyvec_workspace` requests its three children together and waits for all
three acknowledgements; fixed bound 132 cycles.

Verify address-dependent nonzero fill, first/middle/final writes, reset
retention outside scrub, reset during scrub, readback, reload, and all ordinary
M4 workspace/polyvec tests.  Commit only this independently complete owner
layer as `security(storage)` if its ordinary M4 focused regression passes.

## Z2: NTT/INTT banks and transforms

Files:

- `rtl/memory/ntt_pingpong_banks.v`
- `rtl/ntt/ntt_core_pipe.v`
- `rtl/ntt/intt_core_pipe.v`
- `rtl/ntt/intt_scaler_pipe.v`
- `rtl/poly/poly_transform_pipe.v`
- `rtl/poly/poly_ntt_pipe.v`, `poly_intt_pipe.v`
- `rtl/poly/polyvec_elementwise_pipe.v`, `polyvec_ntt_pipe.v`,
  `polyvec_intt_pipe.v`
- dedicated bank/core/transform zeroize TBs and runners

The ping-pong owner multiplexes scrub writes into all four physical banks at
each address.  It never resets RAM payload.  NTT/INTT cores clear preload
arrays in the same 128-address sequence, request the bank owner, flush
remaining pipeline/scaler stages, and wait for all acknowledgements.  Bounds:
130 bank cycles, 134 forward-core cycles, 138 inverse-core cycles.

TBs fill and inspect source/destination bank 0/1, inactive banks,
preload/result state, first/final address, reset interruption, and clean
transform restart.  Run ordinary NTT, INTT, roundtrip, M3 focused, then affected
M4 transforms.

## Z3: Generic pipeline flushing

Files include `fixed_latency_delay.v`, modular arithmetic pipes, butterfly
pipes, BaseCaseMultiply pipes, and their owning wrappers.

For each fixed-depth pipeline, add scrub mode that injects valid zero payload
for its full depth, drains for the documented latency, suppresses output
visibility, directly clears only state that cannot be reached by a zero
transaction, and pulses done after hierarchical TB inspection proves every
stage zero.  Each module records depth, injection count, and drain count as
local parameters used by assertions and the coverage manifest.  No wide
payload reset mux is allowed.

Run the affected arithmetic/butterfly/BaseCaseMultiply unit test before M2/M3/
M4 focused regressions.  Stop if any stage cannot be proven overwritten.

## Z4: Codec, sampler, PRF, and XOF propagation

Files include byte encode/decode, compression/decompression, message/poly and
polyvec codecs, CBD/parser/samplers, `mlkem_prf.v`, and `mlkem_xof.v`.

Flush codec/CBD/parser pipelines with valid zero transactions and directly
clear unreachable reservoirs.  Noise and SampleNTT owners request all child
scrubs and wait for acknowledgements.  PRF/XOF clear retained seed/input
registers and propagate the M5 sponge request.  Public matrix coefficient
payload may be exempt, but ownership/domain/valid metadata is cleared.

Dedicated TBs prove ordinary output equivalence, zero-state hierarchy,
mid-operation abort, reset interruption, and restart.  Run affected unit tests,
then M6 focused.  Commit as `security(m6)` only with complete manifest coverage.

## Z5: Hierarchical K-PKE closure

Files: the three `rtl/kpke/kpke_*.v` controllers and matrix/noise helpers.

Replace `child_clear` private-reset pulses with explicit child request/ack
vectors.  On zeroize acceptance, invalidate normal ownership, scan all local
arrays, directly clear secret scalars, request every instantiated stateful
child, and wait for all bits of a sticky acknowledgement vector.  Public A-hat
payload may be exempt; its ownership metadata is still invalidated.  Normal
done/output is suppressed until the controller returns idle.

Extend the dedicated M7 TB to fill and inspect controller and child hierarchy,
derive its check count from the manifest, and test every major phase.  Run
matrix/noise, KeyGen, Encrypt, Decrypt, roundtrip, ordinary M7 focused, then M7
zeroize.  Do not commit until all child entries are complete.

## Z6: M8 deterministic and public controllers

Add the frozen protocol to internal and public controllers.  Local scan lengths
remain 2400/1184/2400 for KeyGen/Encaps/Decaps internal and 64/1184/2400 for
public wrappers.  Controllers request children, retain sticky acknowledgements,
and pulse normal done only after automatic cleanup.  Explicit abort follows the
same scrub path but suppresses designated outputs.  Mismatch accumulator/mask
and temporary selected K are direct-cleared after final K acceptance.

Test automatic cleanup, explicit idle scrub, abort in each phase, output stall,
reset interruption, boot-scrub restart, repeated scrub, and immediate clean
command.  Run affected unit/internal/public tests, then M8 smoke.

## Z7: Unified top and boot scrub

Replace `child_rst_n = rst_n && !zeroizing` with the documented nine-state
hierarchical FSM.  Reset deassertion enters boot scrub and holds `cmd_ready=0`.
The top requests all three public wrappers in parallel for the baseline,
records acknowledgements, clears top scalars, and exposes ready only after
completion.  Explicit ZEROIZE while active first suppresses all public traffic,
then follows the same hierarchy.  Estimated bound is 7,420 cycles.

The unified-top TB is not weakened: its existing entropy failure at line 18
must pass through real overwrite.  Add boot-scrub, reset-during-scrub, repeated
zeroize, all active phases, no-stale-output/error, and clean restart cases.

## Z8: Coverage and regression gates

Create `reports/security/m8_zeroize_coverage.json` with one record per retained
state identifier, expected and checked counts, mechanism, TB, and PASS/FAIL.
Regression counters are generated from this manifest.  After all records pass:
M5 focused, M6 focused, M7 focused, M8 smoke, M8 focused, then the nonrecursive
full-project regression exactly once.

No phase is committed if a child is missing, an ordinary regression changes,
or reset is used as evidence of erasure.  No synthesis, area, timing, Fmax, or
final CAVP/ACVP claim follows from this plan.
