# M4.3 Basemul Audit

`basemul_unit` implements five combinational Montgomery multiplications and
two modular additions with asynchronous reset and latency 3. With canonical
mathematical inputs and `zeta_rom = gamma*R`, both outputs equal the FIPS
BaseCaseMultiply result times `R^-1`. Its legacy TB intentionally checks that
Montgomery equation. It therefore does not implement the frozen public FIPS
boundary and cannot feed the frozen M3 inverse core directly.

`poly_basemul_addr_gen` has the correct 128-operation coefficient and zeta
schedule but asynchronous reset and no workspace/domain protocol. It remains a
useful legacy schedule reference. `poly_basemul_montgomery` uses asynchronous
`poly_buffer`, the legacy multiplier, and exposes no completeness/domain/error
contract; it remains legacy-only. Existing adjacency tests are retained.

`mod_mul_pipe` and combinational `mod_mul` compute `a*b*R^-1`. The former is a
verified latency-4 internal leaf; neither is ordinary multiplication.
`barrett_reduce_pipe` is reusable unchanged because its proven unsigned
32-bit input range covers the maximum 12x12 product `3328^2=11,075,584`.
`zetas_rom` values are Montgomery-scaled; M4.3 explicitly removes that factor.

Decision: use a new exact normal multiplier and new synchronous/domain-aware
BaseCaseMultiply and polynomial controllers. No legacy or M2/M3 semantics are
modified.
