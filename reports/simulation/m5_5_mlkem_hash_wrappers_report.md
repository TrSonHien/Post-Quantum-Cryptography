# M5.5 ML-KEM Hash Wrapper Report

H, G, and J are thin wrappers over SHA3-256, SHA3-512, and SHAKE256(32)
respectively. `run_mlkem_hgj.sh` passes 80 vectors per function and 10,240
total output bytes: H 2,560, G 5,120, J 2,560. G bytes 0..31 precede bytes
32..63 without reversal; J is not SHA3-256.

PRF internally absorbs exactly the 32 seed bytes followed by the nonce byte.
Eta selects only 128 or 192 output bytes. `run_mlkem_prf.sh` passes 128 vectors
(64 per eta), 8,192 eta2 bytes and 12,288 eta3 bytes, including zero/all-ff/
sequential/random seeds and nonce 0/1/255. Invalid eta and busy start error.

XOF internally absorbs exactly `seed||index0||index1`, with both convenience
and generic packed 34-byte inputs tested. `run_mlkem_xof.sh` passes 64 vectors,
5,561 bytes, and 1,155 repeated squeeze requests, including 3-byte requests,
one full 168-byte rate block, and multi-block output. Output backpressure and
continuous stream position pass. M5 performs no matrix interpretation,
rejection sampling, or CBD conversion.
