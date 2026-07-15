# ML-KEM-768 Engine Contract v0.1

## Authority and exact objects

FIPS 203 Algorithms 16--21 and the independent Python ML-KEM model define M8.
ML-KEM-768 uses `n=256`, `q=3329`, `k=3`, `eta1=eta2=2`, `du=10`, and `dv=4`.
Byte arrays increase in address order; a 32-bit beat carries the earliest byte
in bits 7:0.  Exact sizes are EK 1184, K-PKE DK 1152, ciphertext 1088, shared
secret 32, and ML-KEM DK 2400 bytes.

The decapsulation key is mechanically partitioned by half-open offsets:

| Region | Start | End | Length |
|---|---:|---:|---:|
| `dkPKE` | 0 | 1152 | 1152 |
| embedded `ekPKE` | 1152 | 2336 | 1184 |
| stored `H(ekPKE)` | 2336 | 2368 | 32 |
| `z` | 2368 | 2400 | 32 |

The endpoints are cumulative constants and must be asserted in layout tests.

## Deterministic internal functions

`mlkem_keygen_internal`, `mlkem_encaps_internal`, and
`mlkem_decaps_internal` are deterministic test/integration functions.  They
accept caller-supplied `d,z,m` and are not normal application APIs.

- KeyGen_internal invokes K-PKE.KeyGen once, H once, emits EK then assembles
  `dkPKE || ekPKE || H(ekPKE) || z`.
- Encaps_internal computes `h=H(ek)`, `G(m||h)`, uses G bytes 0..31 as K and
  32..63 as r, invokes K-PKE.Encrypt once, and emits K then ciphertext.
- Decaps_internal parses exact DK ranges, decrypts once, always computes
  `G(m'||h)` and `J(z||c)`, always re-encrypts once, compares all 1088 bytes,
  selects all 32 K bytes with a full mask, and emits only K.

Internal controllers use registered states and mode-local fixed byte arrays.
Stream load/output initiation interval is one accepted 32-bit beat per cycle.
Indexed byte storage uses deterministic writes and synchronous one-cycle reads.
Total latency is variable because reused SampleNTT has data-dependent rejection.

## Public functions and external entropy

`mlkem_keygen`, `mlkem_encaps`, and `mlkem_decaps` are the application-facing
controllers.  KeyGen requests exactly 64 fresh external bytes, splitting d then
z.  Encaps fully checks the 1184-byte EK before requesting exactly 32 bytes for
m.  Decaps accepts exactly 2400 DK bytes and 1088 ciphertext bytes, then checks
`H(dk[1152:2336]) == dk[2336:2368]` before internal invocation.

Entropy uses `rng_req_valid/ready`, `rng_req_len_bytes`, and a 32-bit
low-byte-first `rng_data_valid/ready/data/keep/last/fail` stream.  Failure,
wrong length, illegal keep, or bad last aborts with public error, no designated
output, and mandatory partial-state scrub.  Retained entropy is never reused.

The EK modulus check scans all 1152 coefficient bytes through verified d12
noncanonical evidence; the final 32 rho bytes are length-checked only.  A
public input-check failure never invokes the internal function.  Correctly
sized cryptographically modified ciphertext is not a public input error and
uses implicit rejection internally.

## Unified public top

`mlkem768_top` supports KEYGEN, ENCAPS, DECAPS, and ZEROIZE command modes.  It
uses synchronous active-low `rst_n`; `cmd_valid/ready/mode`; `busy/done/error`;
typed application input records (`EK`, `DK`, `CIPHERTEXT`); the entropy
interface above; and typed output records (`EK`, `DK`, `SHARED_SECRET`,
`CIPHERTEXT`).  No polynomial-bank or deterministic-seed port is public.

Record order is frozen:

- KeyGen: EK 1184, then DK 2400.
- Encaps: SHARED_SECRET 32, then CIPHERTEXT 1088.
- Decaps: SHARED_SECRET 32.

Each record has its own `out_last`.  Data, kind, keep, and last remain stable
while stalled.  `done` pulses only after the final record was accepted and all
mandatory scrub writes committed.  `busy` remains asserted through stalls and
scrub.  No new command is accepted while busy.  Implicit rejection neither
sets public error nor changes record shape or timing of compare/select.

## Control, zeroization, and error contract

Reset immediately cancels ownership and invalidates metadata but makes no
physical-erasure claim.  Explicit ZEROIZE aborts an active operation, blocks
new traffic, overwrites all reachable secret/ephemeral state, clears secret
scalars and reject metadata, then completes.  Public operations automatically
perform the same required destruction before done.  Designated output staging
may be retained only until accepted, then is scrubbed.

Error categories are protocol/input, entropy, and subengine failure.  The
internal ciphertext mismatch is never an error or port.  Error is cleared on a
new accepted command/reset and stable for the completed failed transaction.

## Architecture and verification freeze

The correctness-first baseline composes standalone verified M7 mode
controllers and dedicated M5 H/G/J wrappers under registered M8 controllers.
This may duplicate resources; it is a structural fact, not synthesized area,
and consolidation is deferred until measured after M9.  Compare and select are
serialized byte loops: exactly 1088 compare iterations and 32 select
iterations, independent of mismatch position.  Buffer scrub visits every
configured address.  Expected critical paths are registered buffer selection
and byte compare/mask logic.

Verification uses independent Python vectors, exact intermediate comparisons,
protocol/reset/backpressure tests, hierarchy-assisted scrub checks, fixed loop
cycle assertions, deterministic regeneration, focused M7 preservation, and a
single final lower-milestone closure.  No complete constant-cycle,
side-channel-certification, synthesis, area, timing-closure, Fmax, or final
CAVP/ACVP claim is made.
