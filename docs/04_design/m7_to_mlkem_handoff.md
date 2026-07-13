# M7 to M8 ML-KEM Handoff

## M7 boundary

M7 provides deterministic, byte-exact K-PKE Algorithms 13--15 through
standalone KeyGen, Encrypt, and Decrypt controllers.  It does not provide a
normal application API and does not implement ML-KEM Algorithms 16--21.

## KeyGen_internal

M8 supplies independent 32-byte d and z values.  M7 K-PKE.KeyGen consumes d
and supplies ekPKE=1184 bytes and dkPKE=1152 bytes.  M8 computes H(ekPKE),
composes the final ML-KEM decapsulation key, and owns final ek/dk interface and
RBG behavior.  z never enters M7 KeyGen.

## Encaps_internal

M8 supplies a checked ek, 32-byte m, and the derived 32-byte r.  M7 Encrypt
supplies the deterministic 1088-byte ciphertext.  M8 owns encapsulation-key
type/modulus checking, `G(m||H(ek))`, shared-secret extraction, approved-RBG
behavior, and final internal/public encapsulation semantics.

## Decaps_internal

M8 parses the ML-KEM decapsulation key and supplies dkPKE and ciphertext to M7
Decrypt, obtaining m_prime.  It derives re-encryption randomness and invokes
M7 Encrypt to obtain c_prime.  M8 owns ciphertext comparison, implicit
rejection, `J(z||c)`, constant-time shared-secret selection, key/hash/length
checks, and all public decapsulation semantics.

## Required integration rules

- Preserve `A[row,col]=SampleNTT(rho||col||row)` and request transpose through
  the explicit orientation contract; never swap workspace order silently.
- Preserve KeyGen `G(d||03)` and all KeyGen/Encrypt nonce schedules.
- Treat K-PKE d12 noncanonical evidence as informational, not as the complete
  ML-KEM check result.
- Honor valid/ready, busy, done, error, typed output, and exact byte ordering.
- Do not assume a fixed SampleNTT cycle count or expose physical polynomial
  banks.
- Do not expose deterministic K-PKE entry points to ordinary applications.
- Do not claim that synchronous reset erases secret arrays.  M8/top-level must
  implement an explicit zeroize/scrub policy and define its completion proof.
- Do not claim final KAT validation until authoritative NIST CAVP/ACVP vectors
  are present and passing.

M8 entry requires all standalone K-PKE differential and roundtrip tests,
matrix/transpose and nonce proofs, protocol/reset/backpressure tests, unified
M7 plus preservation regressions, clean artifacts/process state, and this
frozen handoff.  M2.3b server synthesis remains independent and pending.
