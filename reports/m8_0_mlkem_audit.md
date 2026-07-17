# M8.0 ML-KEM Integration and Security Audit

## Scope and result

This audit covers the live M5--M7 services at development HEAD `58a2d77`, with
`8712d7c` as the frozen M7 functional checkpoint.  FIPS 203 Algorithms 16--21
and the independent Python model in `ref_model/python_model/mlkem.py` are the
functional authorities.  The legacy Kyber C tree is historical corroboration,
not final FIPS or CAVP/ACVP authority.

The verified deterministic M7 controllers can be composed without changing
their Algorithms 13--15 results.  M8 must add exact public input checks,
external-RBG ownership, implicit rejection, typed record ordering, and a real
scrub path.  Reset alone is insufficient because live payload arrays are not
overwritten.

## Reused-service register

| Service | Interface and ordering | Lengths and completion | Backpressure/error/reset | Retained payload and scrub gap |
|---|---|---|---|---|
| `mlkem_h` | 32-bit low-byte-first input/output stream | caller-specified input; 32-byte output | ready/valid; stable stalled output; malformed length/keep/last errors; synchronous active-low reset cancels ownership | explicit zeroize clears the 1600-bit sponge and permutation states plus staging/control payload; M5 focused regression PASS |
| `mlkem_g` | same stream convention | caller-specified input; 64-byte output, bytes 0..31 then 32..63 | same M5 contract | same explicit Keccak zeroize contract and verification |
| `mlkem_j` | same stream convention; SHAKE256 | caller-specified input; exactly 32-byte output | same M5 contract | same explicit Keccak zeroize contract and verification |
| d12 decode/encode | 32-bit low-byte-first stream; coefficients in increasing index | one polynomial is 384 bytes; K=3 polyvec is 1152 bytes | full ready/valid; d12 decode reports informational noncanonical evidence; reset cancels | reservoirs/output registers retain prior payload; no zeroize port |
| `kpke_keygen` | input `d`; output `ekPKE` then `dkPKE`, distinguished by `out_type` | 32-byte input; 1184-byte EK and 1152-byte DK | exact full-word stream; stable output stalls; one-cycle done after final acceptance; protocol/subengine errors | explicit zeroize clears all controller-owned d/rho/sigma/EK/DK and coefficient arrays; retained child polynomial, codec, and sampler payload is still blocked |
| `kpke_encrypt` | input `ekPKE || m || r`; ciphertext output | 1248-byte input; 1088-byte output | exact stream; noncanonical evidence is informational; stable stalls; deterministic controller | explicit zeroize clears all controller-owned key/message/randomness/ciphertext and coefficient arrays; retained child payload is still blocked |
| `kpke_decrypt` | input `dkPKE || c`; message output | 2240-byte input; 32-byte output | exact stream; arbitrary correctly sized ciphertext is processed; stable stalls | explicit zeroize clears all controller-owned key/ciphertext/message and coefficient arrays; retained child payload is still blocked |

M5 H/G/J latency depends on input length and stalls but has deterministic
Keccak round count.  M7 measured no-stall ranges are approximately 46,438--
46,738 KeyGen, 54,510--54,810 Encrypt, and 17,755 Decrypt cycles.  SampleNTT
rejection makes complete K-PKE/ML-KEM execution variable-cycle.

## Ownership and integration findings

- Every M7 mode owns private mode-local engines and byte/coefficient arrays.
  Instantiating all three modes structurally duplicates those resources.
- M7 output order is not the M8 public order: KeyGen emits EK then DK, Encrypt
  emits only ciphertext, and Decrypt emits only the recovered message.  M8
  controllers must stage H/G/J results and typed records explicitly.
- M7 never produces an application-visible output before its complete
  deterministic K-PKE algorithm has finished.  Output remains stable under
  backpressure.
- M7 d12 noncanonical evidence is deliberately informational.  Public Encaps
  must perform the FIPS modulus check before entropy or internal invocation.
- No existing early-exit ciphertext comparator or implicit-rejection selector
  exists; both are new M8 functions.
- Byte order is unambiguous: increasing byte address, earliest byte in
  `data[7:0]`, then `[15:8]`, `[23:16]`, `[31:24]`.
- Reset clears control/valid/error ownership but does not erase payload arrays.
  M8 requires explicit overwrite of new buffers and all secret-bearing reused
  state.  Minimal zeroize-only interface extensions must preserve M5--M7
  functional outputs and default operation behavior.
- M7 `done` is a one-cycle pulse after final output acceptance.  M8 public done
  must instead wait for its own mandatory scrub completion.

## Public/internal boundary risks and disposition

Deterministic `d`, `z`, and `m` interfaces are test/integration-only.  The
public top exposes no such inputs: public KeyGen requests 64 external random
bytes and public Encaps requests 32 only after EK acceptance.  Public Decaps
performs length and stored-hash checks, while a correctly sized modified
ciphertext proceeds through internal implicit rejection without public error.

No normal public Decaps modulus check is added.  No reject flag or mask is a
public port.  `J` remains SHAKE256 with input exactly `z || c`; `G` splits its
first half as K and second half as r.  These decisions remove the identified
API, byte-order, and algorithm-selection ambiguities.

## Audit conclusion

The functional integration boundary is ready.  The security boundary is
frozen but not yet implemented: M8.1 must prove exact layout/check/compare and
physical scrub before internal or public M8 completion can be claimed.  There
is no synthesis, area, timing-closure, Fmax, final KAT, or CAVP/ACVP claim.

## 2026-07-15 continuation audit

The dirty M8 baseline reproduces its original smoke and focused claims.  The
classification after source and regression audit is:

- complete and verified: M8.0 contract at `54910f6`, exact DK boundary tests,
  constant-work 1088-byte compare/32-byte select, and M5 H/G/J explicit scrub;
- implemented but insufficiently tested: M8.1--M8.5 behavioral RTL, public
  wrappers, typed top, reset/backpressure paths, and controller-owned scrub;
- incomplete: required 12/16/16/32/8 differential depths, internal/public
  chain TBs, cycle accounting, nonrecursive M2/Python closure, and M8.6;
- known failing: the reset-clears-payload shortcut was rejected by M4 and
  removed; the restored M4 regression passes 26/26;
- blocked by physical scrub: M7 child `poly_workspace` even/odd banks,
  `ntt_pingpong_banks` RAMs, NTT/INTT preload arrays, `poly_reduce_pipe`
  memories where instantiated, fixed-latency payload/metadata stages, and
  codec/sampler retained payload reached by secret K-PKE operations;
- unexpected/unnecessary: no unexpected source file was found; counting reset
  payload retention as a zeroize check was corrected in the runner.

M7 controller-owned scrub covers 21,408 locations.  That number deliberately
does not claim the unresolved child payload.  M8 remains blocked until those
child instances receive explicit overwrite control and independent tests.

## 2026-07-17 academic-baseline disposition

The preceding physical-scrub observations remain accurate, but they are not a
functional completion gate for the reduced academic M8 milestone. M8-local
control state and selected secret buffers are explicitly cleared, stale outputs
are suppressed after reset or zeroize, and existing M5/M7 zeroize propagation is
preserved. Exhaustive physical destruction of retained lower-level datapath
payload is future security-hardening work; no FIPS destruction-compliance or
side-channel-resistance claim is made.
