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
