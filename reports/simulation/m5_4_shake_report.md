# M5.4 SHAKE Report

The thin SHAKE128 and SHAKE256 one-shot wrappers share the context. Each passes
80 deterministic input/output pairs and 6,747 byte comparisons against
`hashlib`, including empty/`abc`, all input rate boundaries, 1/2/3/4/31/32/33
byte outputs, exact and crossed rate outputs, and multi-rate output.

Direct-context testing absorbs the same messages in irregular chunks and emits
the SHAKE vectors over 3,601 total repeated requests across all modes. SHAKE
chunks preserve the continuous stream across request and rate boundaries.
Suffix `0x1f`, backpressure stability, reset invalidation, and restart pass.
