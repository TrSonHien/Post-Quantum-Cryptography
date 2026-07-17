# Memory and bank ownership

## memory

### Purpose
workspace, RAM, or NTT bank ownership primitive

### Active modules

- `ntt_bank_map`
- `ntt_pingpong_banks`
- `sync_1r1w_ram`

### Retained support / legacy modules

- `poly_buffer`

### Reading notes

- Use the module catalog for parents, children, domain, handshake, state ownership, TB, and runner links.
- Treat named domain signals as authoritative; NORMAL and NTT are distinct representations.
- Fixed cycle counts are stated only where the implementation contract proves them; controllers otherwise use done/busy completion.

### Dependency graph, ownership, and reading order

Read `sync_1r1w_ram`, `ntt_bank_map`, `ntt_pingpong_banks`, then `poly_buffer`.
The active NTT path owns the four-bank ping-pong workspace and has a one-cycle
read response; `poly_buffer` is a retained asynchronous-read adapter for
legacy paths.  A role swap is legal only under the traffic conditions asserted
by the RTL.  Memory payload reset is intentionally not described as physical
erasure; external access is legal only in the owning controller phase.  The
M2 primitive runner is the primary verification entry point.
