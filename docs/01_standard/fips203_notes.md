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
