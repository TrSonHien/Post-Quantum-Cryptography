# Active, Wrapper, and Legacy Modules

The release hierarchy is rooted at `mlkem768_top`; an inactive module remains retained for independent tests, compatibility, or an earlier architectural alternative.  It is not deleted by this readability campaign.

## Families that intentionally coexist

| Family | Active release selection | Retained alternative | Why both remain |
|---|---|---|---|
| modular add/subtract | `mod_add_pipe`, `mod_sub_pipe` | `mod_add`, `mod_sub` | Pipelined release leaf versus compact/legacy reference leaf. |
| modular multiply/reduction | `mod_mul_pipe`, `montgomery_reduce_pipe`, `barrett_reduce_pipe` | `mod_mul`, `montgomery_reduce`, `barrett_reduce` | Pipeline and legacy/reference implementations support independent checks. |
| NTT/INTT | `ntt_core_pipe`, `intt_core_pipe` | `ntt_core`, `intt_core` | Pipelined release cores coexist with earlier controller implementations. |
| polynomial primitives | `*_pipe` release adapters | unpipelined `poly_add`, `poly_sub`, `poly_reduce` and related helpers | Retained for focused tests, comparison, and compatibility. |

## Classification list

### ACTIVE_RELEASE_PATH

- `kpke_decrypt` — `rtl/kpke/kpke_decrypt.v`
- `kpke_encrypt` — `rtl/kpke/kpke_encrypt.v`
- `kpke_keygen` — `rtl/kpke/kpke_keygen.v`
- `kpke_matrix_row_sampler` — `rtl/kpke/kpke_matrix_row_sampler.v`
- `kpke_noise_vector_sampler` — `rtl/kpke/kpke_noise_vector_sampler.v`
- `mlkem768_top` — `rtl/mlkem/mlkem768_top.v`
- `mlkem_decaps` — `rtl/mlkem/mlkem_decaps.v`
- `mlkem_decaps_input_check` — `rtl/mlkem/mlkem_decaps_input_check.v`
- `mlkem_decaps_internal` — `rtl/mlkem/mlkem_decaps_internal.v`
- `mlkem_ek_check` — `rtl/mlkem/mlkem_ek_check.v`
- `mlkem_encaps` — `rtl/mlkem/mlkem_encaps.v`
- `mlkem_encaps_internal` — `rtl/mlkem/mlkem_encaps_internal.v`
- `mlkem_keygen` — `rtl/mlkem/mlkem_keygen.v`
- `mlkem_keygen_internal` — `rtl/mlkem/mlkem_keygen_internal.v`

### ACTIVE_SHARED_LEAF

- `barrett_reduce_pipe` — `rtl/arithmetic/barrett_reduce_pipe.v`
- `basecase_mul_pipe` — `rtl/poly/basecase_mul_pipe.v`
- `butterfly_pipe` — `rtl/ntt/butterfly_pipe.v`
- `byte_decode_poly_pipe` — `rtl/codec/byte_decode_poly_pipe.v`
- `byte_encode_poly_pipe` — `rtl/codec/byte_encode_poly_pipe.v`
- `fixed_latency_delay` — `rtl/control/fixed_latency_delay.v`
- `intt_butterfly_pipe` — `rtl/ntt/intt_butterfly_pipe.v`
- `intt_core_pipe` — `rtl/ntt/intt_core_pipe.v`
- `intt_scaler_pipe` — `rtl/ntt/intt_scaler_pipe.v`
- `intt_scheduler_pipe` — `rtl/ntt/intt_scheduler_pipe.v`
- `keccak_f1600_core` — `rtl/keccak/keccak_f1600_core.v`
- `keccak_hash_stream` — `rtl/keccak/keccak_hash_stream.v`
- `keccak_round` — `rtl/keccak/keccak_round.v`
- `keccak_sponge_ctx` — `rtl/keccak/keccak_sponge_ctx.v`
- `message_to_poly_pipe` — `rtl/codec/message_to_poly_pipe.v`
- `mlkem_g` — `rtl/keccak/mlkem_g.v`
- `mlkem_h` — `rtl/keccak/mlkem_h.v`
- `mlkem_j` — `rtl/keccak/mlkem_j.v`
- `mlkem_noise_sampler` — `rtl/sampler/mlkem_noise_sampler.v`
- `mlkem_prf` — `rtl/keccak/mlkem_prf.v`
- `mlkem_sample_ntt` — `rtl/sampler/mlkem_sample_ntt.v`
- `mlkem_xof` — `rtl/keccak/mlkem_xof.v`
- `mod_add_pipe` — `rtl/arithmetic/mod_add_pipe.v`
- `mod_mul` — `rtl/arithmetic/mod_mul.v`
- `mod_mul_normal_pipe` — `rtl/arithmetic/mod_mul_normal_pipe.v`
- `mod_mul_pipe` — `rtl/arithmetic/mod_mul_pipe.v`
- `mod_sub_pipe` — `rtl/arithmetic/mod_sub_pipe.v`
- `montgomery_reduce` — `rtl/arithmetic/reduction.v`
- `montgomery_reduce_pipe` — `rtl/arithmetic/montgomery_reduce_pipe.v`
- `ntt_bank_map` — `rtl/memory/ntt_bank_map.v`
- `ntt_core_pipe` — `rtl/ntt/ntt_core_pipe.v`
- `ntt_pingpong_banks` — `rtl/memory/ntt_pingpong_banks.v`
- `ntt_scheduler_pipe` — `rtl/ntt/ntt_scheduler_pipe.v`
- `poly_add_pipe` — `rtl/poly/poly_add_pipe.v`
- `poly_basemul_pipe` — `rtl/poly/poly_basemul_pipe.v`
- `poly_binary_pipe` — `rtl/poly/poly_binary_pipe.v`
- `poly_compress_encode_pipe` — `rtl/codec/poly_compress_encode_pipe.v`
- `poly_decode_decompress_pipe` — `rtl/codec/poly_decode_decompress_pipe.v`
- `poly_intt_pipe` — `rtl/poly/poly_intt_pipe.v`
- `poly_sub_pipe` — `rtl/poly/poly_sub_pipe.v`
- `poly_to_message_pipe` — `rtl/codec/poly_to_message_pipe.v`
- `poly_transform_pipe` — `rtl/poly/poly_transform_pipe.v`
- `poly_workspace` — `rtl/poly/poly_workspace.v`
- `polyvec_basemul_acc_pipe` — `rtl/poly/polyvec_basemul_acc_pipe.v`
- `polyvec_codec_pipe` — `rtl/codec/polyvec_codec_pipe.v`
- `polyvec_compress_encode10_pipe` — `rtl/codec/polyvec_compress_encode10_pipe.v`
- `polyvec_decode12_pipe` — `rtl/codec/polyvec_decode12_pipe.v`
- `polyvec_decode_decompress10_pipe` — `rtl/codec/polyvec_decode_decompress10_pipe.v`
- `polyvec_elementwise_pipe` — `rtl/poly/polyvec_elementwise_pipe.v`
- `polyvec_encode12_pipe` — `rtl/codec/polyvec_encode12_pipe.v`
- `polyvec_ntt_pipe` — `rtl/poly/polyvec_ntt_pipe.v`
- `polyvec_workspace` — `rtl/poly/polyvec_workspace.v`
- `sample_ntt_parser` — `rtl/sampler/sample_ntt_parser.v`
- `sample_poly_cbd_pipe` — `rtl/sampler/sample_poly_cbd_pipe.v`
- `sha3_256_stream` — `rtl/keccak/sha3_256_stream.v`
- `sha3_512_stream` — `rtl/keccak/sha3_512_stream.v`
- `shake256_stream` — `rtl/keccak/shake256_stream.v`
- `sync_1r1w_ram` — `rtl/memory/sync_1r1w_ram.v`
- `zetas_rom` — `rtl/ntt/zetas_rom.v`

### WRAPPER_OR_ADAPTER

- `kpke_format_pipe` — `rtl/codec/kpke_format_pipe.v`
- `mlkem_byte_buffer` — `rtl/mlkem/mlkem_byte_buffer.v`
- `ntt_addr_gen` — `rtl/ntt/ntt_addr_gen.v`
- `poly_basemul_addr_gen` — `rtl/poly/poly_basemul_addr_gen.v`
- `poly_buffer` — `rtl/memory/poly_buffer.v`

### LEGACY_OR_SUPERSEDED

- `barrett_reduce` — `rtl/arithmetic/reduction.v`
- `basemul_unit` — `rtl/ntt/basemul_unit.v`
- `bits_to_bytes_pipe` — `rtl/codec/bits_to_bytes_pipe.v`
- `butterfly_unit` — `rtl/ntt/butterfly_unit.v`
- `bytes_to_bits_pipe` — `rtl/codec/bytes_to_bits_pipe.v`
- `cbd_pair_pipe` — `rtl/sampler/cbd_pair_pipe.v`
- `compress_coeff_pipe` — `rtl/codec/compress_coeff_pipe.v`
- `conditional_sub_q` — `rtl/arithmetic/reduction.v`
- `decompress_coeff_pipe` — `rtl/codec/decompress_coeff_pipe.v`
- `intt_butterfly_unit` — `rtl/ntt/intt_butterfly_unit.v`
- `intt_core` — `rtl/ntt/intt_core.v`
- `kpke_ciphertext_pack_pipe` — `rtl/codec/kpke_ciphertext_pack_pipe.v`
- `kpke_ciphertext_unpack_pipe` — `rtl/codec/kpke_ciphertext_unpack_pipe.v`
- `kpke_dk_pack_pipe` — `rtl/codec/kpke_dk_pack_pipe.v`
- `kpke_dk_unpack_pipe` — `rtl/codec/kpke_dk_unpack_pipe.v`
- `kpke_ek_pack_pipe` — `rtl/codec/kpke_ek_pack_pipe.v`
- `kpke_ek_unpack_pipe` — `rtl/codec/kpke_ek_unpack_pipe.v`
- `mod_add` — `rtl/arithmetic/mod_add.v`
- `mod_sub` — `rtl/arithmetic/mod_sub.v`
- `ntt_core` — `rtl/ntt/ntt_core.v`
- `poly_add` — `rtl/poly/poly_add.v`
- `poly_basemul_montgomery` — `rtl/poly/poly_basemul_montgomery.v`
- `poly_decode12_pipe` — `rtl/codec/poly_decode12_pipe.v`
- `poly_encode12_pipe` — `rtl/codec/poly_encode12_pipe.v`
- `poly_ntt_pipe` — `rtl/poly/poly_ntt_pipe.v`
- `poly_reduce` — `rtl/poly/poly_reduce.v`
- `poly_reduce_pipe` — `rtl/poly/poly_reduce_pipe.v`
- `poly_sub` — `rtl/poly/poly_sub.v`
- `polyvec_add_pipe` — `rtl/poly/polyvec_add_pipe.v`
- `polyvec_intt_pipe` — `rtl/poly/polyvec_intt_pipe.v`
- `polyvec_reduce_pipe` — `rtl/poly/polyvec_reduce_pipe.v`
- `polyvec_sub_pipe` — `rtl/poly/polyvec_sub_pipe.v`

### TEST_OR_COMPATIBILITY_ONLY

- `mlkem_ct_compare_select` — `rtl/mlkem/mlkem_ct_compare_select.v`
- `mlkem_dk_assemble` — `rtl/mlkem/mlkem_dk_assemble.v`
- `mlkem_dk_parse` — `rtl/mlkem/mlkem_dk_parse.v`
- `mlkem_zeroize_controller` — `rtl/mlkem/mlkem_zeroize_controller.v`
- `rv_register_slice` — `rtl/control/rv_register_slice.v`
- `shake128_stream` — `rtl/keccak/shake128_stream.v`
