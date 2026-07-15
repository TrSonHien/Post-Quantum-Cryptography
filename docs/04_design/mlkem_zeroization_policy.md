# ML-KEM Zeroization and Destruction Policy v0.1

## Three distinct events

Reset is logical invalidation: synchronous active-low reset cancels traffic and
clears ownership, completeness, valid, done, error, and secret metadata.  It
does not claim that RAM/flop payload bits were erased.

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
and a sequential scrub that visits address 0 through capacity-1.  Reused M5--
M7 modules require zeroize-only interface extensions or equivalent verified
overwrite control.  Reset-driven invalidation is not accepted as a substitute.

## Verification and limitations

Tests preload nonzero patterns at every reachable address, request zeroize,
and inspect every location after completion.  They cover idle, success paths,
active abort, output stall, reset during scrub, explicit restart, reject-state
clearing, and the prohibition on done before the final overwrite.  Any child
payload that cannot be overwritten remains an explicit M8 blocker and must be
reported; it cannot be waived by documentation.

This is a functional RTL destruction policy, not a proof against remanence,
fault injection, probing, power analysis, compiler optimization, or physical
implementation leakage.
