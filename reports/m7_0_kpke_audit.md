# M7.0 K-PKE Integration Audit

## Scope and result

The audit covers the live M4 polynomial/polyvec engines, M5 `G`, and M6
codec/sampler engines at checkpoint `0407afd`.  The result is suitable for a
serialized M7 baseline without changing M4--M6 RTL.  No unresolved
mathematical, representation, matrix-index, nonce, or input-checking decision
remains.  Physical resource sharing across standalone mode controllers is not
claimed; each controller is independently verifiable and a later arbitration
wrapper may select them.

## Reused engine register

| Engine | Input -> output domain | Load/result protocol | Completion and restart | Measured compute cycles |
|---|---|---|---|---:|
| `poly_workspace` | caller-declared canonical NORMAL/NTT | indexed writes; one-cycle indexed reads | completeness/owner metadata invalidated by reset; payload unreset | storage primitive |
| `poly_add_pipe`, `poly_sub_pipe` | equal NORMAL or equal NTT -> same domain | two complete indexed polynomials; synchronous result reads | busy through publish; one-cycle done; release before overwrite | 134 |
| `poly_ntt_pipe` | NORMAL -> NTT | complete indexed polynomial | child M3 transaction is fully hidden | 1473 |
| `poly_intt_pipe` | NTT -> NORMAL | complete indexed polynomial | child M3 transaction is fully hidden | 1608 |
| `polyvec_ntt_pipe` | three NORMAL -> three NTT | elements 0,1,2, indexed | one shared polynomial NTT child | 5980 |
| `polyvec_intt_pipe` | three NTT -> three NORMAL | elements 0,1,2, indexed | one shared polynomial INTT child | 6385 |
| `polyvec_basemul_acc_pipe` | two NTT polyvecs -> one NTT polynomial | two operands, elements 0,1,2; synchronous result reads | three exact MultiplyNTTs plus two canonical accumulations | 2757 |
| `mlkem_g` | byte stream -> 64 raw bytes | 32-bit low-byte-first valid/ready | done after final output acceptance | variable with input/backpressure |
| `mlkem_noise_sampler` | seed, nonce, eta -> NORMAL polynomial | start plus coefficient stream | 256 accepted coefficients; reset cancels | eta2 about 385 aggregate M6 average |
| `mlkem_sample_ntt` | seed, index0, index1 -> NTT polynomial | start plus coefficient stream | 256 accepted coefficients; continuing XOF; no functional bound | 1124--1256 in M6 closure set |
| message converters | 32 bytes <-> NORMAL polynomial | low-byte-first stream | exact length; done after final accepted transfer | variable with stalls |
| poly/polyvec codecs | canonical coefficients <-> raw bytes | serialized element 0,1,2 | exact length; d12 decode reports noncanonical evidence | measured in M6 reports |
| K-PKE format adapters | encoded segment words -> identical ordered words | 32-bit full-word stream | exact word count and segment marker | one registered word buffer |

All M4 indexed result ports have one-cycle response latency.  M6 streaming
outputs remain stable under backpressure.  A caller must retain every complete
object until the last dependent transaction finishes; child output storage is
not an implicit caller workspace.

## Frozen integration semantics

Architectural coefficients are unsigned canonical residues in `[0,3328]`.
NORMAL and NTT are semantic domains and are never inferred from encoded bytes.
`A_ENTRY(row,col)` is exactly `SampleNTT(rho || col || row)`.  KeyGen requests
rows with `(index0,index1)=(col,row)`.  Encrypt transpose row `row` requests
`(index0,index1)=(row,col)`, thereby selecting `A[col,row]` without rearranging
polyvec element storage.

KeyGen noise uses sigma nonces 0,1,2 for `s` and 3,4,5 for `e`, all eta2 for
ML-KEM-768.  Encrypt uses r nonces 0,1,2 for `y`, 3,4,5 for `e1`, and 6 for
`e2`, all eta2.  Eta controls PRF output length and is not absorbed.

K-PKE decode follows Algorithm 14/15 primitive semantics.  D12 inputs reduce
modulo q and noncanonical evidence is informational.  M7 does not reject or
alter arithmetic for that evidence.  Length, keep, last, mode, ownership, and
subengine failures remain protocol errors.  M8 owns the public ML-KEM input
checks.

## Integration risks and disposition

| Risk | Audit disposition |
|---|---|
| row/column reversal | explicit index0/index1 registers and matrix helper tests |
| A used instead of transpose | transpose flag changes index bytes, never polyvec order |
| nonce reuse/skip or eta mismatch | explicit start nonce, element counter, and next nonce |
| NORMAL/NTT confusion | every buffer and child load has a fixed documented domain |
| premature result reuse | controller phases copy complete results before release |
| noncanonical D12 abort | metadata only; arithmetic continues |
| byte reversal | address-increasing bytes, earliest byte in `data[7:0]` |
| output overwrite | separate live arrays or proven phase reuse only |
| stale state after reset | reset clears FSM/counters/valid/completeness; payload is invalid |
| serialized-engine deadlock | single owner per child and bounded TB watchdogs |

Reset provides logical invalidation, not physical zeroization.  Seed, secret,
noise, and decoded-key arrays may retain payload bits after reset.  M8/top-level
integration must provide an explicit scrub/zeroize policy.

## Documentation discrepancies

At audit time root `README.md` still labeled the current milestone M1,
`rtl/README.md` said M5 was pending, and the FIPS tracking rows for NTT and
MultiplyNTTs retained pre-closure wording.  These are documentation drift, not
live RTL contradictions, and are scheduled for M7.6 synchronization.

No tracked simulation artifact, obsolete stash, stale simulator, unexpected
worktree change, or frozen-worktree modification was found at entry.
