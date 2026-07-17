# RTL Module Catalog

This is the current release-tree catalog after the legacy RTL prune.  It lists
only source files present in this checkout.  Superseded RTL implementations
remain available in Git history before `pre-legacy-prune-b683bd7`.

## Classification totals

| Classification | Modules |
|---|---:|
| ACTIVE_RELEASE_PATH | 14 |
| ACTIVE_SHARED_LEAF | 62 |
| WRAPPER_OR_ADAPTER | 5 |
| TEST_OR_COMPATIBILITY_ONLY | 4 |
| LEGACY_OR_SUPERSEDED (mixed source retained) | 2 |
| **Total** | **87** |

## ACTIVE_RELEASE_PATH

| Module | Source |
|---|---|
| `kpke_decrypt` | `rtl/kpke/kpke_decrypt.v` |
| `kpke_encrypt` | `rtl/kpke/kpke_encrypt.v` |
| `kpke_keygen` | `rtl/kpke/kpke_keygen.v` |
| `kpke_matrix_row_sampler` | `rtl/kpke/kpke_matrix_row_sampler.v` |
| `kpke_noise_vector_sampler` | `rtl/kpke/kpke_noise_vector_sampler.v` |
| `mlkem768_top` | `rtl/mlkem/mlkem768_top.v` |
| `mlkem_decaps` | `rtl/mlkem/mlkem_decaps.v` |
| `mlkem_decaps_input_check` | `rtl/mlkem/mlkem_decaps_input_check.v` |
| `mlkem_decaps_internal` | `rtl/mlkem/mlkem_decaps_internal.v` |
| `mlkem_ek_check` | `rtl/mlkem/mlkem_ek_check.v` |
| `mlkem_encaps` | `rtl/mlkem/mlkem_encaps.v` |
| `mlkem_encaps_internal` | `rtl/mlkem/mlkem_encaps_internal.v` |
| `mlkem_keygen` | `rtl/mlkem/mlkem_keygen.v` |
| `mlkem_keygen_internal` | `rtl/mlkem/mlkem_keygen_internal.v` |

## ACTIVE_SHARED_LEAF

| Module | Source |
|---|---|
| `barrett_reduce_pipe` | `rtl/arithmetic/barrett_reduce_pipe.v` |
| `basecase_mul_pipe` | `rtl/poly/basecase_mul_pipe.v` |
| `butterfly_pipe` | `rtl/ntt/butterfly_pipe.v` |
| `byte_decode_poly_pipe` | `rtl/codec/byte_decode_poly_pipe.v` |
| `byte_encode_poly_pipe` | `rtl/codec/byte_encode_poly_pipe.v` |
| `fixed_latency_delay` | `rtl/control/fixed_latency_delay.v` |
| `intt_butterfly_pipe` | `rtl/ntt/intt_butterfly_pipe.v` |
| `intt_core_pipe` | `rtl/ntt/intt_core_pipe.v` |
| `intt_scaler_pipe` | `rtl/ntt/intt_scaler_pipe.v` |
| `intt_scheduler_pipe` | `rtl/ntt/intt_scheduler_pipe.v` |
| `keccak_f1600_core` | `rtl/keccak/keccak_f1600_core.v` |
| `keccak_hash_stream` | `rtl/keccak/keccak_hash_stream.v` |
| `keccak_round` | `rtl/keccak/keccak_round.v` |
| `keccak_sponge_ctx` | `rtl/keccak/keccak_sponge_ctx.v` |
| `message_to_poly_pipe` | `rtl/codec/message_to_poly_pipe.v` |
| `mlkem_g` | `rtl/keccak/mlkem_g.v` |
| `mlkem_h` | `rtl/keccak/mlkem_h.v` |
| `mlkem_j` | `rtl/keccak/mlkem_j.v` |
| `mlkem_noise_sampler` | `rtl/sampler/mlkem_noise_sampler.v` |
| `mlkem_prf` | `rtl/keccak/mlkem_prf.v` |
| `mlkem_sample_ntt` | `rtl/sampler/mlkem_sample_ntt.v` |
| `mlkem_xof` | `rtl/keccak/mlkem_xof.v` |
| `mod_add_pipe` | `rtl/arithmetic/mod_add_pipe.v` |
| `mod_mul` | `rtl/arithmetic/mod_mul.v` |
| `mod_mul_normal_pipe` | `rtl/arithmetic/mod_mul_normal_pipe.v` |
| `mod_mul_pipe` | `rtl/arithmetic/mod_mul_pipe.v` |
| `mod_sub_pipe` | `rtl/arithmetic/mod_sub_pipe.v` |
| `montgomery_reduce` | `rtl/arithmetic/reduction.v` |
| `montgomery_reduce_pipe` | `rtl/arithmetic/montgomery_reduce_pipe.v` |
| `ntt_bank_map` | `rtl/memory/ntt_bank_map.v` |
| `ntt_core_pipe` | `rtl/ntt/ntt_core_pipe.v` |
| `ntt_pingpong_banks` | `rtl/memory/ntt_pingpong_banks.v` |
| `ntt_scheduler_pipe` | `rtl/ntt/ntt_scheduler_pipe.v` |
| `poly_add_pipe` | `rtl/poly/poly_add_pipe.v` |
| `poly_basemul_pipe` | `rtl/poly/poly_basemul_pipe.v` |
| `poly_binary_pipe` | `rtl/poly/poly_binary_pipe.v` |
| `poly_compress_encode_pipe` | `rtl/codec/poly_compress_encode_pipe.v` |
| `poly_decode12_pipe` | `rtl/codec/poly_decode12_pipe.v` |
| `poly_decode_decompress_pipe` | `rtl/codec/poly_decode_decompress_pipe.v` |
| `poly_encode12_pipe` | `rtl/codec/poly_encode12_pipe.v` |
| `poly_intt_pipe` | `rtl/poly/poly_intt_pipe.v` |
| `poly_ntt_pipe` | `rtl/poly/poly_ntt_pipe.v` |
| `poly_sub_pipe` | `rtl/poly/poly_sub_pipe.v` |
| `poly_to_message_pipe` | `rtl/codec/poly_to_message_pipe.v` |
| `poly_transform_pipe` | `rtl/poly/poly_transform_pipe.v` |
| `poly_workspace` | `rtl/poly/poly_workspace.v` |
| `polyvec_basemul_acc_pipe` | `rtl/poly/polyvec_basemul_acc_pipe.v` |
| `polyvec_codec_pipe` | `rtl/codec/polyvec_codec_pipe.v` |
| `polyvec_compress_encode10_pipe` | `rtl/codec/polyvec_compress_encode10_pipe.v` |
| `polyvec_decode12_pipe` | `rtl/codec/polyvec_decode12_pipe.v` |
| `polyvec_decode_decompress10_pipe` | `rtl/codec/polyvec_decode_decompress10_pipe.v` |
| `polyvec_elementwise_pipe` | `rtl/poly/polyvec_elementwise_pipe.v` |
| `polyvec_encode12_pipe` | `rtl/codec/polyvec_encode12_pipe.v` |
| `polyvec_ntt_pipe` | `rtl/poly/polyvec_ntt_pipe.v` |
| `polyvec_workspace` | `rtl/poly/polyvec_workspace.v` |
| `sample_ntt_parser` | `rtl/sampler/sample_ntt_parser.v` |
| `sample_poly_cbd_pipe` | `rtl/sampler/sample_poly_cbd_pipe.v` |
| `sha3_256_stream` | `rtl/keccak/sha3_256_stream.v` |
| `sha3_512_stream` | `rtl/keccak/sha3_512_stream.v` |
| `shake256_stream` | `rtl/keccak/shake256_stream.v` |
| `sync_1r1w_ram` | `rtl/memory/sync_1r1w_ram.v` |
| `zetas_rom` | `rtl/ntt/zetas_rom.v` |

## WRAPPER_OR_ADAPTER

| Module | Source |
|---|---|
| `kpke_format_pipe` | `rtl/codec/kpke_format_pipe.v` |
| `mlkem_byte_buffer` | `rtl/mlkem/mlkem_byte_buffer.v` |
| `ntt_addr_gen` | `rtl/ntt/ntt_addr_gen.v` |
| `poly_basemul_addr_gen` | `rtl/poly/poly_basemul_addr_gen.v` |
| `poly_buffer` | `rtl/memory/poly_buffer.v` |

## TEST_OR_COMPATIBILITY_ONLY (kept)

| Module | Source | Required release-check dependency |
|---|---|---|
| `mlkem_ct_compare_select` | `rtl/mlkem/mlkem_ct_compare_select.v` | `run_m8_smoke.sh` → compare-select unit check |
| `mlkem_dk_assemble` | `rtl/mlkem/mlkem_dk_assemble.v` | `run_m8_smoke.sh` → DK-layout unit check |
| `mlkem_dk_parse` | `rtl/mlkem/mlkem_dk_parse.v` | `run_m8_smoke.sh` → DK-layout unit check |
| `mlkem_zeroize_controller` | `rtl/mlkem/mlkem_zeroize_controller.v` | `run_m8_smoke.sh` → zeroize unit check |

## LEGACY_OR_SUPERSEDED (mixed source retained)

| Module | Source | Action |
|---|---|---|
| `barrett_reduce` | `rtl/arithmetic/reduction.v` | Retained only because it shares `reduction.v` with active `montgomery_reduce`. |
| `conditional_sub_q` | `rtl/arithmetic/reduction.v` | Retained only because it shares `reduction.v` with active `montgomery_reduce`. |

For hierarchy, contracts, and reading order, see the neighboring code-guide
documents.  Do not treat unselected generic generate branches as release-path
dependencies; the elaborated `mlkem768_top` hierarchy is authoritative.
