# M7 Deterministic K-PKE Completion Report

## Status and architecture

M7.0 through M7.6 are complete at the functional RTL boundary.  The selected
architecture is three standalone deterministic mode controllers.  Each mode
serializes one matrix sampler, one noise path, one polyvec NTT, one dot-product
engine, one INTT/add/sub path as required, and shared mode-local codecs.  A
`kpke_core` wrapper was intentionally not added because merely instantiating all
three verified controllers would duplicate resources without real sharing.
This baseline is resource-conscious within a mode, not claimed area-optimal.

## Matrix, nonce, domain, and format proof

`A[row,col]=SampleNTT(rho||col||row)`. KeyGen uses `(col,row)` for all nine
entries. Encrypt transpose row i uses `(i,0)`, `(i,1)`, `(i,2)` and retains
polyvec element order. The 96-row helper test performs 77,568 coefficient and
10,404 exact sampler-input-byte checks. KeyGen nonces are 0..5; Encrypt nonces
are 0..6; helper nonce/reset tests pass 16,128 coefficients and 66 launches.

All objects are unsigned canonical residues. Sampling/message/u/v are NORMAL;
A, decoded t/s keys, transformed vectors, dots, and t_hat are NTT. Every
transition is performed by the verified M4 adapter and checked against Python.
Key format is 1152 d12 t_hat bytes plus rho and 1152 d12 s_hat bytes;
ciphertext is 960 d10 u bytes plus 128 d4 v bytes. D12 noncanonical evidence
is informational inside K-PKE; M8 owns public ML-KEM input checking.

## Algorithm evidence and cycles

KeyGen performs 1 G over exactly `d||03`, 9 SampleNTT, 6 noise, 2 polyvec NTT,
3 dot, and 3 NTT-add operations. Twenty vectors pass 76,800 coefficient and
48,000 byte comparisons. Stalled command-to-done cycles are 46,486--46,787.

Encrypt performs 9 SampleNTT, 7 noise, 1 polyvec NTT, 4 dot, 4 INTT, 5 add, and
1 message conversion. Twenty vectors pass 92,160 coefficient and 22,400 byte
comparisons. Stalled cycles are 54,533--54,832.

Decrypt performs 1 polyvec NTT, 1 dot, 1 INTT, 1 subtract, and 1 message
conversion. Twenty vectors pass 61,440 coefficient and 640 byte comparisons.
Stalled cycles are 17,755--17,756.

Twenty actual-RTL KeyGen-to-Encrypt-to-Decrypt roundtrips pass 69,120 byte
comparisons. Roundtrip no-stall cycles are 46,438--46,738, 54,510--54,810, and
17,755 respectively. Project vectors regenerate byte-identically.

## Control, security, and regression

The 35-check protocol test resets during input, hash/decode, sampler, NTT,
matrix/dot, INTT, add/sub, codec, and stalled output; cancellation and clean
restart pass. Malformed keep/last, command while busy, exact output length,
one-cycle done, and stable backpressure payload pass.

Reset invalidates control, ownership, completeness, domain, and valid metadata
but does not physically erase payload arrays. M8/top-level must add explicit
zeroization/scrub policy and proof. Functional K-PKE does not depend on scrub.

Unified M7 regression passes 13/13 programs, 6,102,998 checks, 150,564 byte and
324,096 coefficient comparisons. Full M6/M5/M4/M3 and Python regressions pass.
M2.3b server synthesis remains pending. There is no full ML-KEM completion,
authoritative final CAVP/ACVP KAT, synthesis, area, timing-closure, or Fmax
claim.

## M8 entry

Algorithms 13--15 are bit-exact against Python; matrix/transpose, nonce,
domain, formats, standalone differential, roundtrip, reset/backpressure,
reproducibility, and unified preservation gates pass. The frozen handoff is
`docs/04_design/m7_to_mlkem_handoff.md`. M8 is entry-ready but not started.
