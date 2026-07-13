# M5.2 Incremental Sponge Report

`run_keccak_sponge_ctx.sh` passes 320 SHA3/SHAKE vectors and 21,174 byte
comparisons across all required message and output rate boundaries. Absorb uses
irregular 1/2/3/4-byte transfers; SHAKE output is split over 3,601 squeeze
requests, including partial words and multiple rate blocks. Concatenated chunks
match one-shot `hashlib` output exactly.

Output stability under deterministic stalls passes. Seven illegal protocol
classes pass. Reset cancellation is exercised at every permutation round and
while output is stalled; context, done, and output valid remain invalid until a
fresh init. Padding uses `0x06`/`0x1f` plus final `0x80`; empty, exact-rate, and
multi-rate cases all pass.
