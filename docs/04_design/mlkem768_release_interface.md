# ML-KEM-768 Academic RTL Release Interface

## Scope and source

This M9 release document freezes the implemented public top-level interface
without changing its architecture.  The source of record is
`rtl/mlkem/mlkem768_top.v`, module `mlkem768_top`.

## Clock and reset

- `clk`: the only clock input.  The hierarchy has no generated-clock port or
  generated-clock assumption.
- `rst_n`: synchronous, active-low reset sampled on `posedge clk`.  It
  invalidates operation control and suppresses stale output; it is not a claim
  of exhaustive lower-datapath physical payload erasure.

## Command and status interface

| Port | Width | Direction | Meaning |
|---|---:|---|---|
| `cmd_valid` | 1 | in | Command is presented when `cmd_ready` is high. |
| `cmd_ready` | 1 | out | High only when the top is idle and can accept a command. |
| `cmd_mode` | 2 | in | `00` KeyGen, `01` Encaps, `10` Decaps, `11` explicit zeroize. |
| `busy` | 1 | out | A selected command is active. |
| `done` | 1 | out | One-cycle completion indication for a successful selected command. |
| `error` | 1 | out | Completion/error indication from the selected public controller. |

The top accepts one command at a time.  A command issued while `cmd_ready=0`
is unsupported.  Mode `11` invokes the existing explicit-zeroize path and
does not emit a key, ciphertext, or shared-secret record.

## Input stream

| Port | Width | Direction | Meaning |
|---|---:|---|---|
| `in_valid` / `in_ready` | 1 / 1 | in/out | Transfer occurs only when both are high. |
| `in_data` | 32 | in | Four input bytes, low byte first. |
| `in_keep` | 4 | in | Valid-byte lanes for the final word. |
| `in_last` | 1 | in | Final word of the current input record. |
| `in_kind` | 2 | in | `00` encapsulation key, `01` decapsulation key, `10` ciphertext. |

The selected public controller enforces the record type and byte count:
Encaps consumes one 1184-byte encapsulation key; Decaps consumes a 2400-byte
decapsulation key followed by a 1088-byte ciphertext; KeyGen has no input
record.  Partial-word semantics use `in_keep`; ordinary records are emitted
and consumed four bytes at a time.

## External random-byte interface

| Port | Width | Direction | Meaning |
|---|---:|---|---|
| `rng_req_valid` / `rng_req_ready` | 1 / 1 | out/in | Request handshake. |
| `rng_req_len_bytes` | 16 | out | Requested random-byte count. |
| `rng_data_valid` / `rng_data_ready` | 1 / 1 | in/out | Random data transfer handshake. |
| `rng_data` / `rng_keep` / `rng_last` | 32 / 4 / 1 | in | Low-byte-first random data record. |
| `rng_fail` | 1 | in | RBG failure; the active public operation reports error. |

Public KeyGen requests 64 bytes (first `d`, then `z`); public Encaps requests
32 bytes (`m`); public Decaps does not request randomness.  The source is an
external interface only; this academic RTL neither implements nor certifies an
approved RBG.

## Output stream

| Port | Width | Direction | Meaning |
|---|---:|---|---|
| `out_valid` / `out_ready` | 1 / 1 | out/in | Transfer occurs only when both are high. |
| `out_data` / `out_keep` / `out_last` | 32 / 4 / 1 | out | Low-byte-first output record. |
| `out_kind` | 2 | out | Mode-qualified record type; see below. |

KeyGen emits a 1184-byte encapsulation key (`out_kind=00`) then a 2400-byte
decapsulation key (`01`).  Encaps emits a 32-byte shared secret (`11`) then a
1088-byte ciphertext (`10`).  Decaps emits one 32-byte shared secret (`10`);
therefore `out_kind=10` is mode-qualified and must be interpreted together with
the accepted command.  Valid/ready backpressure is supported by the implemented
public controllers; consumers must retain `out_ready` until the requested
transfer occurs.

## Input checks and limitations

Public Encaps checks key length and noncanonical encoded coefficients.  Public
Decaps checks decapsulation-key length, ciphertext length, and stored
`H(ek)`.  Decapsulation performs implicit rejection internally: no public
rejection record is emitted and malformed/re-encrypted ciphertext selection
returns a 32-byte secret.

The current academic RTL baseline provides control-state invalidation and
selected explicit secret-state clearing.  Exhaustive physical destruction of
all retained lower-level datapath state is deferred to a future security
hardening milestone.  The interface is not certified for production use,
side-channel resistance, fault injection, approved-RBG operation, or final
NIST CAVP/ACVP validation.
