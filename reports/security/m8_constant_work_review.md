# M8 Constant-Work Structural Review

The internal Decaps controller always invokes Decrypt, G, J, and re-encryption.
Its compare loop has exactly 1,088 serialized byte iterations and its select
loop exactly 32 byte iterations.  Selection uses an all-zero/all-one byte mask;
there is no reject output, secret-dependent index, early termination, output
length, or mismatch error.  First/middle/final/all mismatch tests pass, and the
reject accumulator/mask are cleared before K output.

This is not full side-channel certification.  SampleNTT rejection remains
data-dependent, complete ML-KEM latency is variable, physical implementation
leakage is unassessed, and retained child payload currently blocks zeroization
closure.
