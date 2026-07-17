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
