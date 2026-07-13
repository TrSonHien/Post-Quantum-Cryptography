# Polynomial/Polyvec Engine Contract

## Scope and constants

This contract freezes M4.0 through M4.3. One polynomial has `N=256`
coefficients, each externally encoded as an unsigned 12-bit canonical residue
in `[0,3328]` for `q=3329`. One ML-KEM-768 polyvec has `K=3` polynomials and
768 coefficients. Exact polynomial MultiplyNTTs is frozen; K=3 orchestration
and accumulation remain M4.4/M4.5 work.

## Domains

Domain metadata is two bits:

| Encoding | Name | Meaning |
|---|---|---|
| `2'b00` | `POLY_DOMAIN_INVALID` | Reset, unknown, incomplete, or unpublished data |
| `2'b01` | `POLY_DOMAIN_NORMAL` | Canonical normal polynomial coefficients |
| `2'b10` | `POLY_DOMAIN_NTT` | Canonically encoded coefficients with NTT semantics |
| `2'b11` | `POLY_DOMAIN_POINTWISE` | Reserved for future M4.3 results; behavior is not frozen |

Coefficient encoding and semantic domain are separate concepts. Canonical bits
do not identify whether a coefficient is normal or NTT data. Callers must carry
domain metadata and may not infer it from coefficient values.

## Frozen baseline

- one shared forward NTT engine and one shared inverse NTT engine;
- one logical polynomial workspace abstraction per live operand/result;
- serialized polyvec element order 0, 1, 2;
- no duplicated M3 engine and no caller access to M3 physical banks;
- explicit load, internal operation, publish, and result phases;
- no operation on incomplete or invalid-domain data;
- no output overwrite before explicit new-load initialization.

## Workspace

`poly_workspace` uses two 128x12 banks with fixed mapping
`bank=index[0]`, `address=index[7:1]`. This is a bijection over all 256 logical
indices. Pair index `p` addresses logical indices `2p` and `2p+1`, one in each
bank, so intended two-lane access is collision-free.

Ownership states are `EXTERNAL_LOAD`, `INTERNAL_OPERATION`, and
`EXTERNAL_RESULT`. Memory payload is never reset. Synchronous reset clears
owner, read valids, completeness, domain, and sticky error. Completeness is a
256-bit logical-index bitmap plus a count; RAM contents never imply validity.
Duplicate external writes are legal before start and overwrite the coefficient
without incrementing the count. `load_begin` explicitly invalidates prior
metadata before reuse.

External and internal reads are synchronous with one-cycle latency and II=1.
Internal single access supports M3 adapters; even/odd pair access supports M4.1
arithmetic. External access is rejected during internal ownership. Publish is
legal only after all 256 output indices have been written.

## Controller interface

Polynomial controllers follow this indexed, non-streaming boundary:

```text
clk, rst_n
load_begin, load_domain[1:0]
load_we, load_operand, load_coeff_index[7:0], load_coeff
load_ready
start, busy, done, error
result_req, result_coeff_index[7:0]
result_valid, result_coeff[11:0], result_domain[1:0], result_complete
```

Binary arithmetic selects operand A/B with `load_operand`. Reduce accepts a
documented 32-bit unsigned input coefficient. NTT adapters have one input.
Polyvec controllers later add a two-bit element index and must reject value 3.
No generic valid/ready streaming bus is introduced.

`rst_n` is synchronous active-low. `done` is one cycle. `busy` remains asserted
through the final committed output and publish. `error` is sticky until reset,
matching M3. Illegal start while busy, incomplete input, invalid or mismatched
domain, load/read while busy, read before publish, coefficient outside the
declared range, invalid polyvec index, and result overwrite are errors.

## Arithmetic domain rules

- Add/sub require two complete operands with equal `NORMAL` or equal `NTT`
  domains. Output preserves that domain.
- Reduce accepts a complete operand with `NORMAL` or `NTT` semantics and
  preserves it. Its input width is 32 bits and output is canonical 12-bit.
- Forward NTT requires complete `NORMAL` input and publishes complete `NTT`.
- Inverse NTT requires complete `NTT` input and publishes complete `NORMAL`.
- Exact MultiplyNTTs requires two complete `NTT` operands and publishes `NTT`.
- `POINTWISE` is internal-reserved and does not escape the M4.3 boundary.
- `INVALID` and `POINTWISE` are rejected by public M4.1-M4.3 operations.

## M3 adapter contract

Adapters read the workspace synchronously, preload all 256 logical M3 indices,
start only after the final preload is accepted, wait for M3 `done`, issue 256
logical result reads, and synchronously store every response before publish.
They do not expose or reconstruct physical M3 banks. The inverse adapter does
not rescale: `intt_core_pipe` already returns canonical normal-domain results.

## Limitations

M4.3 pointwise/basemul orchestration, polyvec accumulation, DMA/streaming,
synthesis timing, and Fmax are not part of this freeze. M2.3b remains pending.
