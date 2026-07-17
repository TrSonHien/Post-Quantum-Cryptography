# Release-tree RTL prune manifest

## Scope and checkpoint

This manifest was prepared on `cleanup/prune-legacy-rtl` from
`b683bd7f225fd35883cc7fb102c4e56de1b16336`, with the local annotated tag
`pre-legacy-prune-b683bd7` as the recovery checkpoint.  It applies the
classification in the M9 code guides to the current tree only; it does not
rewrite history or modify `main`.

Release RTL is the elaborated hierarchy rooted at `mlkem768_top`.  The M8
smoke suite additionally requires the three ML-KEM unit helpers listed below.
The current mandatory checks are complete elaboration, M8 smoke, M8 functional
regression, K-PKE roundtrip, deterministic-vector reproduction, and M9 release
checks.

## Candidate review and final RTL actions

| Source file | Module | Classification | In release hierarchy | Parents / use | Test and runner references | File-list references | Action | Reason |
|---|---|---|---|---|---|---|---|---|
| `rtl/arithmetic/mod_add.v` | `mod_add` | LEGACY_OR_SUPERSEDED | no | legacy arithmetic / NTT path | `tb_mod_add`; `run_mod_add.sh` | M9; M2.3 wrapper sweep; legacy sim list | DELETE | Replaced by `mod_add_pipe`. |
| `rtl/arithmetic/mod_sub.v` | `mod_sub` | LEGACY_OR_SUPERSEDED | no | legacy arithmetic / NTT path | `tb_mod_sub`; `run_mod_sub.sh` | M9; M2.3 wrapper sweep | DELETE | Replaced by `mod_sub_pipe`. |
| `rtl/ntt/basemul_unit.v` | `basemul_unit` | LEGACY_OR_SUPERSEDED | no | legacy polynomial path | `tb_basemul_unit`; `run_basemul_unit.sh` | M9 | DELETE | Replaced by `basecase_mul_pipe` / `poly_basemul_pipe`. |
| `rtl/ntt/butterfly_unit.v` | `butterfly_unit` | LEGACY_OR_SUPERSEDED | no | legacy NTT core | `tb_butterfly_unit`; `run_butterfly_unit.sh` | M9; M2.3 wrapper sweep | DELETE | Replaced by `butterfly_pipe`. |
| `rtl/ntt/intt_butterfly_unit.v` | `intt_butterfly_unit` | LEGACY_OR_SUPERSEDED | no | legacy INTT core | no standalone TB | M9; M2.3 wrapper sweep | DELETE | Replaced by `intt_butterfly_pipe`. |
| `rtl/ntt/intt_core.v` | `intt_core` | LEGACY_OR_SUPERSEDED | no | legacy transform path | `tb_intt_core`; `run_intt_core.sh` | M9 | DELETE | Replaced by `intt_core_pipe`. |
| `rtl/ntt/ntt_core.v` | `ntt_core` | LEGACY_OR_SUPERSEDED | no | legacy transform path | `tb_ntt_core`; `run_ntt_core.sh` | M9 | DELETE | Replaced by `ntt_core_pipe`. |
| `rtl/codec/bits_to_bytes_pipe.v` | `bits_to_bytes_pipe` | LEGACY_OR_SUPERSEDED | no | old codec micro-test | `tb_bits_bytes_pipe`; `run_bits_bytes_pipe.sh` | M9 | DELETE | Superseded by active record codecs. |
| `rtl/codec/bytes_to_bits_pipe.v` | `bytes_to_bits_pipe` | LEGACY_OR_SUPERSEDED | no | old codec micro-test | `tb_bits_bytes_pipe`; `run_bits_bytes_pipe.sh` | M9 | DELETE | Superseded by active record codecs. |
| `rtl/codec/compress_coeff_pipe.v` | `compress_coeff_pipe` | LEGACY_OR_SUPERSEDED | no | old codec micro-test | `tb_compress_coeff_pipe`; `run_compress_coeff_pipe.sh` | M9 | DELETE | Superseded by `poly_compress_encode_pipe`. |
| `rtl/codec/decompress_coeff_pipe.v` | `decompress_coeff_pipe` | LEGACY_OR_SUPERSEDED | no | old codec micro-test | `tb_decompress_coeff_pipe`; `run_decompress_coeff_pipe.sh` | M9 | DELETE | Superseded by `poly_decode_decompress_pipe`. |
| `rtl/codec/kpke_ciphertext_pack_pipe.v` | `kpke_ciphertext_pack_pipe` | LEGACY_OR_SUPERSEDED | no | none | none | M9 | DELETE | Unused superseded K-PKE format path. |
| `rtl/codec/kpke_ciphertext_unpack_pipe.v` | `kpke_ciphertext_unpack_pipe` | LEGACY_OR_SUPERSEDED | no | none | none | M9 | DELETE | Unused superseded K-PKE format path. |
| `rtl/codec/kpke_dk_pack_pipe.v` | `kpke_dk_pack_pipe` | LEGACY_OR_SUPERSEDED | no | none | none | M9 | DELETE | Unused superseded K-PKE format path. |
| `rtl/codec/kpke_dk_unpack_pipe.v` | `kpke_dk_unpack_pipe` | LEGACY_OR_SUPERSEDED | no | none | none | M9 | DELETE | Unused superseded K-PKE format path. |
| `rtl/codec/kpke_ek_pack_pipe.v` | `kpke_ek_pack_pipe` | LEGACY_OR_SUPERSEDED | no | none | none | M9 | DELETE | Unused superseded K-PKE format path. |
| `rtl/codec/kpke_ek_unpack_pipe.v` | `kpke_ek_unpack_pipe` | LEGACY_OR_SUPERSEDED | no | none | none | M9 | DELETE | Unused superseded K-PKE format path. |
| `rtl/codec/poly_decode12_pipe.v` | `poly_decode12_pipe` | ACTIVE_SHARED_LEAF | yes | `polyvec_codec_pipe` selected by active K-PKE decode wrappers | K-PKE roundtrip; M8 | M9 | KEEP / RECLASSIFIED | Initial catalog classification was contradicted by active selected elaboration. |
| `rtl/codec/poly_encode12_pipe.v` | `poly_encode12_pipe` | ACTIVE_SHARED_LEAF | yes | `polyvec_codec_pipe` selected by active K-PKE encode wrappers | K-PKE roundtrip; M8 | M9 | KEEP / RECLASSIFIED | Initial catalog classification was contradicted by active selected elaboration. |
| `rtl/sampler/cbd_pair_pipe.v` | `cbd_pair_pipe` | LEGACY_OR_SUPERSEDED | no | old sampler path | `tb_cbd_pair_pipe`; `run_cbd_pair_pipe.sh` | M9 | DELETE | Superseded by `sample_poly_cbd_pipe`. |
| `rtl/poly/poly_add.v` | `poly_add` | LEGACY_OR_SUPERSEDED | no | legacy polynomial path | `tb_poly_add`; `run_poly_add.sh` | M9 | DELETE | Replaced by `poly_binary_pipe`. |
| `rtl/poly/poly_basemul_montgomery.v` | `poly_basemul_montgomery` | LEGACY_OR_SUPERSEDED | no | legacy polynomial path | `tb_poly_basemul_montgomery`; runner | M9 | DELETE | Replaced by `poly_basemul_pipe`. |
| `rtl/poly/poly_ntt_pipe.v` | `poly_ntt_pipe` | ACTIVE_SHARED_LEAF | yes | `polyvec_ntt_pipe` used by every active K-PKE controller | K-PKE roundtrip; M8 | M9 | KEEP / RECLASSIFIED | It is the active forward adapter around `poly_transform_pipe`. |
| `rtl/poly/poly_reduce.v` | `poly_reduce` | LEGACY_OR_SUPERSEDED | no | legacy polynomial path | none direct | M9 | DELETE | Replaced by `poly_binary_pipe`. |
| `rtl/poly/poly_reduce_pipe.v` | `poly_reduce_pipe` | LEGACY_OR_SUPERSEDED | no | legacy transform adapter | old poly-transform runners | M9 | DELETE | Replaced by `poly_binary_pipe`. |
| `rtl/poly/poly_sub.v` | `poly_sub` | LEGACY_OR_SUPERSEDED | no | legacy polynomial path | `tb_poly_sub`; `run_poly_sub.sh` | M9 | DELETE | Replaced by `poly_binary_pipe`. |
| `rtl/poly/polyvec_add_pipe.v` | `polyvec_add_pipe` | LEGACY_OR_SUPERSEDED | no | legacy vector adapter | old elementwise runner | M9 | DELETE | Replaced by `polyvec_elementwise_pipe`. |
| `rtl/poly/polyvec_intt_pipe.v` | `polyvec_intt_pipe` | LEGACY_OR_SUPERSEDED | no | legacy vector adapter | old elementwise runner | M9 | DELETE | Replaced by `polyvec_elementwise_pipe`. |
| `rtl/poly/polyvec_reduce_pipe.v` | `polyvec_reduce_pipe` | LEGACY_OR_SUPERSEDED | no | legacy vector adapter | old elementwise runner | M9 | DELETE | Replaced by `polyvec_elementwise_pipe`. |
| `rtl/poly/polyvec_sub_pipe.v` | `polyvec_sub_pipe` | LEGACY_OR_SUPERSEDED | no | legacy vector adapter | old elementwise runner | M9 | DELETE | Replaced by `polyvec_elementwise_pipe`. |
| `rtl/control/rv_register_slice.v` | `rv_register_slice` | TEST_OR_COMPATIBILITY_ONLY | no | pipeline-control-only | `tb_pipeline_control`; `run_pipeline_control.sh` | M9 | DELETE | Not used by mandatory release checks. |
| `rtl/keccak/shake128_stream.v` | `shake128_stream` | TEST_OR_COMPATIBILITY_ONLY | no | SHAKE128 compatibility test only | `tb_shake128_stream`; related M5 runners | M9 | DELETE | Release ML-KEM-768 uses SHAKE256/XOF services. |

## Retained compatibility and mixed sources

| Source file | Module(s) | Classification / action | Exact dependency and reason |
|---|---|---|---|
| `rtl/mlkem/mlkem_ct_compare_select.v` | `mlkem_ct_compare_select` | TEST_OR_COMPATIBILITY_ONLY / KEEP | `run_m8_smoke.sh` runs `run_mlkem_ct_compare_select.sh`. |
| `rtl/mlkem/mlkem_dk_assemble.v` | `mlkem_dk_assemble` | TEST_OR_COMPATIBILITY_ONLY / KEEP | `run_m8_smoke.sh` runs `run_mlkem_dk_layout.sh`. |
| `rtl/mlkem/mlkem_dk_parse.v` | `mlkem_dk_parse` | TEST_OR_COMPATIBILITY_ONLY / KEEP | `run_m8_smoke.sh` runs `run_mlkem_dk_layout.sh`. |
| `rtl/mlkem/mlkem_zeroize_controller.v` | `mlkem_zeroize_controller` | TEST_OR_COMPATIBILITY_ONLY / KEEP | `run_m8_smoke.sh` runs `run_mlkem_zeroization.sh`. |
| `rtl/arithmetic/reduction.v` | `montgomery_reduce`, `barrett_reduce`, `conditional_sub_q` | ACTIVE_SHARED_LEAF plus LEGACY_OR_SUPERSEDED / REVIEW_MIXED_FILE, KEEP | The active `montgomery_reduce` shares this source with the two legacy declarations.  This cleanup does not split mixed files. |

## Collateral disposition

Dedicated legacy unit testbenches, runners, flat simulation lists, and M2.3
wrappers are removed with their sole DUT.  Composite M3--M6 regression runners
remain, with legacy-only invocations removed.  Historical reports remain as
evidence and are annotated where necessary; documentation is updated to
describe only files present in the release tree.

## Post-prune accounting target

The pre-prune tree contains 115 RTL source/include files and 116 module
declarations.  Hierarchy review reclassified three initially proposed legacy
files as active shared leaves, so this cleanup removes 29 single-module RTL
files.  The retained mixed `reduction.v` file keeps its active and unsplit
legacy declarations; therefore the expected current tree has 86 RTL
source/include files and 87 module declarations.  Superseded implementations remain available in Git
history before `pre-legacy-prune-b683bd7`.
