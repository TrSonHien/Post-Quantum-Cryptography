# M4.1 Canonical Polynomial Arithmetic Report

## Architecture and interface

`poly_add_pipe` and `poly_sub_pipe` wrap `poly_binary_pipe`, three workspaces,
and two parallel `mod_add_pipe` or `mod_sub_pipe` lanes. Each source issues one
even/odd pair per cycle. Source read latency is one cycle, arithmetic latency is
one cycle, and the result workspace commits the output on the following edge.
All 128 pairs issue at II=1; measured polynomial-level start-to-done is 132
cycles. Output preserves matching NORMAL or NTT input domain.

`poly_reduce_pipe` accepts complete unsigned 32-bit input coefficients, uses
two synchronous 128-entry source banks and two parallel three-cycle
`barrett_reduce_pipe` lanes, and publishes canonical 12-bit output. Its measured
start-to-done duration is 134 cycles and semantic domain is preserved.

Controllers expose explicit operand load initialization, indexed loads, start,
sticky error, busy, one-cycle done, synchronous indexed result read, result
domain/completeness, and explicit result release. They reject incomplete,
invalid, mismatched-domain, busy-access, and overwrite attempts. Reset cancels
pending validity but does not clear payload arrays.

## Differential verification

`tb/tools/gen_m4_poly_vectors.py` uses Python integer modular arithmetic with
seed `0x4d34504f`. Each operation has 32 polynomials covering zero, `q-1`,
alternating, incrementing, impulses, boundaries, and deterministic random data.

| Command | Vectors | Coefficient comparisons | Result |
|---|---:|---:|---|
| `timeout 45s ./sim/scripts/run_poly_add_pipe.sh` | 32 | 8192 | PASS |
| `timeout 45s ./sim/scripts/run_poly_sub_pipe.sh` | 32 | 8192 | PASS |
| `timeout 45s ./sim/scripts/run_poly_reduce_pipe.sh` | 32 | 8192 | PASS |

Additional checks cover NORMAL and NTT domains, mismatched domains, incomplete
preload, reset during issue/drain, restart, canonical outputs, and sticky error.
The frozen M2 leaves were not modified. `run_m3_regression.sh` passed 22/22
programs and 361656 checks after integration, including M2 and legacy polynomial
adjacency.

M4.3 basemul orchestration is not implemented. No synthesis/Fmax claim is made;
M2.3b remains pending.
