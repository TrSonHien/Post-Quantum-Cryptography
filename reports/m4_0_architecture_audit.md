# M4.0 Polynomial/Polyvec Architecture Audit

## Sources

The audit used the frozen M3 contracts, M1/M2 memory and arithmetic contracts,
FIPS 203 Algorithms 9-15 tracking, the independent Python NTT model, Kyber768
reference `poly.c`/`polyvec.c`, every `rtl/poly` module, current polynomial
testbenches, and their runners.

## Existing RTL classification

| Module | Current contract and verification | M4 classification |
|---|---|---|
| `poly_buffer` | 256x12 register array, two asynchronous reads, two synchronous writes, no reset/valid/domain; legacy NTT/poly tests | Legacy-only; unsafe for M4 memory boundary |
| `poly_add` | Two combinational lanes, 128 cycles, async reads, async reset, canonical 4-pattern test (1024 checks), no completeness/domain/error | Reusable only as behavioral adjacency; superseded by M4.1 controller |
| `poly_sub` | Same structure as add, canonical subtraction, 1024-check PASS | Reusable only as behavioral adjacency; superseded by M4.1 controller |
| `poly_reduce` | Empty module stub | Superseded; unsafe and unverified |
| `poly_basemul_addr_gen` | 128-operation legacy schedule, async reset, 256 address checks PASS | Legacy-only until M4.3 domain/memory integration |
| `poly_basemul_montgomery` | Async `poly_buffer`, pipelined three-cycle basemul, 768 coefficient checks PASS | Legacy adjacency; requires a future M4.3 adapter and independent domain proof |
| `mod_add_pipe` | Canonical 12-bit, latency 1, II=1, synchronous valid reset | Reusable unchanged |
| `mod_sub_pipe` | Canonical 12-bit, latency 1, II=1, synchronous valid reset | Reusable unchanged |
| `barrett_reduce_pipe` | Full unsigned 32-bit input, canonical 12-bit output, latency 3, II=1 | Reusable unchanged |
| `sync_1r1w_ram` | Synchronous one-cycle read, payload unreset, collision assertions | Reusable unchanged where one lane/port is sufficient |

No current polyvec controller exists. The Kyber C add/sub routines use lazy
signed intermediates, and `poly_invntt_tomont` has a legacy Montgomery boundary;
neither representation is copied into M4. M4 uses canonical boundaries and the
frozen M3 normal/NTT semantics.

## Frozen decisions

The new workspace is a fixed even/odd two-bank synchronous memory with explicit
ownership, bitmap completeness, and two-bit domain metadata. New add/sub/reduce
controllers issue one coefficient pair per cycle through two verified M2 leaf
lanes. New NTT/INTT adapters serialize indexed workspace access into the frozen
M3 public ports. Errors are sticky until synchronous reset.

The baseline uses one forward and one inverse M3 engine and serializes polyvec
elements. M4.3 pointwise multiplication is deliberately not defined beyond the
reserved domain tag. There is no architecture contradiction blocking M4.1.

No synthesis/Fmax claim is made. M2.3b remains pending.
