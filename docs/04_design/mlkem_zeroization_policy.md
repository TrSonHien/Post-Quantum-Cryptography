# ML-KEM Zeroization and Destruction Policy v0.1

## Frozen explicit protocol

Every state-owning engine added or extended for M8 uses the same three-signal
protocol where practical:

- input `zeroize_req`;
- output `zeroize_busy`;
- output `zeroize_done`.

`zeroize_req` is sampled only when the owner can enter zeroize mode.  It has
priority over a new normal start/load command.  Acceptance immediately
invalidates normal ownership and suppresses normal input readiness, output
validity, normal `done`, and error reporting.  New work is rejected while
`zeroize_busy`.  The owner overwrites every sensitive retained payload and
secret scalar, requests every stateful child, and waits for every child
acknowledgement.  `zeroize_done` pulses for exactly one cycle only after the
final local write and all child `zeroize_done` events have committed.  The
latency is fixed for a given module configuration and is recorded in the
retained-state inventory and coverage manifest.

Legacy M5/M7 owners retain a compatible `zeroize` spelling where changing the
normal interface would add risk; M8-facing services use `zeroize_req`.
Adapters preserve the same request/busy/done contract. `rst_n` is never driven
as a substitute for either spelling.

## Three distinct events

Reset is logical invalidation: synchronous active-low reset cancels traffic and
clears ownership, completeness, valid, done, error, and secret metadata.  It
does not claim that RAM/flop payload bits were erased.

If reset interrupts a scrub, any pending zeroize completion is invalidated.
After reset deassertion the unified top enters mandatory boot scrub, keeps
`cmd_ready=0`, restarts every required address scan from zero, and accepts no
public operation until the hierarchical boot scrub completes.  Reset itself
does not produce `zeroize_done`.

Physical zeroize is explicit overwrite: every reachable secret or ephemeral
array address is written with zero, scalar secret registers and Keccak payload
state are cleared, and reject accumulator/mask state is cleared.  Completion
occurs only after all writes commit.

Operation completion is an API event: a public operation may stream designated
outputs first, but `busy` remains asserted and `done` cannot pulse until its
mandatory physical destruction is complete.

## Abort and ownership policy

An explicit ZEROIZE command accepted while idle begins a full scrub.  A
zeroize request during an active public operation aborts that operation,
withdraws input/output valids, suppresses designated outputs not yet accepted,
and takes exclusive ownership until scrub completes.  Reset during scrub
cancels control and invalidates metadata; because reset is not erasure, a later
explicit zeroize is still required before an erasure claim.  New commands are
blocked during output stalls and scrub.

The unified top uses the following correctness-first states:

1. `BOOT_REQ` and `BOOT_WAIT` after reset;
2. `IDLE` after boot scrub completion;
3. `ACTIVE` for one public operation;
4. `ZERO_REQ` to issue one-cycle wrapper scrub requests;
5. `ZERO_WAIT` to latch all three wrapper acknowledgements.

Parallel child scans are used because each owner has an independent request
and acknowledgement. Requests are pulses, not levels held until completion;
this prevents a child that returns to idle from accepting the same request
twice. The former top-level private-reset shortcut is removed.

## Bottom-up implementation order and fixed-cycle budget

Implementation proceeds in this order: storage owners; NTT/INTT and pipeline
engines; codecs/samplers; K-PKE controllers; deterministic M8 controllers;
public wrappers; unified top.  No upper layer may report completion for an
unclosed child.

Provisional fixed upper bounds, excluding normal operation latency, are:

| Owner | Estimated scrub cycles |
|---|---:|
| H/G/J service | 5 |
| `poly_workspace` | 130 |
| `polyvec_workspace` | 132 |
| NTT core including all four ping-pong banks | 134 |
| INTT core including preload/scaler staging | 138 |
| codec or arithmetic pipeline | at most 12 |
| K-PKE KeyGen | at most 1,190 |
| K-PKE Encrypt | at most 1,190 |
| K-PKE Decrypt | at most 1,160 |
| KeyGen_internal | at most 3,600 |
| Encaps_internal | at most 2,400 |
| Decaps_internal | at most 6,200 |
| public KeyGen | at most 3,700 |
| public Encaps | at most 3,700 |
| public Decaps | at most 7,400 |
| unified boot scrub with three public branches in parallel | measured 2,407 |

The storage/transform values are measured owner-level bounds. The M8 local
controller bounds follow fixed scan lengths with children running in parallel.
The unified boot result is measured by the top TB from reset release to
`cmd_ready`; a 100,000-cycle watchdog prevents unbounded boot wait.

## Required destruction sets

- KeyGen: d, z, sigma, s/e and transformed secret/error workspaces, secret hash
  state, temporary dkPKE copies, and partial entropy.
- Encaps: m, r, H(ek), G staging after K is secured, y/y-hat/e1/e2, K-PKE
  ephemeral workspaces, partial entropy, and secret Keccak state.
- Decaps: parsed DK copies, z, m-prime, K-prime, r-prime, K-bar after transfer,
  c-prime, mismatch accumulator/mask, K-PKE secret workspaces, and secret
  Keccak state.
- Public/top buffers: all candidate keys/ciphertexts and designated output
  staging are scrubbed after use.  Public matrix A derived only from rho is not
  secret, but a uniform full-controller scrub may overwrite it.

Every new fixed byte buffer has a configured capacity, metadata invalidation,
and a sequential scrub that visits address 0 through capacity-1.  M5 H/G/J now
have explicit zeroize ports that clear sponge, permutation, and staging state.
M7 controller-owned arrays and all reused polynomial, NTT/INTT, codec, sampler,
and Keccak child payload have explicit overwrite control and acknowledged
hierarchical propagation. Reset-driven invalidation is not counted as erase.

## Verification and limitations

Tests preload nonzero patterns at every reachable address, request zeroize,
and inspect every location after completion.  They cover idle, success paths,
active abort, output stall, reset during scrub, explicit restart, reject-state
clearing, and the prohibition on done before the final overwrite. The final
coverage manifest maps all retained-state owner families and reports zero
uncovered entries.

This is a functional RTL destruction policy, not a proof against remanence,
fault injection, probing, power analysis, compiler optimization, or physical
implementation leakage.

The verified reset test intentionally preloads nonzero RAM/workspace/delay
payload, asserts reset, and proves payload retention while valid/control state
is invalidated.  This prevents reset from being reported as physical erasure.
