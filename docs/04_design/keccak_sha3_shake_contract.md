# Keccak/SHA3/SHAKE Contract v0.1

## Authority and scope

FIPS 202 defines the permutation, sponge, padding, SHA3, and SHAKE semantics.
FIPS 203 defines ML-KEM H, G, J, PRF, and XOF. SP 800-185 supports continuing
XOF API behavior; cSHAKE, KMAC, TupleHash, and ParallelHash are excluded.

## State and byte representation

The state is 1600 bits arranged as 25 64-bit lanes `A[x,y]`, with `x,y` in
0..4. `lane_index=x+5*y` and
`state[64*lane_index +: 64]=A[x,y]`. Serialized byte offset `b` maps to
`state[8*b +: 8]`; bytes within a lane are little-endian. Thus byte 0 is the
low byte of A[0,0], byte 7 its high byte, and byte 8 the low byte of A[1,0].

The 32-bit stream uses the same order: the earliest byte is `data[7:0]`, then
`[15:8]`, `[23:16]`, and `[31:24]`. Legal keep masks are only `0001`, `0011`,
`0111`, and `1111`; holes and zero keep are errors. Output keep marks the valid
low bytes. `out_data`, `out_keep`, and `out_last` remain stable whenever valid
is high and ready is low.

## Keccak-f[1600]

Each of 24 rounds performs theta, rho, pi, chi, and iota in that order:

```text
C[x] = xor_y A[x,y]
D[x] = C[x-1] xor ROTL64(C[x+1],1)
A_theta[x,y] = A[x,y] xor D[x]
B[y,2*x+3*y] = ROTL64(A_theta[x,y], r[x,y])
A_chi[x,y] = B[x,y] xor ((not B[x+1,y]) and B[x+2,y])
A_out[0,0] = A_chi[0,0] xor RC[round]
```

Coordinates are modulo five. Rotation offsets and all 24 round constants are
the FIPS 202 tables. Rotations are unsigned 64-bit rotate-left operations.
The functional baseline has one combinational round datapath, one 1600-bit
permutation state register, and 24 sequential rounds. There is no unrolling or
multi-context interleaving. Exact measured public edge latency is recorded by
M5.1 verification; no timing closure is implied.

## Modes and padding

| Mode | Rate bytes | Capacity bits | Suffix | Output |
|---|---:|---:|---:|---|
| SHA3-256 | 136 | 512 | `0x06` | exactly 32 bytes |
| SHA3-512 | 72 | 1024 | `0x06` | exactly 64 bytes |
| SHAKE128 | 168 | 256 | `0x1f` | positive variable length |
| SHAKE256 | 136 | 512 | `0x1f` | positive variable length |

For byte-aligned input, the suffix is XORed into the first unused rate byte and
`0x80` into the last rate byte. If both are the same byte, the values naturally
combine to `0x86` for SHA3 or `0x9f` for SHAKE. A message ending exactly at a
rate boundary first permutes that full data block, then uses a new empty padding
block. Absorb and squeeze access only the rate; capacity bytes are never direct
stream input or output.

## Incremental context protocol

An accepted init selects a mode and explicitly zeros state and all offsets.
Zero or more absorb beats follow. A full rate block owns the single permutation
core until its permutation completes; ready is low while storage or the core is
unavailable. Finalize is a separate command, applies padding, permutes, and
enters squeeze phase. Absorb after finalize and squeeze before finalize error.

A positive squeeze request emits exactly its byte length. Multiple SHAKE
requests continue the same stream and preserve the byte offset. Crossing a rate
boundary launches another permutation and resumes from offset zero. SHA3
squeezing is restricted to its one fixed digest. Commands never overlap core
ownership and stale done pulses cannot be consumed by another phase.

Fixed-length one-shot commands consume exactly `msg_len_bytes`. Each non-final
beat is full; the final keep matches the remainder and `in_last` is accepted
only with the final byte. Empty messages provide no input beat and finalize
automatically. Early/missing last, excess bytes, invalid keep/mode/output length,
or a command while busy sets error and invalidates the operation. Done pulses
only after the final output beat is accepted.

## Reset and security control

`rst_n` is synchronous active-low. Reset clears FSMs, counters, valid flags,
context validity, busy, done, and error; payload state need not be reset because
every init writes a fresh zero state. Reset cancels ownership and invalidates the
context. No stale state/output/done is legal after reset. All permutations run
all 24 rounds; state bits never affect control flow. Only input/output length
and ready/valid stalls affect cycle count.

## ML-KEM functions

- `H(s)=SHA3-256(s)`, 32 bytes.
- `G(c)=SHA3-512(c)`, 64 bytes; bytes 0..31 are the first half and 32..63 the
  second, with no reversal.
- `J(s)=SHAKE256(s,32)`, not SHA3-256.
- `PRF_eta(s,b)=SHAKE256(s||b,64*eta)`, with 32-byte `s`, one-byte `b`, and eta
  2 or 3. Eta controls output length only.
- XOF is incremental SHAKE128. The convenience input is exactly
  `seed||index0||index1` (34 bytes); M5 assigns no matrix-coordinate meaning.

## Timing and limitations

All cycle counts are measured simulation edge counts and are added at M5.6.
The architecture structurally contains one permutation core per context, one
combinational round datapath, a 1600-bit state register in the core, a 1600-bit
sponge context register, and registered output staging. These are RTL facts,
not synthesized area. M2.3b and M5 focused synthesis remain pending; there is
no frequency, area, timing-closure, sampler, codec, or later-milestone claim.
