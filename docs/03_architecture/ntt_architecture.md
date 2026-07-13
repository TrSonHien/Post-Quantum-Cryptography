# NTT Architecture

Use this file for NTT, INTT, butterfly, twiddle ROM, and memory scheduling architecture notes.

## Architecture Priority

NTT/INTT and base multiplication follow the project-wide priority:

```text
1. Correctness
2. Timing closure / high operating frequency / Fmax
3. Throughput
4. Area
```

The preferred basemul architecture is a high-throughput pipelined datapath.
Sequential/resource-shared basemul is allowed only as a comparison or reference
implementation; it is not the main direction.

## Pipelined Basemul Direction

The main `basemul_unit` should accept a new valid transaction every cycle when
upstream data is available and downstream logic can accept the result. Later
poly-level pointwise multiplication blocks should be designed to feed pipelined
basemul every cycle when possible.

The current main basemul direction assumes:

- fixed coefficient interface: unsigned canonical `KYBER_Q_WIDTH` values
- valid-only pipeline interface
- no backpressure in the first implementation
- latency documented at the module boundary
- write address and output index alignment delayed by the basemul pipeline
  latency

## M1 v0.1 NTT/INTT baseline

The frozen baseline accepts one radix-2 butterfly per cycle with `II=1`.
Forward NTT has seven 128-butterfly stages (`len=128,64,32,16,8,4,2`). INTT has
seven 128-butterfly stages (`len=2,4,8,16,32,64,128`) plus 256 final scaling
operations. Exact arithmetic pipeline depth is selected in M3; multi-lane
variants are also deferred to M3.

Storage is out-of-place ping-pong with one-cycle synchronous reads and two
source plus two destination banks. At every cycle the schedule reads one
coefficient from each source bank and writes one result to each destination
bank. Source/destination roles swap after each committed stage.

## Conflict-free bank and address mapping

Let logical coefficient index `i` have bits `i[7:0]`. A stage with butterfly
distance `L=2^p` pairs `i` with `i xor 2^p`, where the lower endpoint has
`i[p]=0`. Define `remove_bit(i,p)` as the 7-bit value obtained by deleting bit
`p` from `i` while retaining all other bits in order.

For the first source layout:

```text
bank(i) = i[p]
addr(i) = remove_bit(i,p)
```

For a transition from current distance `2^p` to next distance `2^r`:

```text
bank(i) = i[p] xor i[r]
addr(i) = remove_bit(i,r)
```

The destination layout becomes the source layout of the next stage. For the
last-stage destination, use `bank(i)=i[p]` and `addr(i)=remove_bit(i,p)`; drain
logic reconstructs logical indices from that map.

### Proof

1. Current butterfly outputs differ only in bit `p`; therefore transition bank
   differs by one, so exactly one result writes each destination bank.
2. The two current outputs retain different bit `p` in `remove_bit(i,r)` because
   adjacent stages have `p != r`; therefore their destination addresses differ.
3. A next-stage pair differs only in bit `r`; transition bank differs by one and
   `remove_bit(i,r)` is equal, so the next read obtains one operand from each
   source bank at the same 7-bit address.
4. Removing bit `r` is injective within either bank: the only two logical indices
   sharing an address differ in `r`, and thus occupy opposite banks.
5. Source and destination are different physical sets, eliminating read/write
   collisions. Induction across every transition proves conflict freedom.

This proof applies to both decreasing-distance NTT and increasing-distance INTT.

## Complete stage mapping table

Forward NTT:

| Stage | `L` | Source layout | Destination layout | Butterflies | Reads | Writes |
|---:|---:|---|---|---:|---:|---:|
| 0 | 128 | `b=i7, a=rm7` | `b=i7^i6, a=rm6` | 128 | 256 | 256 |
| 1 | 64  | `b=i7^i6, a=rm6` | `b=i6^i5, a=rm5` | 128 | 256 | 256 |
| 2 | 32  | `b=i6^i5, a=rm5` | `b=i5^i4, a=rm4` | 128 | 256 | 256 |
| 3 | 16  | `b=i5^i4, a=rm4` | `b=i4^i3, a=rm3` | 128 | 256 | 256 |
| 4 | 8   | `b=i4^i3, a=rm3` | `b=i3^i2, a=rm2` | 128 | 256 | 256 |
| 5 | 4   | `b=i3^i2, a=rm2` | `b=i2^i1, a=rm1` | 128 | 256 | 256 |
| 6 | 2   | `b=i2^i1, a=rm1` | `b=i1, a=rm1` | 128 | 256 | 256 |

Inverse NTT:

| Stage | `L` | Source layout | Destination layout | Butterflies | Reads | Writes |
|---:|---:|---|---|---:|---:|---:|
| 0 | 2   | `b=i1, a=rm1` | `b=i2^i1, a=rm1` | 128 | 256 | 256 |
| 1 | 4   | `b=i2^i1, a=rm1` | `b=i3^i2, a=rm2` | 128 | 256 | 256 |
| 2 | 8   | `b=i3^i2, a=rm2` | `b=i4^i3, a=rm3` | 128 | 256 | 256 |
| 3 | 16  | `b=i4^i3, a=rm3` | `b=i5^i4, a=rm4` | 128 | 256 | 256 |
| 4 | 32  | `b=i5^i4, a=rm4` | `b=i6^i5, a=rm5` | 128 | 256 | 256 |
| 5 | 64  | `b=i6^i5, a=rm5` | `b=i7^i6, a=rm6` | 128 | 256 | 256 |
| 6 | 128 | `b=i7^i6, a=rm6` | `b=i7, a=rm7` | 128 | 256 | 256 |

Here `rmN` means `remove_bit(i,N)`. Every row has one read per source bank and
one write per destination bank per cycle.

## Cycle and bandwidth tables

Let `L_bf` be butterfly arithmetic latency after the one-cycle memory read.
Let `L_scale` be INTT scaling-pipeline latency. Stage drain costs
`1 + L_bf` cycles from final read issue through final committed write; it may be
implemented as pipeline drain, not an idle bubble hidden from accounting.

| Operation | Stages/ops | Issue cycles | Read coefficients | Write coefficients | Baseline total |
|---|---:|---:|---:|---:|---:|
| NTT | 7 x 128 butterflies | 896 | 1,792 | 1,792 | `896 + 7*(1+L_bf)` plus command/response handshakes |
| INTT butterflies | 7 x 128 | 896 | 1,792 | 1,792 | `896 + 7*(1+L_bf)` |
| INTT final scale | 128 coefficient pairs | 128 | 256 | 256 | 135 cycles through final ownership, 136 through public `done` |
| Full INTT | above combined | 1,024 pair issues | 2,048 | 2,048 | 1,090 measured start-to-`done` cycles |

Peak active-stage bandwidth is two 12-bit reads and two 12-bit writes each
cycle (24 read bits/cycle and 24 write bits/cycle). The final scaler uses two
parallel `mod_mul_pipe` lanes with operand 512. No architectural completion is
emitted until the last destination write commits and final result ownership is
established.

When a poly-level block writes basemul results back to a polynomial buffer, its
write address, coefficient-pair index, zeta index, and output valid strobes must
be delayed by the same latency as the basemul data path. If future `mod_mul` or
Montgomery reduction becomes pipelined, those extra cycles must be reflected in
the basemul and poly-level alignment logic.
