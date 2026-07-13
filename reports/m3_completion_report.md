# M3 Completion Report

## Status

M3.0 through M3.6 are implemented, independently differential-tested, and
closed by the unified regression. M3 provides one banked, pipelined forward NTT
core and one banked, pipelined inverse core with a two-lane canonical final
scaler. The public interfaces are frozen for M4 in
`docs/04_design/ntt_intt_engine_contract.md`.

| Milestone | Result |
|---|---|
| M3.0 architecture/layout audit | Complete |
| M3.1 forward scheduler | Complete |
| M3.2 forward banked core | Complete |
| M3.3 inverse scheduler and stages | Complete |
| M3.4 two-lane final scaler | Complete |
| M3.5 differential and roundtrip verification | Complete |
| M3.6 unified regression and interface freeze | Complete |

## Final architecture

Each transform stage issues 128 logical butterfly pairs at II=1 through two
synchronous source banks, a one-cycle read, a five-cycle butterfly, aligned
zeta/write metadata, and two synchronous destination banks. The committed last
write and zero pending reads/butterflies/writes trigger one safe role swap and
one scheduler stage advance.

The forward core executes seven Cooley-Tukey stages, zeta groups 1 through 127,
and ends in logical layout `b=i1,a=rm1`. The inverse core reverses the proven
layout sequence through seven Gentleman-Sande stages with zetas 127 through 1,
then reads canonical layout `b=i7,a=rm7` into two parallel scaler lanes. Operand
512 converts the Montgomery multiplier result to normal-domain scaling by
`128^-1 mod q = 3303`.

## Layout correction history

The original M3.0 constant-`r=7` transition plan was incorrect. The first real
M3.2 divergence was a stage-1 destination-bank collision caused by stale
scheduler/layout metadata. The abandoned WIP also swapped roles without proving
all pending traffic drained. M3.2 corrected the forward sequence; M3.3 derived
the inverse by reversing that committed sequence. M3.6 corrected the remaining
stale inverse prose table and re-proved eight bijective layouts plus 896
conflict-free requests in each direction.

## Verified results

- Forward: 896 pair reads/responses/inputs/outputs/writes, seven stage swaps,
  seven-cycle issue-to-write latency, 955 start-to-done cycles.
- Inverse stages: the same 896 transaction counts and swaps, seven-cycle
  issue-to-write latency, 954 cycles before scaling.
- Scaler: two lanes, 128 pair reads, 256 inputs/outputs, 128 writes, six-cycle
  issue-to-write latency; full inverse done at 1090 cycles.
- Forward differential: 28 polynomials and 7168 coefficient comparisons.
- Inverse differential: 31 polynomials and 7936 comparisons.
- Pipelined roundtrip: 30 polynomials, 7680 independent forward comparisons and
  7680 final comparisons.
- Reset/control, logical-write uniqueness, pending traffic, metadata/zeta
  alignment, role swaps, M2 adjacency, legacy adjacency, Python model/schema,
  and deterministic vector reproduction all pass.
- Unified regression: 22/22 programs and 361656 internal checks PASS.

## Frozen M4 boundary

M4 receives indexed canonical unsigned coefficients and must track normal,
NTT, and pointwise-product domains. It must serialize 256 coefficient loads,
compute, and synchronous indexed readback; wait for `done`; propagate sticky
errors; and never access physical banks. The baseline reuses one engine for the
three ML-KEM-768 polyvec elements. No M4 functional RTL is part of M3.6.

## Limitations and M4 entry criteria

M2.3b server ASIC synthesis remains pending, so no frequency, Fmax, area, or
physical timing claim exists. The interface is indexed rather than streaming,
and no full ML-KEM KAT completion is claimed.

M4 entry requires the unified M3 regression PASS, clean worktree, frozen engine
interface, documented canonical domains, and no unresolved memory collision or
reset/control issue. Those functional criteria are met. M2.3b may remain
pending but must remain tracked during M4.
