# RTL Reading Roadmap

Read the release from stable constants and leaves toward the public controller.  Every linked source is synthesizable and listed in `synth/m9/rtl.f`.

## Leaf-to-top path

| Step | Topic | RTL | Contract/guide |
|---:|---|---|---|
| 1 | Parameters | `rtl/common/kyber_params.vh` | `docs/03_architecture/interface_contract.md` |
| 2 | Control timing | `rtl/control/fixed_latency_delay.v` | `docs/03_architecture/pipeline_contract.md` |
| 3 | Mod-q arithmetic | `rtl/arithmetic/mod_add_pipe.v` | `docs/05_code_guide/02_arithmetic.md` |
| 4 | Memory and bank map | `rtl/memory/sync_1r1w_ram.v` | `docs/05_code_guide/03_memory.md` |
| 5 | Butterflies and schedules | `rtl/ntt/butterfly_pipe.v` | `docs/05_code_guide/04_ntt_intt.md` |
| 6 | Transform cores | `rtl/ntt/ntt_core_pipe.v` | `docs/05_code_guide/04_ntt_intt.md` |
| 7 | Polynomial workspace | `rtl/poly/poly_workspace.v` | `docs/05_code_guide/05_poly_polyvec.md` |
| 8 | Polyvec operations | `rtl/poly/polyvec_workspace.v` | `docs/05_code_guide/05_poly_polyvec.md` |
| 9 | Keccak leaves | `rtl/keccak/keccak_round.v` | `docs/05_code_guide/06_keccak.md` |
| 10 | Sponge and hash services | `rtl/keccak/keccak_sponge_ctx.v` | `docs/05_code_guide/06_keccak.md` |
| 11 | Codecs | `rtl/codec/byte_encode_poly_pipe.v` | `docs/05_code_guide/07_codec_sampler.md` |
| 12 | Sampling | `rtl/sampler/mlkem_sample_ntt.v` | `docs/05_code_guide/07_codec_sampler.md` |
| 13 | K-PKE | `rtl/kpke/kpke_keygen.v` | `docs/05_code_guide/08_kpke.md` |
| 14 | ML-KEM internal/public controllers | `rtl/mlkem/mlkem_keygen_internal.v` | `docs/05_code_guide/09_mlkem_top.md` |
| 15 | Unified top | `rtl/mlkem/mlkem768_top.v` | `docs/04_design/mlkem768_release_interface.md` |

## How to read a controller

1. Read ports and record constants first.  2. Identify child instances and their request wiring.  3. Read state encodings and grouped FSM phases.  4. Trace result capture into owned buffers.  5. Trace output valid/ready behavior.  6. Finish with reset/zeroize invalidation; do not mistake it for complete physical destruction.
