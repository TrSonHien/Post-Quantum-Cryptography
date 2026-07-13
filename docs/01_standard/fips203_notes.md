# FIPS 203 Notes

Use this file for ML-KEM notes from FIPS 203.

## Topics To Capture

- ML-KEM-768 parameters
- KeyGen behavior
- Encaps behavior
- Decaps behavior
- Byte encoding and decoding rules
- Required randomness and hash/XOF functions
- Test-vector implications

## Open Questions

- Which KAT source will be treated as the project baseline?

## M6 frozen Algorithms 3--8

Bits and bytes are LSB-first within each byte. Compression/decompression use
exact integer nearest rounding with no floating point. ByteDecode12 reduces
the raw 12-bit segment modulo 3329 and separately exposes noncanonical input;
it does not reject. CBD emits canonical `x-y mod q`. SampleNTT parses d1 then
d2, rejects values at least q without reduction, suppresses d2 only when d1
fills index 255, and continues a single SHAKE128 context without a functional
iteration bound. Full M6 differential regression is recorded in the M6.6
report; final external CAVP/ACVP validation remains pending.

## M7 frozen Algorithms 13--15

K-PKE.KeyGen hashes exactly `d||03`; matrix entries are
`A[row,col]=SampleNTT(rho||col||row)`. Encrypt transpose row `i` therefore uses
inputs `rho||i||0`, `rho||i||1`, and `rho||i||2`. KeyGen noise nonces are 0--5
and Encrypt nonces are 0--6; ML-KEM-768 uses eta2 throughout these schedules.
All NORMAL/NTT transitions and exact ekPKE/dkPKE/ciphertext bytes pass the
independent Python differential and chained roundtrip tests. D12 noncanonical
evidence remains informational inside Algorithms 14/15; M8 owns ML-KEM input
checks. Final authoritative CAVP/ACVP validation remains pending.
