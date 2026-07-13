# Keccak Architecture

M5 selects one shared combinational Keccak round datapath and one iterative
1600-bit permutation state register, executing one round per cycle for all 24
rounds. A reusable byte-stream sponge context owns that core for full absorb
blocks, final padding, and additional squeeze blocks. SHA3, SHAKE, and ML-KEM
functions are thin controllers/wrappers and never duplicate the permutation.

State, stream, mode, padding, reset, ownership, and continuing-squeeze rules are
frozen in `docs/04_design/keccak_sha3_shake_contract.md`. This is a functional
baseline pending focused synthesis evidence; no one-round timing claim exists.
