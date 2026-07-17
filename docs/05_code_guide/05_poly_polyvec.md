# Polynomial and polyvec

## poly

### Purpose
FIPS 203 polynomial/polyvec operation support

### Active modules

- `basecase_mul_pipe`
- `poly_add_pipe`
- `poly_basemul_pipe`
- `poly_binary_pipe`
- `poly_intt_pipe`
- `poly_sub_pipe`
- `poly_transform_pipe`
- `poly_workspace`
- `polyvec_basemul_acc_pipe`
- `polyvec_elementwise_pipe`
- `polyvec_ntt_pipe`
- `polyvec_workspace`

### Retained support / legacy modules

- `poly_add`
- `poly_basemul_addr_gen`
- `poly_basemul_montgomery`
- `poly_ntt_pipe`
- `poly_reduce`
- `poly_reduce_pipe`
- `poly_sub`
- `polyvec_add_pipe`
- `polyvec_intt_pipe`
- `polyvec_reduce_pipe`
- `polyvec_sub_pipe`

### Reading notes

- Use the module catalog for parents, children, domain, handshake, state ownership, TB, and runner links.
- Treat named domain signals as authoritative; NORMAL and NTT are distinct representations.
- Fixed cycle counts are stated only where the implementation contract proves them; controllers otherwise use done/busy completion.
