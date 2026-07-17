# Active Release Hierarchy

Source of truth: `synth/m9/rtl.f`, the M9 elaboration target, and textual instantiation scanning.

- Release top: `mlkem768_top`
- Transitive active modules: 73 of 116 declared modules.
- No module is marked unused from filename alone; inactive classifications require both graph absence and textual scan.

## Active modules by source

| Module | Source | Parents | Direct children |
|---|---|---|---|
| `barrett_reduce_pipe` | `rtl/arithmetic/barrett_reduce_pipe.v` | `mod_mul_normal_pipe`, `poly_reduce_pipe` | leaf |
| `basecase_mul_pipe` | `rtl/poly/basecase_mul_pipe.v` | `poly_basemul_pipe` | `fixed_latency_delay`, `mod_add_pipe`, `mod_mul_normal_pipe` |
| `butterfly_pipe` | `rtl/ntt/butterfly_pipe.v` | `ntt_core_pipe` | `fixed_latency_delay`, `mod_add_pipe`, `mod_mul_pipe`, `mod_sub_pipe` |
| `byte_decode_poly_pipe` | `rtl/codec/byte_decode_poly_pipe.v` | `poly_decode12_pipe`, `poly_decode_decompress_pipe` | leaf |
| `byte_encode_poly_pipe` | `rtl/codec/byte_encode_poly_pipe.v` | `poly_compress_encode_pipe`, `poly_encode12_pipe` | leaf |
| `fixed_latency_delay` | `rtl/control/fixed_latency_delay.v` | `basecase_mul_pipe`, `butterfly_pipe`, `intt_butterfly_pipe`, `intt_core_pipe`, `intt_scaler_pipe`, `ntt_core_pipe`, `poly_basemul_pipe` | leaf |
| `intt_butterfly_pipe` | `rtl/ntt/intt_butterfly_pipe.v` | `intt_core_pipe` | `fixed_latency_delay`, `mod_add_pipe`, `mod_mul_pipe`, `mod_sub_pipe` |
| `intt_core_pipe` | `rtl/ntt/intt_core_pipe.v` | `poly_transform_pipe` | `fixed_latency_delay`, `intt_butterfly_pipe`, `intt_scaler_pipe`, `intt_scheduler_pipe`, `ntt_pingpong_banks`, `zetas_rom` |
| `intt_scaler_pipe` | `rtl/ntt/intt_scaler_pipe.v` | `intt_core_pipe` | `fixed_latency_delay`, `mod_mul_pipe` |
| `intt_scheduler_pipe` | `rtl/ntt/intt_scheduler_pipe.v` | `intt_core_pipe` | `ntt_bank_map` |
| `keccak_f1600_core` | `rtl/keccak/keccak_f1600_core.v` | `keccak_sponge_ctx` | `keccak_round` |
| `keccak_hash_stream` | `rtl/keccak/keccak_hash_stream.v` | `mlkem_prf`, `sha3_256_stream`, `sha3_512_stream`, `shake128_stream`, `shake256_stream` | `keccak_sponge_ctx` |
| `keccak_round` | `rtl/keccak/keccak_round.v` | `keccak_f1600_core` | leaf |
| `keccak_sponge_ctx` | `rtl/keccak/keccak_sponge_ctx.v` | `keccak_hash_stream`, `mlkem_xof` | `keccak_f1600_core` |
| `kpke_decrypt` | `rtl/kpke/kpke_decrypt.v` | `mlkem_decaps_internal` | `poly_decode_decompress_pipe`, `poly_intt_pipe`, `poly_sub_pipe`, `poly_to_message_pipe`, `polyvec_basemul_acc_pipe`, `polyvec_decode12_pipe`, `polyvec_decode_decompress10_pipe`, `polyvec_ntt_pipe` |
| `kpke_encrypt` | `rtl/kpke/kpke_encrypt.v` | `mlkem_decaps_internal`, `mlkem_encaps_internal` | `kpke_matrix_row_sampler`, `kpke_noise_vector_sampler`, `message_to_poly_pipe`, `mlkem_noise_sampler`, `poly_add_pipe`, `poly_compress_encode_pipe`, `poly_intt_pipe`, `polyvec_basemul_acc_pipe`, `polyvec_compress_encode10_pipe`, `polyvec_decode12_pipe`, `polyvec_ntt_pipe` |
| `kpke_keygen` | `rtl/kpke/kpke_keygen.v` | `mlkem_keygen_internal` | `kpke_matrix_row_sampler`, `kpke_noise_vector_sampler`, `mlkem_g`, `poly_add_pipe`, `polyvec_basemul_acc_pipe`, `polyvec_encode12_pipe`, `polyvec_ntt_pipe` |
| `kpke_matrix_row_sampler` | `rtl/kpke/kpke_matrix_row_sampler.v` | `kpke_encrypt`, `kpke_keygen` | `mlkem_sample_ntt` |
| `kpke_noise_vector_sampler` | `rtl/kpke/kpke_noise_vector_sampler.v` | `kpke_encrypt`, `kpke_keygen` | `mlkem_noise_sampler` |
| `message_to_poly_pipe` | `rtl/codec/message_to_poly_pipe.v` | `kpke_encrypt` | `poly_decode_decompress_pipe` |
| `mlkem768_top` | `rtl/mlkem/mlkem768_top.v` | top | `mlkem_decaps`, `mlkem_encaps`, `mlkem_keygen` |
| `mlkem_decaps` | `rtl/mlkem/mlkem_decaps.v` | `mlkem768_top` | `mlkem_decaps_input_check`, `mlkem_decaps_internal` |
| `mlkem_decaps_input_check` | `rtl/mlkem/mlkem_decaps_input_check.v` | `mlkem_decaps` | `mlkem_h` |
| `mlkem_decaps_internal` | `rtl/mlkem/mlkem_decaps_internal.v` | `mlkem_decaps` | `kpke_decrypt`, `kpke_encrypt`, `mlkem_g`, `mlkem_j` |
| `mlkem_ek_check` | `rtl/mlkem/mlkem_ek_check.v` | `mlkem_encaps` | leaf |
| `mlkem_encaps` | `rtl/mlkem/mlkem_encaps.v` | `mlkem768_top` | `mlkem_ek_check`, `mlkem_encaps_internal` |
| `mlkem_encaps_internal` | `rtl/mlkem/mlkem_encaps_internal.v` | `mlkem_encaps` | `kpke_encrypt`, `mlkem_g`, `mlkem_h` |
| `mlkem_g` | `rtl/keccak/mlkem_g.v` | `kpke_keygen`, `mlkem_decaps_internal`, `mlkem_encaps_internal` | `sha3_512_stream` |
| `mlkem_h` | `rtl/keccak/mlkem_h.v` | `mlkem_decaps_input_check`, `mlkem_encaps_internal`, `mlkem_keygen_internal` | `sha3_256_stream` |
| `mlkem_j` | `rtl/keccak/mlkem_j.v` | `mlkem_decaps_internal` | `shake256_stream` |
| `mlkem_keygen` | `rtl/mlkem/mlkem_keygen.v` | `mlkem768_top` | `mlkem_keygen_internal` |
| `mlkem_keygen_internal` | `rtl/mlkem/mlkem_keygen_internal.v` | `mlkem_keygen` | `kpke_keygen`, `mlkem_h` |
| `mlkem_noise_sampler` | `rtl/sampler/mlkem_noise_sampler.v` | `kpke_encrypt`, `kpke_noise_vector_sampler` | `mlkem_prf`, `sample_poly_cbd_pipe` |
| `mlkem_prf` | `rtl/keccak/mlkem_prf.v` | `mlkem_noise_sampler` | `keccak_hash_stream` |
| `mlkem_sample_ntt` | `rtl/sampler/mlkem_sample_ntt.v` | `kpke_matrix_row_sampler` | `mlkem_xof`, `sample_ntt_parser` |
| `mlkem_xof` | `rtl/keccak/mlkem_xof.v` | `mlkem_sample_ntt` | `keccak_sponge_ctx` |
| `mod_add_pipe` | `rtl/arithmetic/mod_add_pipe.v` | `basecase_mul_pipe`, `butterfly_pipe`, `intt_butterfly_pipe`, `poly_binary_pipe`, `polyvec_basemul_acc_pipe` | leaf |
| `mod_mul` | `rtl/arithmetic/mod_mul.v` | `basemul_unit`, `butterfly_unit`, `intt_butterfly_unit`, `intt_core`, `poly_basemul_pipe` | `montgomery_reduce` |
| `mod_mul_normal_pipe` | `rtl/arithmetic/mod_mul_normal_pipe.v` | `basecase_mul_pipe` | `barrett_reduce_pipe` |
| `mod_mul_pipe` | `rtl/arithmetic/mod_mul_pipe.v` | `butterfly_pipe`, `intt_butterfly_pipe`, `intt_scaler_pipe` | `montgomery_reduce_pipe` |
| `mod_sub_pipe` | `rtl/arithmetic/mod_sub_pipe.v` | `butterfly_pipe`, `intt_butterfly_pipe`, `poly_binary_pipe` | leaf |
| `montgomery_reduce` | `rtl/arithmetic/reduction.v` | `mod_mul` | leaf |
| `montgomery_reduce_pipe` | `rtl/arithmetic/montgomery_reduce_pipe.v` | `mod_mul_pipe` | leaf |
| `ntt_bank_map` | `rtl/memory/ntt_bank_map.v` | `intt_scheduler_pipe`, `ntt_core_pipe`, `ntt_pingpong_banks`, `ntt_scheduler_pipe` | leaf |
| `ntt_core_pipe` | `rtl/ntt/ntt_core_pipe.v` | `poly_transform_pipe` | `butterfly_pipe`, `fixed_latency_delay`, `ntt_bank_map`, `ntt_pingpong_banks`, `ntt_scheduler_pipe`, `zetas_rom` |
| `ntt_pingpong_banks` | `rtl/memory/ntt_pingpong_banks.v` | `intt_core_pipe`, `ntt_core_pipe` | `ntt_bank_map`, `sync_1r1w_ram` |
| `ntt_scheduler_pipe` | `rtl/ntt/ntt_scheduler_pipe.v` | `ntt_core_pipe` | `ntt_bank_map` |
| `poly_add_pipe` | `rtl/poly/poly_add_pipe.v` | `kpke_encrypt`, `kpke_keygen` | `poly_binary_pipe` |
| `poly_basemul_pipe` | `rtl/poly/poly_basemul_pipe.v` | `polyvec_basemul_acc_pipe` | `basecase_mul_pipe`, `fixed_latency_delay`, `mod_mul`, `poly_workspace`, `zetas_rom` |
| `poly_binary_pipe` | `rtl/poly/poly_binary_pipe.v` | `poly_add_pipe`, `poly_sub_pipe` | `mod_add_pipe`, `mod_sub_pipe`, `poly_workspace` |
| `poly_compress_encode_pipe` | `rtl/codec/poly_compress_encode_pipe.v` | `kpke_encrypt`, `poly_to_message_pipe` | `byte_encode_poly_pipe` |
| `poly_decode_decompress_pipe` | `rtl/codec/poly_decode_decompress_pipe.v` | `kpke_decrypt`, `message_to_poly_pipe` | `byte_decode_poly_pipe` |
| `poly_intt_pipe` | `rtl/poly/poly_intt_pipe.v` | `kpke_decrypt`, `kpke_encrypt` | `poly_transform_pipe` |
| `poly_sub_pipe` | `rtl/poly/poly_sub_pipe.v` | `kpke_decrypt` | `poly_binary_pipe` |
| `poly_to_message_pipe` | `rtl/codec/poly_to_message_pipe.v` | `kpke_decrypt` | `poly_compress_encode_pipe` |
| `poly_transform_pipe` | `rtl/poly/poly_transform_pipe.v` | `poly_intt_pipe`, `poly_ntt_pipe` | `intt_core_pipe`, `ntt_core_pipe`, `poly_workspace` |
| `poly_workspace` | `rtl/poly/poly_workspace.v` | `poly_basemul_pipe`, `poly_binary_pipe`, `poly_reduce_pipe`, `poly_transform_pipe`, `polyvec_basemul_acc_pipe`, `polyvec_workspace` | leaf |
| `polyvec_basemul_acc_pipe` | `rtl/poly/polyvec_basemul_acc_pipe.v` | `kpke_decrypt`, `kpke_encrypt`, `kpke_keygen` | `mod_add_pipe`, `poly_basemul_pipe`, `poly_workspace`, `polyvec_workspace` |
| `polyvec_codec_pipe` | `rtl/codec/polyvec_codec_pipe.v` | `polyvec_compress_encode10_pipe`, `polyvec_decode12_pipe`, `polyvec_decode_decompress10_pipe`, `polyvec_encode12_pipe` | leaf |
| `polyvec_compress_encode10_pipe` | `rtl/codec/polyvec_compress_encode10_pipe.v` | `kpke_encrypt` | `polyvec_codec_pipe` |
| `polyvec_decode12_pipe` | `rtl/codec/polyvec_decode12_pipe.v` | `kpke_decrypt`, `kpke_encrypt` | `polyvec_codec_pipe` |
| `polyvec_decode_decompress10_pipe` | `rtl/codec/polyvec_decode_decompress10_pipe.v` | `kpke_decrypt` | `polyvec_codec_pipe` |
| `polyvec_elementwise_pipe` | `rtl/poly/polyvec_elementwise_pipe.v` | `polyvec_add_pipe`, `polyvec_intt_pipe`, `polyvec_ntt_pipe`, `polyvec_reduce_pipe`, `polyvec_sub_pipe` | `polyvec_workspace` |
| `polyvec_encode12_pipe` | `rtl/codec/polyvec_encode12_pipe.v` | `kpke_keygen` | `polyvec_codec_pipe` |
| `polyvec_ntt_pipe` | `rtl/poly/polyvec_ntt_pipe.v` | `kpke_decrypt`, `kpke_encrypt`, `kpke_keygen` | `polyvec_elementwise_pipe` |
| `polyvec_workspace` | `rtl/poly/polyvec_workspace.v` | `polyvec_basemul_acc_pipe`, `polyvec_elementwise_pipe` | `poly_workspace` |
| `sample_ntt_parser` | `rtl/sampler/sample_ntt_parser.v` | `mlkem_sample_ntt` | leaf |
| `sample_poly_cbd_pipe` | `rtl/sampler/sample_poly_cbd_pipe.v` | `mlkem_noise_sampler` | leaf |
| `sha3_256_stream` | `rtl/keccak/sha3_256_stream.v` | `mlkem_h` | `keccak_hash_stream` |
| `sha3_512_stream` | `rtl/keccak/sha3_512_stream.v` | `mlkem_g` | `keccak_hash_stream` |
| `shake256_stream` | `rtl/keccak/shake256_stream.v` | `mlkem_j` | `keccak_hash_stream` |
| `sync_1r1w_ram` | `rtl/memory/sync_1r1w_ram.v` | `ntt_pingpong_banks` | leaf |
| `zetas_rom` | `rtl/ntt/zetas_rom.v` | `intt_core`, `intt_core_pipe`, `ntt_core`, `ntt_core_pipe`, `poly_basemul_montgomery`, `poly_basemul_pipe` | leaf |
