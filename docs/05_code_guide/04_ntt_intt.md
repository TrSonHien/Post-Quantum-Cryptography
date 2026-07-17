# NTT and INTT

## ntt

### Purpose
FIPS 203 Algorithms 9--12 transform support

### Active modules

- `butterfly_pipe`
- `intt_butterfly_pipe`
- `intt_core_pipe`
- `intt_scaler_pipe`
- `intt_scheduler_pipe`
- `ntt_core_pipe`
- `ntt_scheduler_pipe`
- `zetas_rom`

### Retained support / legacy modules

- `basemul_unit`
- `butterfly_unit`
- `intt_butterfly_unit`
- `intt_core`
- `ntt_addr_gen`
- `ntt_core`

### Reading notes

- Use the module catalog for parents, children, domain, handshake, state ownership, TB, and runner links.
- Treat named domain signals as authoritative; NORMAL and NTT are distinct representations.
- Fixed cycle counts are stated only where the implementation contract proves them; controllers otherwise use done/busy completion.
