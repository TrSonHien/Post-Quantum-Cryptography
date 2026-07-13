# M4.2 Polynomial Forward NTT Adapter Report

`poly_ntt_pipe` wraps `poly_transform_pipe`, one input and one output
`poly_workspace`, and the unchanged frozen `ntt_core_pipe`. Its indexed load
interface requires a complete `POLY_DOMAIN_NORMAL` polynomial. The adapter
acquires the source, synchronously reads 256 logical coefficients, drives only
the M3 public preload ports, waits for M3 `done`, reads 256 logical M3 results,
stores all responses, and publishes `POLY_DOMAIN_NTT` only after completeness.

The adapter never references `ntt_pingpong_banks`, bank/address metadata, or
any physical M3 memory hierarchy. External encoding remains canonical unsigned
12-bit at both boundaries. Sticky error rejects incomplete/wrong-domain start,
start/load/read while busy, result overwrite, and result access before publish.

Measured start-to-done is 1473 cycles for every test: 256 unique preload
transfers, the frozen 955-cycle M3 compute, 256 unique result indices plus the
final synchronous response cycle, and five controller/acquire/publish cycles.
External workspace loading and result consumption are outside this compute
interval.

`timeout 75s ./sim/scripts/run_poly_ntt_pipe.sh` PASS: 32 independent Python
vectors and 8192 differential coefficient comparisons. Directed vectors cover
zero, `q-1`, eight impulses, alternating and incrementing patterns, plus 20
deterministic random polynomials. Protocol tests cover incomplete/wrong domain,
overwrite, busy access, reset during preload, M3 compute, and readback, and
clean restart. No premature domain/completeness publication occurred.

M3 RTL was not modified. No synthesis/Fmax claim is made; M2.3b remains pending.
