# FIPS 202 / Keccak Notes

FIPS 202 is the normative source for M5. The frozen implementation mapping is
`S[64*(x+5*y)+z]=A[x,y,z]`; serialized byte `b` maps to state bits
`[8*b +: 8]`. Rho is rotate-left and pi maps the rotated source lane to
`B[y,2*x+3*y]` (coordinates modulo five).

For byte-aligned messages, SHA3 uses delimited suffix `0x06` and SHAKE uses
`0x1f`. XOR the suffix into the first unused rate byte and `0x80` into the last
rate byte. Exact multiples of the rate require a new empty padding block.
SHA3-256/SHA3-512 rates are 136/72 bytes; SHAKE128/SHAKE256 rates are 168/136.
See `docs/04_design/keccak_sha3_shake_contract.md` for the RTL contract.
