# M4.3 Exact Normal Multiplier Report

`mod_mul_normal_pipe` registers a 24-bit product then uses
`barrett_reduce_pipe`. Contract: `a*b mod 3329`, latency 4, II=1, canonical
input/output, synchronous active-low validity reset. The full product bound is
11,075,584, within the reducer's verified unsigned 32-bit range.

`timeout 60s ./sim/scripts/run_mod_mul_normal_pipe.sh` PASS: 100,000
deterministic Python-generated products, boundary/structured/random coverage,
full-rate traffic, canonical outputs, valid alignment, and reset cancellation.
