# M1 Architecture Freeze v0.1

## Status

M1 documentation freezes the approved interface, representation, reset,
pipeline, synchronous-memory, and one-butterfly NTT/INTT baseline contracts.
No RTL, testbench, simulation script, or reference model was modified.

## Frozen decisions

- Canonical unsigned `[0,3328]` architectural coefficients.
- Explicit `*_hat` NTT-domain naming and metadata.
- Montgomery representation confined to multiplier internals.
- Valid/ready engine channels and fixed-latency valid-only internal lanes.
- Synchronous active-low internal reset of control/valid state only.
- One butterfly accepted per cycle (`II=1`).
- One-cycle synchronous out-of-place ping-pong polynomial storage.
- Two source and two destination banks, 128 x 12 bits per bank.
- Illegal collision semantics and completion after final write commit.
- Multi-lane NTT deferred to M3.

## Banking proof result

The two-bank-per-side topology is conflict-free. For adjacent stage pair bits
`p` and `r`, destination bank is `i[p] xor i[r]` and address is logical index
`i` with bit `r` removed. Current butterfly outputs differ in `p`, so they write
opposite banks; next butterfly inputs differ in `r`, so they read opposite banks
at the same address. Address deletion is injective within each bank. This covers
all seven forward and seven inverse stage transitions; full tables are in
`docs/03_architecture/ntt_architecture.md`.

## Legacy RTL boundary

Existing `poly_buffer` uses asynchronous reads, legacy engines use
`start/busy/done`, most pipelines lack ready/backpressure, resets are generally
asynchronous, and `mod_mul` exposes Montgomery-reduction semantics. Those blocks
remain useful verified baselines but do not satisfy M1 contracts without future
wrappers or replacement. M1 makes no new RTL correctness or Fmax claim.

## Verification evidence and pending work

The stale dedicated `poly_sub` report was resolved by rerunning
`bash sim/scripts/run_poly_sub.sh`: `pass_count=1024 fail_count=0`, PASS. The M1
verification plan maps `mlkem-vector-v1` into future RTL streams and defines
protocol, reset, domain, bank, latency, collision, and completion assertions.

Final NIST CAVP/ACVP vectors remain pending. M2 must not begin without explicit
approval; arithmetic pipeline latency and implementation are M2/M3 work.
