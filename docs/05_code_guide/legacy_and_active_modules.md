# Active and Historical RTL Modules

`mlkem768_top` is the release root.  The current tree retains only its active
release path, shared leaves, adapters, four smoke-suite compatibility helpers,
and two unsplittable legacy declarations in `reduction.v`.

Superseded RTL implementations remain available in Git history before
`pre-legacy-prune-b683bd7`; they are not current runnable release modules.

## Current coexistence

| Family | Current release selection | Notes |
|---|---|---|
| modular arithmetic | `mod_add_pipe`, `mod_sub_pipe`, `mod_mul_pipe`, `mod_mul`, reduction leaves | The compact add/sub variants were pruned. |
| NTT / INTT | `ntt_core_pipe`, `intt_core_pipe`, pipelined butterflies and schedulers | Earlier non-pipelined cores were pruned. |
| polynomial / polyvec | `poly_transform_pipe`, `poly_ntt_pipe`, `poly_intt_pipe`, `poly_binary_pipe`, current vector controllers | `poly_ntt_pipe` is active through `polyvec_ntt_pipe`; it was reclassified after hierarchy review. |
| codecs | byte codecs, 12-bit poly adapters, compressed codecs, K-PKE format adapter | `poly_encode12_pipe` and `poly_decode12_pipe` are active through current polyvec codecs. |
| Keccak | SHA3, SHAKE256, H/G/J, PRF, XOF | SHAKE128 compatibility RTL was pruned. |

## Mixed source exception

`rtl/arithmetic/reduction.v` contains active `montgomery_reduce` together with
legacy `barrett_reduce` and `conditional_sub_q`.  The source is intentionally
kept intact: splitting it would be an unnecessary behavioral-risk change for a
tree cleanup.  The two legacy declarations are not release-hierarchy parents.

## Compatibility helpers kept for mandatory smoke checks

- `mlkem_ct_compare_select` supports `run_mlkem_ct_compare_select.sh`.
- `mlkem_dk_assemble` and `mlkem_dk_parse` support `run_mlkem_dk_layout.sh`.
- `mlkem_zeroize_controller` supports `run_mlkem_zeroization.sh`.

The complete current classification is in [module_catalog.md](module_catalog.md).
