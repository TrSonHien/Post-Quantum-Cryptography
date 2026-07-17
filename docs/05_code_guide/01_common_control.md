# Common parameters and control

## common

### Purpose
ML-KEM-768 parameter definitions

### Active modules

- none

### Retained support / legacy modules


### Reading notes

- Use the module catalog for parents, children, domain, handshake, state ownership, TB, and runner links.
- Treat named domain signals as authoritative; NORMAL and NTT are distinct representations.
- Fixed cycle counts are stated only where the implementation contract proves them; controllers otherwise use done/busy completion.

### Dependency graph, ownership, and reading order

`fixed_latency_delay` and `rv_register_slice` are shared leaves.  Read the
port contract first, then the valid/ready or valid-only metadata registers,
then reset/zeroize handling.  They own only control/pipeline state, not a
polynomial workspace.  The relevant unit tests and runners are linked in the
module catalog.  The common mistake is treating a delayed valid as a separate
transaction rather than metadata for the captured payload.

## control

### Purpose
valid/ready or fixed-latency control primitive

### Active modules

- `fixed_latency_delay`

### Retained support / legacy modules

- `rv_register_slice`

### Reading notes

- Use the module catalog for parents, children, domain, handshake, state ownership, TB, and runner links.
- Treat named domain signals as authoritative; NORMAL and NTT are distinct representations.
- Fixed cycle counts are stated only where the implementation contract proves them; controllers otherwise use done/busy completion.
