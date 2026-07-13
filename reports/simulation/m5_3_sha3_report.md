# M5.3 SHA3 Report

The thin SHA3-256 and SHA3-512 wrappers share `keccak_hash_stream` and the
single sponge/permutation implementation. Each wrapper passes 80 deterministic
messages: empty, `abc`, zero byte, all byte values, every required rate
boundary, multi-rate messages, and at least 64 seeded random cases.

SHA3-256 compares 2,560 digest bytes and SHA3-512 compares 5,120 digest bytes
against Python `hashlib`. The pure-Python sponge independently cross-checks the
same functions before vectors are emitted. Fixed lengths and suffix `0x06` are
enforced.
