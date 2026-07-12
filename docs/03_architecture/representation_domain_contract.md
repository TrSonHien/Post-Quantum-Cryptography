# M1 v0.1 Representation and Domain Contract

## Architectural representation

At engine, memory-owner, codec, sampler, and verification boundaries every
coefficient is a 12-bit unsigned canonical representative:

```text
0 <= coefficient < q, q = 3329
```

Centered, signed, lazy, or out-of-range values are not architectural values.
Sums/products may use wider private intermediates, but boundary outputs must be
canonical and range-checked.

## Polynomial domains

- `poly` denotes normal-domain coefficients in `R_q`.
- `poly_hat` denotes the FIPS 203 NTT representation in `T_q`.
- Domain is part of metadata and module contracts, not inferred from control state.
- Normal-domain and NTT-domain operands must never share an untagged buffer.
- NTT consumes `poly` and produces `poly_hat`; INTT consumes `poly_hat` and
  produces `poly`.
- `MultiplyNTTs` consumes two `poly_hat` values and produces `poly_hat`.

## Montgomery boundary

Montgomery values are private to a documented multiplier/reduction pipeline.
No engine port, shared memory, codec, sampler, vector file, or controller-visible
payload may contain a Montgomery-scaled value. A multiplier wrapper must state
its mathematical input/output equation and absorb any `R`, `R^-1`, or twiddle
scaling internally so its public result matches the FIPS-domain operation.

The current `mod_mul` computes Montgomery reduction and the legacy
`poly_basemul_montgomery` intentionally exposes a Montgomery-scaled operation.
They are verified legacy blocks, not compliant implementations of this new
architectural boundary until wrapped or replaced in M2/M3.

## Serialization

`ByteEncode_d`/`ByteDecode_d` follow FIPS least-significant-bit-first packing.
Hex vectors list bytes in increasing address order. `mlkem-vector-v1` integer
arrays use canonical unsigned values; fields named `*_hat` are NTT-domain.
