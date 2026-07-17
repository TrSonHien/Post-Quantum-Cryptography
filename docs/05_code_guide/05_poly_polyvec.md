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
- `poly_ntt_pipe`
- `poly_sub_pipe`
- `poly_transform_pipe`
- `poly_workspace`
- `polyvec_basemul_acc_pipe`
- `polyvec_elementwise_pipe`
- `polyvec_ntt_pipe`
- `polyvec_workspace`

### Adapters and historical note

- `poly_basemul_addr_gen` is a retained adapter.
- Superseded polynomial and polyvec implementations are available only in Git
  history before `pre-legacy-prune-b683bd7`.

### Reading notes

- Use the module catalog for parents, children, domain, handshake, state ownership, TB, and runner links.
- Treat named domain signals as authoritative; NORMAL and NTT are distinct representations.
- Fixed cycle counts are stated only where the implementation contract proves them; controllers otherwise use done/busy completion.

### Dependency graph, ownership, and reading order

Read `poly_workspace`/`polyvec_workspace`, binary/reduce pipes, transforms,
basecase multiplication, then polyvec controllers.  `poly_ntt_pipe` is an
active adapter selected by `polyvec_ntt_pipe`.  These controllers own
coefficient arrays and change their NORMAL/NTT ownership only after child
completion and result drain.  Follow begin,
load, start, wait, read/drain, release phases and the matching M4 runners in
the catalog.  A common error is reading an output before the registered-valid
drain phase has completed.
