# M6.0 Codec and Sampler Audit

## Scope and authority

The development tree and frozen comparison worktree contain no project-owned
codec or sampler RTL: `rtl/codec` and `rtl/sampler` contain placeholders only.
Consequently no legacy RTL is reusable or requires correction. FIPS 203
Algorithms 3 through 8 are normative; the independent Python modules
`codec.py`, `sampling.py`, and `symmetric.py` are the differential oracle.

## Source classification

| Source | Function | Classification | M6 disposition |
|---|---|---|---|
| `ref_model/python_model/codec.py` | Algorithms 3--6 and exact rational rounding | independently verified reference | expected-value source, unchanged |
| `ref_model/python_model/sampling.py` | Algorithms 7--8 | independently verified reference | expected-value source, unchanged |
| `ref_model/python_model/symmetric.py` | PRF and continuing SHAKE128 model | independently verified reference | integration oracle, unchanged |
| Kyber `poly.c`/`polyvec.c` | optimized packing/compression/message conversion | useful reference only | no direct RTL translation |
| Kyber `cbd.c` | word-oriented signed CBD implementation | useful leaf only | prove canonical FIPS output independently |
| Kyber `indcpa.c` | matrix expansion and bounded-buffer rejection parser | legacy-only for control | do not copy loop/buffer policy |

## Required hazard findings

- No existing RTL has an MSB-first packer, but legacy formulas are specialized
  layouts rather than the frozen generic LSB-first stream contract.
- Legacy CBD writes signed `int16_t` values. M6 architectural outputs must
  instead encode `x-y mod 3329` canonically in 12 unsigned bits.
- The legacy C APIs assume complete asynchronous software buffers; they provide
  neither registered SRAM timing nor ready/valid backpressure.
- Legacy compression constants are implementation-specific. They are not proof
  of final-FIPS rational rounding and are reference-only until exhaustive
  equivalence is established.
- M6 uses `Compress_d(x)=floor((2^d*x+1664)/3329) mod 2^d` and
  `Decompress_d(y)=floor((3329*y+2^(d-1))/2^d)` for nonnegative inputs.
- `ByteDecode12` does not reject. It returns `raw12 mod 3329` and separately
  records `raw12 >= 3329`; M7/M8 owns any rejection policy.
- The legacy rejection implementation works in finite refill buffers. M6 has
  no functional rejection bound; a simulation watchdog is verification only.
- M5 continuing XOF requests are mandatory. Restarting SHAKE128 for each
  three-byte group is unsafe and prohibited.
- M6 preserves `seed||index0||index1` and `seed||nonce`; it assigns no matrix
  coordinate meaning and never reverses either index or nonce.
- PRF eta selects 128 or 192 output bytes and is never absorbed. Any other
  output length or eta-as-domain-data behavior is unsafe.
- Raw d-bit codes have explicit raw domains and are never silently interpreted
  as normal or NTT polynomial coefficients.

## Result

The audit found no reusable codec/sampler RTL and no conflict with the M1--M5
contracts. New registered modules are required. Legacy sources remain intact.
M6.0 may freeze the contract below without modifying earlier RTL.
