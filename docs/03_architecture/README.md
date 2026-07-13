# Architecture Notes

Use this folder for hardware architecture planning.

Capture block diagrams, interface assumptions, scheduling ideas, and memory traffic before implementing major RTL blocks.

M1 v0.1 contract sources:

- `interface_contract.md`
- `representation_domain_contract.md`
- `reset_control_contract.md`
- `pipeline_contract.md`
- `memory_architecture.md`
- `ntt_architecture.md`

These contracts govern future RTL. Existing baseline RTL may differ and is not
silently reclassified as compliant.

M3 implementation freeze and M4 handoff:

- `../04_design/ntt_intt_engine_contract.md`
- `../04_design/m4_poly_polyvec_handoff.md`
- `../04_design/poly_polyvec_engine_contract.md`
- `../04_design/poly_basemul_contract.md`
- `../04_design/m4_to_kpke_handoff.md`
