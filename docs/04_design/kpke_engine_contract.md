# K-PKE Engine Contract v0.1

## Scope and authority

This contract freezes deterministic ML-KEM-768 K-PKE Algorithms 13--15 from
NIST FIPS 203.  The independent Python model is the executable oracle.  Legacy
Kyber C is supporting evidence only.  ML-KEM Algorithms 16--21, implicit
rejection, re-encryption checking, and public input checks are outside M7.

Parameters are `n=256`, `q=3329`, `k=3`, `eta1=eta2=2`, `du=10`, and `dv=4`.
Lengths are d/m/r/rho/sigma=32, ekPKE=1184, dkPKE=1152, and ciphertext=1088
bytes.

## External transaction contract

The standalone controllers use synchronous active-low `rst_n`, a command
acceptance handshake, exact-length 32-bit input streams, and typed 32-bit
output streams.  Earliest bytes occupy `data[7:0]`; legal keeps are contiguous
low masks.  Inputs and outputs transfer only on valid and ready.  Output data,
keep, last, and type remain stable while stalled.  `done` is one cycle and is
emitted only after the final output transfer is accepted.  A command while
busy, invalid mode/type, malformed keep/last/length, excess input, illegal
access, or child error sets `error` and invalidates the transaction.

Fixed-size internal arrays bridge streaming M5/M6 engines to indexed M4
engines.  They are architectural logical storage, not exposed physical banks.
Coefficient writes and reads are serialized in logical order.  M4 synchronous
result reads have one-cycle latency.  Major child boundaries are registered;
there is no long combinational valid/ready chain across engines.

## Matrix and nonce helpers

The sole matrix definition is:

```text
A_ENTRY(row,col) = SampleNTT(rho || col_byte || row_byte)
```

`kpke_matrix_row_sampler` emits elements 0,1,2 of one complete NTT polyvec.
For `transpose=0`, element `col` uses `(index0,index1)=(col,row)`.  For
`transpose=1`, element `col` uses `(row,col)`, representing `A[col,row]`.
Exactly one SampleNTT child is instantiated and exactly three polynomials are
committed before done.  SampleNTT is variable-cycle with no functional bound.

`kpke_noise_vector_sampler` emits one complete NORMAL polyvec using one noise
child.  Element `i` uses `start_nonce+i`; `next_nonce=start_nonce+3` modulo
256.  M7 uses only non-wrapping ranges.  Eta is explicit and carries no
algorithm-specific hidden meaning.

## Algorithm/domain schedule

KeyGen hashes exactly `d || 8'h03` through G, with address-increasing d bytes
and the literal numeric k byte last.  G output bytes 0..31 are rho and 32..63
are sigma.  `s,e` are NORMAL; `s_hat,e_hat,A,t_hat` and dot products are NTT.
It performs one G, nine SampleNTT, six noise, two polyvec NTT, three dot, and
three NTT add operations.  The packed keys are
`Encode12(t_hat[0..2])||rho` and `Encode12(s_hat[0..2])`.

Encrypt decodes `t_hat` as NTT and retains noncanonical evidence as metadata.
It samples transpose rows, and uses NORMAL `y,e1,e2,mu,u,v`, NTT `y_hat`, and
NTT dot products.  It performs nine SampleNTT, seven noise, one polyvec NTT,
four dot, four INTT, five NORMAL adds, and one message conversion.  Ciphertext
is d10 compressed `u[0..2]` followed by d4 compressed `v`.

Decrypt decodes/decompresses `u_prime,v_prime` as NORMAL and d12 `s_hat` as
NTT.  It performs one polyvec NTT, one dot, one INTT, one NORMAL subtraction,
and one message conversion.  D12 noncanonical evidence is informational.

## Latency, initiation interval, and critical paths

Each standalone controller accepts no new operation while busy, so its II is
one complete operation.  Exact command-to-done latency is measured, not
predicted, and includes input, child loads, variable sampler work, arithmetic,
packing, and accepted output.  SampleNTT makes total latency data-dependent
through public rejection sampling; cryptographic secret coefficients do not
shorten arithmetic schedules.  Expected integration critical paths are FSM
decode/buffer routing and child-interface fanout.  Arithmetic critical paths
remain within the already registered M2--M6 engines.  No synthesis, area,
timing-closure, throughput-per-second, or Fmax claim follows from this contract.

## Reset and sensitive state

Reset cancels child ownership and invalidates counters, completeness, domain,
output-valid, and transaction metadata.  Payload arrays need not be reset.
This is logical invalidation only, not physical erasure.  Sensitive/ephemeral
payload includes d, sigma, s/e and transforms, dkPKE, r, y/e1/e2 and transforms,
decoded secret keys, and the recovered message polynomial.  M8/top-level must
provide an explicit zeroize/scrub command or equivalent security integration;
functional K-PKE correctness does not depend on automatic post-operation scrub.

## Verification and completion

Independent tests prove exact matrix input bytes and transpose selection,
nonce progressions, every intermediate domain transition, exact final bytes,
reset/restart, malformed protocol handling, and output stability under stalls.
Tracked smoke vectors are compact; bulk vectors are deterministic temporary
artifacts.  Project Python vectors are not final authoritative CAVP/ACVP KATs.
