# Modular arithmetic

## arithmetic

### Purpose
mod-q arithmetic used by FIPS 203 polynomial operations

### Active modules

- `barrett_reduce_pipe`
- `mod_add_pipe`
- `mod_mul`
- `mod_mul_normal_pipe`
- `mod_mul_pipe`
- `mod_sub_pipe`
- `montgomery_reduce`
- `montgomery_reduce_pipe`

### Retained support / legacy modules

- `barrett_reduce`
- `conditional_sub_q`
- `mod_add`
- `mod_sub`

### Reading notes

- Use the module catalog for parents, children, domain, handshake, state ownership, TB, and runner links.
- Treat named domain signals as authoritative; NORMAL and NTT are distinct representations.
- Fixed cycle counts are stated only where the implementation contract proves them; controllers otherwise use done/busy completion.

### Dependency graph, domains, and reading order

The active path uses `mod_add_pipe`, `mod_sub_pipe`, `montgomery_reduce_pipe`,
`mod_mul_pipe`, `mod_mul_normal_pipe`, and `barrett_reduce_pipe`; legacy
combinational counterparts remain for compatibility and independent tests.
Read add/sub, reductions, then multipliers.  Coefficients are canonical
`[0, q-1]` at named module boundaries unless the port contract says otherwise;
Montgomery multiplication semantics do not imply NTT domain.  Pipelines carry
payload and valid metadata together; use the arithmetic unit runners listed in
the catalog.  Do not infer a fixed controller latency where the RTL uses
`done`.
