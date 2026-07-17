# Keccak and hash services

## keccak

### Purpose
FIPS 202 SHA3/SHAKE or FIPS 203 H/G/J/PRF/XOF support

### Active modules

- `keccak_f1600_core`
- `keccak_hash_stream`
- `keccak_round`
- `keccak_sponge_ctx`
- `mlkem_g`
- `mlkem_h`
- `mlkem_j`
- `mlkem_prf`
- `mlkem_xof`
- `sha3_256_stream`
- `sha3_512_stream`
- `shake256_stream`

### Retained support / legacy modules

- `shake128_stream`

### Reading notes

- Use the module catalog for parents, children, domain, handshake, state ownership, TB, and runner links.
- Treat named domain signals as authoritative; NORMAL and NTT are distinct representations.
- Fixed cycle counts are stated only where the implementation contract proves them; controllers otherwise use done/busy completion.
