# Polynomial MultiplyNTTs Contract

## Mathematical boundary

All public coefficients are canonical unsigned residues in `[0,3328]` and
carry `POLY_DOMAIN_NTT`. `basecase_mul_pipe` consumes mathematical residues
`a0,a1,b0,b1,gamma` and returns

```text
c0 = a0*b0 + gamma*a1*b1 mod 3329
c1 = a0*b1 + a1*b0 mod 3329
```

No Montgomery-scaled value may escape this boundary. Reset is synchronous
active-low and clears validity/control only. The pipeline has latency 9 and
II=1, uses five `mod_mul_normal_pipe` instances and two modular-add lanes.

## Exact multiplication and Montgomery proof

`mod_mul_normal_pipe` registers the full 24-bit canonical product and applies
the verified full-32-bit `barrett_reduce_pipe`. Its result is exactly `a*b mod
q`, canonical, with latency 4 and II=1. It is distinct from `mod_mul_pipe`,
whose contract is `a*b*R^-1 mod q`.

`zetas_rom[64+i]` stores `gamma*R mod q`. `poly_basemul_pipe` explicitly
computes `MontgomeryReduce(zeta_mont*1) = gamma` before BaseCaseMultiply. For
odd requests it first forms canonical `-zeta_mont`, which converts to
canonical `-gamma`. Thus no residual `R` or `R^-1` remains.

## Polynomial schedule and protocol

For request `2*i`, coefficient pair `(4*i,4*i+1)` uses positive
`zetas[64+i]`; request `2*i+1` uses `(4*i+2,4*i+3)` and its negative. There
are exactly 128 requests, zeta addresses 64 through 127, and 128 synchronous
pair writes. Completion follows the final aligned output write and workspace
publish, not final issue.

Two complete NTT-domain inputs are mandatory. Output is one complete canonical
NTT-domain polynomial. Incomplete, wrong-domain, busy access, premature read,
or unread-result overwrite is an error. Callers must not interpret the ROM
constant as mathematical gamma, use legacy `basemul_unit` at this boundary, or
infer domain from coefficient bits.
