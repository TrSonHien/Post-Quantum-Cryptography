# M5.0 Keccak/SHA3/SHAKE Existing-Implementation Audit

## Scope and sources

The development checkout at `dd47e50` and the read-only `PQC_main` baseline
were inspected before M5 RTL work. Both `rtl/keccak/` directories contain only
`.gitkeep`; there are no existing Keccak, SHA3, or SHAKE RTL modules, testbenches,
or runners to classify as reusable. The new implementation therefore cannot
silently inherit a legacy state or stream convention.

Normative sources are FIPS 202 for Keccak-f[1600], sponge padding, SHA3, and
SHAKE, and FIPS 203 for H, G, J, PRF, and XOF. SP 800-185 supports the continuing
XOF API interpretation only. The project Python `symmetric.py`/`hashlib` layer
is the independent byte-output oracle. Kyber Round-3 `fips202.c` and
`symmetric-shake.c` are secondary implementation cross-checks only.

## Module classification

| Candidate | Function/interface | Representation and behavior | Classification |
|---|---|---|---|
| Current `rtl/keccak/.gitkeep` | none | no state, stream, reset, or timing contract | no implementation |
| Frozen `PQC_main/rtl/keccak/.gitkeep` | none | no baseline RTL exists | no implementation |
| Python `ref_model/python_model/symmetric.py` | H/G/J/PRF/XOF byte functions | `hashlib`; advancing XOF emulated by cached prefix and offset | independent output oracle; not RTL |
| Kyber reference `fips202.c` | optimized software Keccak/SHA3/SHAKE | 25 little-endian `uint64_t` lanes; two software rounds per loop; block-oriented incremental squeeze | useful reference only |
| Kyber `symmetric-shake.c` | seed/index XOF and seed/nonce PRF | absorbs `seed||x||y` and `seed||nonce`; eta is caller output length | useful reference only |

No candidate is marked reusable unchanged, reusable through an adapter, or
requires correction because no Keccak RTL exists. The imported C is not a
synthesizable or cycle-accurate hardware contract and is legacy-only for
ML-KEM top-level semantics.

## Hazard audit

- Reversed lane ordering: not present in RTL because none exists. New RTL must
  use lane index `x+5*y`; software variable names are not an RTL packing proof.
- MSB-first byte assumption: none exists in RTL. The C cross-check explicitly
  loads/stores bytes little-endian; the frozen stream contract places the
  earliest byte in the low byte of each 32-bit beat and state.
- Incorrect rotate direction or rho/pi coordinates: no RTL exists to assess.
  New RTL is independently checked against the FIPS equations and trace model.
- Incorrect round constants: no RTL table exists. All 24 constants will be
  generated and independently compared.
- Incorrect suffix or shared SHA3/SHAKE suffix: no RTL exists. The contract
  fixes SHA3 to `0x06` and SHAKE to `0x1f`.
- Missing multi-block squeeze: the legacy C public block helper can continue
  whole blocks, but it is not an arbitrary-length ready/valid controller. New
  RTL must preserve byte position over repeated requests and rate boundaries.
- Unbounded/non-backpressured output: no existing RTL. Every new output uses a
  stable registered ready/valid beat.

## Audit result

M5 starts from a clean architectural slate. No legacy RTL is deleted or
modified. Compatibility is defined only by the frozen M5 contract and
independent FIPS/hashlib differential evidence.
