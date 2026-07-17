# Active Release Hierarchy

Source of truth: `synth/m9/rtl.f`, `sim/scripts/run_m9_elaboration.sh`, and
selected elaboration rooted at `mlkem768_top`.  The current list has 85 Verilog
sources plus `rtl/common/kyber_params.vh`, defining 87 modules.

```mermaid
flowchart TD
  TOP[mlkem768_top] --> KG[mlkem_keygen]
  TOP --> EN[mlkem_encaps]
  TOP --> DE[mlkem_decaps]
  KG --> KGI[mlkem_keygen_internal]
  EN --> ENI[mlkem_encaps_internal]
  DE --> DCI[mlkem_decaps_internal]
  KGI --> KPK[ kpke_keygen ]
  ENI --> KPE[kpke_encrypt]
  DCI --> KPD[kpke_decrypt]
  DCI --> KPE
  KPK --> NTT[polyvec_ntt_pipe -> poly_ntt_pipe -> poly_transform_pipe]
  KPE --> NTT
  KPD --> NTT
  NTT --> CORES[ntt_core_pipe / intt_core_pipe]
  KPK --> CODEC[polyvec_encode12_pipe -> polyvec_codec_pipe]
  KPE --> CODEC
  KPD --> CODEC
  CODEC --> P12[poly_encode12_pipe / poly_decode12_pipe]
  KPK --> HASH[H/G/J, SHA3, SHAKE256]
  KPE --> HASH
  KPD --> HASH
```

## Release-path facts

- `poly_ntt_pipe` is an active forward-NTT adapter selected by
  `polyvec_ntt_pipe` in all K-PKE controllers.
- `poly_encode12_pipe` and `poly_decode12_pipe` are active 12-bit codec
  adapters selected by the K-PKE public-key polyvec codec wrappers.
- The generic `polyvec_elementwise_pipe` contains non-release generate modes;
  only its selected `OP=3` path is part of `mlkem768_top`.
- Four test/compatibility modules are not top-level children but are retained
  because `run_m8_smoke.sh` invokes their unit tests.
- `barrett_reduce` and `conditional_sub_q` remain only as declarations sharing
  the active `rtl/arithmetic/reduction.v` source; neither is selected by the
  elaborated release hierarchy.

For the complete current classification, see [module_catalog.md](module_catalog.md).
Superseded RTL implementations remain available in Git history before
`pre-legacy-prune-b683bd7`.
