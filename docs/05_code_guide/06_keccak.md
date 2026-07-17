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

### Historical note

The current ML-KEM-768 release uses SHAKE256/XOF services.  Superseded
SHAKE128 compatibility RTL remains available only in Git history before
`pre-legacy-prune-b683bd7`.

### Reading notes

- Use the module catalog for parents, children, domain, handshake, state ownership, TB, and runner links.
- Treat named domain signals as authoritative; NORMAL and NTT are distinct representations.
- Fixed cycle counts are stated only where the implementation contract proves them; controllers otherwise use done/busy completion.

### Dependency graph, domains, and reading order

Read `keccak_round`, `keccak_f1600_core`, `keccak_sponge_ctx`,
`keccak_hash_stream`, then SHA3/SHAKE and ML-KEM H/G/J/PRF/XOF wrappers.  Byte
streams use the documented low-byte-first order; state arrays represent Keccak
lanes rather than polynomial domains.  Sponge state is owned by its context
until absorb/permutation/squeeze completion.  Use M5 regression and the H/G/J
tests in the catalog; do not confuse wrapper completion with a full public
ML-KEM controller transaction.
