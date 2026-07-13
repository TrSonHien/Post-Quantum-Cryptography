# M6.1 ByteDecode Report

`run_byte_decode_poly_pipe.sh` passes 68 arrays per d=1,4,10,12: 69,632 value
comparisons. A separate 256-segment d12 case injects raw 3329, 3330, 4095 and
additional noncanonical values; every result equals raw modulo 3329 and
`noncanonical_seen` asserts without rejecting the transaction.

The decoder uses a 64-bit bounded LSB-first reservoir, verifies full-word
length/last protocol, emits indices 0 through 255 in order, and remains stable
under deterministic output stalls. Inputs were Python ByteEncode outputs and
expected values came from the independent FIPS codec model.
