# K-PKE controllers

## kpke

### Purpose
FIPS 203 Algorithms 13--15 K-PKE support

### Active modules

- `kpke_decrypt`
- `kpke_encrypt`
- `kpke_keygen`
- `kpke_matrix_row_sampler`
- `kpke_noise_vector_sampler`

### Retained support / legacy modules


### Reading notes

- Use the module catalog for parents, children, domain, handshake, state ownership, TB, and runner links.
- Treat named domain signals as authoritative; NORMAL and NTT are distinct representations.
- Fixed cycle counts are stated only where the implementation contract proves them; controllers otherwise use done/busy completion.
