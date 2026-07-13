# NTT/INTT Engine Contract

## 1. Purpose and scope

This document freezes the verified M3.6 boundary of `ntt_core_pipe` and
`intt_core_pipe` for M4 integration. It describes canonical coefficient
interfaces, synchronous memory protocols, internal bank layouts, measured
cycle behavior, and caller restrictions. It does not select a clock frequency
or claim synthesis timing.

## 2. External interfaces

Both cores expose the same ports:

```text
clk, rst_n, start, busy, done, error
preload_en, preload_idx[7:0], preload_coeff[11:0], preload_ready
result_rd_req, result_rd_idx[7:0], result_rd_valid, result_rd_data[11:0]
```

`ntt_core_pipe` accepts a normal-domain polynomial and returns `polynomial_hat`
in the project's NTT domain. `intt_core_pipe` accepts that canonical NTT-domain
encoding and returns a scaled canonical normal-domain polynomial.

## 3. Representation and domain

- `q=3329`, `N=256`, and all external coefficients are unsigned 12-bit
  integers in `[0,3328]`.
- The NTT boundary uses canonical residues, not an undocumented Montgomery
  encoding. Montgomery-scaled constants exist inside arithmetic pipelines.
- Forward output is named `polynomial_hat`. Its mathematical ordering is the
  FIPS/Kyber NTT ordering represented by logical indices, not normal polynomial
  coefficient order.
- Final inverse output is canonical normal-domain data after multiplication by
  `128^-1 mod q = 3303`.

## 4. Reset and control

`rst_n` is synchronous and active low. A low value sampled on `clk` clears FSM,
valid, pending, completion, result-ownership, and sticky error state. Memories
and datapath payload registers are not reset. A cancelled operation therefore
invalidates its results even though old payload bits can remain physically
present.

- `start` is accepted only while idle after all 128 preload pairs exist.
- `busy` remains high from accepted start through final result ownership.
- `done` is a one-cycle pulse. Forward `done` follows the final NTT role swap;
  inverse `done` follows the final scaler write, drain, and role swap.
- `error` is sticky until reset. Start, preload, or result access while busy,
  start with incomplete preload, and result access before valid completion set
  it.
- A completed or reset core can be preloaded and restarted.

## 5. Preload protocol

`preload_ready` equals `!busy`. The caller presents one logical index and one
canonical coefficient with `preload_en`. The paired-bank write occurs when the
second member of each implementation-defined pair arrives; callers must use
the natural complete-polynomial load order `0..255` unless a future adapter
explicitly implements the pairing rule. Exactly 256 accepted coefficient loads
are required before start. Preload data is written to the inactive role and a
pre-start role swap establishes source ownership.

Forward pairs are `(i,i+128)` for `i=0..127`. Inverse preload pairs are arranged
for layout `b=i1,a=rm1`; the natural `0..255` sequence satisfies the internal
pair tracker.

## 6. Result-read protocol

Result reads are legal only while idle after `done`. The caller asserts
`result_rd_req` with a logical `result_rd_idx`. The synchronous bank read
returns `result_rd_valid` and canonical `result_rd_data` one cycle later. The
interface accepts one logical request per cycle. Reading all coefficients
therefore requires 256 requests plus the final response cycle. Logical index
mapping reconstructs the coefficient independently of physical bank layout.

## 7. Memory and layout

Each engine uses `ntt_pingpong_banks`: two source banks and two destination
banks, each a one-read/one-write synchronous RAM. An active issue reads one
coefficient from each source bank; a valid result writes one coefficient to
each destination bank. `ntt_bank_map` implements

```text
bank(i) = i[p] xor (xor_layout ? i[r] : 0)
addr(i) = remove_bit(i,r)
```

Roles swap only after the final marked write commits and all pending reads,
butterflies, and writes are zero. Exhaustive proof covers all 256 indices in
every layout and all 896 requests in each transform direction.

Forward layouts:

| Stage | Len | Source | Destination |
|---:|---:|---|---|
| 0 | 128 | `b=i7,a=rm7` | `b=i7^i6,a=rm6` |
| 1 | 64 | `b=i7^i6,a=rm6` | `b=i6^i5,a=rm5` |
| 2 | 32 | `b=i6^i5,a=rm5` | `b=i5^i4,a=rm4` |
| 3 | 16 | `b=i5^i4,a=rm4` | `b=i4^i3,a=rm3` |
| 4 | 8 | `b=i4^i3,a=rm3` | `b=i3^i2,a=rm2` |
| 5 | 4 | `b=i3^i2,a=rm2` | `b=i2^i1,a=rm1` |
| 6 | 2 | `b=i2^i1,a=rm1` | `b=i1,a=rm1` |

Inverse layouts reverse the proven sequence:

| Stage | Len | Source | Destination |
|---:|---:|---|---|
| 0 | 2 | `b=i1,a=rm1` | `b=i2^i1,a=rm1` |
| 1 | 4 | `b=i2^i1,a=rm1` | `b=i3^i2,a=rm2` |
| 2 | 8 | `b=i3^i2,a=rm2` | `b=i4^i3,a=rm3` |
| 3 | 16 | `b=i4^i3,a=rm3` | `b=i5^i4,a=rm4` |
| 4 | 32 | `b=i5^i4,a=rm4` | `b=i6^i5,a=rm5` |
| 5 | 64 | `b=i6^i5,a=rm5` | `b=i7^i6,a=rm6` |
| 6 | 128 | `b=i7^i6,a=rm6` | `b=i7,a=rm7` |

The scaler reads `b=i7,a=rm7`, writes the same canonical layout in the other
role, and performs the final ownership swap.

## 8. Twiddles and butterfly equations

The combinational `zetas_rom` table contains Montgomery-scaled zetas. The zeta
selected at issue is delayed with its transaction through the one-cycle RAM
read.

- Forward group addresses increase from 1 through 127 over lengths
  `128,64,32,16,8,4,2`.
- Inverse group addresses decrease from 127 through 1 over lengths
  `2,4,8,16,32,64,128`.
- Forward: `t=MontgomeryReduce(zeta*v)`, `out_u=u+t`, `out_v=u-t`, all modulo q.
- Inverse: `out_u=u+v`, `out_v=MontgomeryReduce(zeta*(v-u))`, all modulo q.

## 9. Pipeline, drain, and cycle contracts

An accepted butterfly request at edge `M` produces visible RAM data and samples
the butterfly at `M+1`; butterfly output and write metadata are visible at
`M+6`; the destination write commits at `M+7`. Each stage issues 128 requests
on consecutive cycles and has eight no-issue cycles before the next stage's
first issue. Stage advance is based on committed-last metadata and zero pending
traffic, not a guessed drain counter.

Measured compute accounting:

| Engine phase | Pair issues | Duration | Utilization |
|---|---:|---:|---:|
| Forward NTT | 896 | 955 cycles start-to-done | 93.82% |
| Inverse butterflies | 896 | 954 cycles through stage completion | 93.92% |
| Inverse scaler through ownership | 128 | 135 cycles | 94.81% |
| Full inverse | 1,024 | 1,090 cycles start-to-done | n/a across mixed work |

Forward and inverse butterfly work is 896 pair operations or 1,792 coefficient
lane operations. Their measured cycles per butterfly pair are 1.0658 and
1.0647. Ideal issue time is 896 cycles, leaving 59 forward and 58 inverse-stage
cycles for startup, drains, swaps, advances, and completion. Compute totals
exclude serialized preload and result readback.

## 10. Final inverse scaling

`intt_scaler_pipe` reads one coefficient pair per cycle and drives two parallel
four-cycle `mod_mul_pipe` lanes. Each lane receives operand 512:

```text
R = 2^16 mod 3329 = 2285
128^-1 mod 3329 = 3303
3303 * R mod 3329 = 512
MontgomeryReduce(x * 512) = x * 3303 mod 3329
```

The scaler issue-to-write-commit latency is six cycles: one RAM cycle, four
multiplier cycles, and one synchronous write commit. It accepts 128 pair
requests, 256 lane inputs, 256 lane outputs, and commits 128 pair writes.
Constant 1441 is a legacy `tomont`-related operand and is not used for the
canonical final inverse output.

## 11. Known limitations and M4 requirements

- M2.3b ASIC synthesis and any Fmax selection remain pending.
- The coefficient boundary is indexed and serialized, not a valid/ready stream.
- One core processes one polynomial at a time; no polyvec parallelism is frozen.
- Full ML-KEM KAT completion is not claimed by M3.

M4 must serialize complete preload, start, wait for `done`, and logical
readback; track normal/NTT domains explicitly; propagate sticky errors; and
prevent overwrite of unread results.

Callers must not access physical banks, assume asynchronous reads, assume NTT
output is normal polynomial order, infer physical layout from logical indices,
interpret NTT boundary values as Montgomery-encoded, start while busy, preload
or read while compute is active, consume results before `done`, or depend on a
future clock frequency/Fmax.
