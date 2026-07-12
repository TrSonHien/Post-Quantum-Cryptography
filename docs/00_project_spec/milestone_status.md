# Milestone Status

## Current Milestone

M2: Contract-compliant RTL foundations

## Completed

- Initial repository exists.
- Main roadmap file exists.
- Active repository structure is focused on algorithm study, reference models, KATs, RTL, testbenches, and simulation.
- Original PDFs and standards are kept under `references/`.
- `docs/` is reserved for project-written notes, architecture documents, and verification plans.
- Root `AGENTS.md` discovers the project instruction file through the local symlink.
- M0.1 source, standards, and provenance audit.
- M0.2 detailed FIPS 203 algorithm tracking.
- M0.3 legacy Kyber768 C/KAT harness.
- M0.4a independent Python foundation layer for ML-KEM-768 low-level algorithms.
- M0.4b complete deterministic internal Python ML-KEM-768 golden model.
- M0.5 comparison tools, vector export infrastructure, and final M0 report.
- M0 milestone closed with final NIST CAVP/ACVP verification explicitly pending.
- M1 v0.1 documentation freeze: interface, representation/domain, reset/control,
  pipeline metadata, synchronous memory, and NTT/INTT banking contracts.
- Conflict-free two-source/two-destination bank schedule proof and complete
  forward/inverse stage tables.
- Python-vector-to-RTL mapping and architecture assertion/verification plan.
- Stale `poly_sub` report reconciled against a live 1024/0 PASS regression.
- M2.1 synchronous memory and pipeline-control primitives.
- M2.1 exhaustive bank mapping/ping-pong, collision, reset, latency, metadata,
  and backpressure unit verification.

## In Progress

- None. Do not start M2.2 without explicit approval.

## Blocked By

- None

## Latest Failing Test

None

## Next Target

Await explicit approval before M2.2. M2.1 provides reusable storage/control
primitives only; no arithmetic or NTT controller has started. Final CAVP/ACVP
ML-KEM verification remains pending.

## Current Focus

```text
standards and provenance -> FIPS algorithm tracking -> KAT provenance ->
independent golden models -> comparison tools -> architecture freeze -> RTL
```

## Explicitly Excluded From Current Phase

- Genus
- Innovus
- PnR
- STA
- GDSII
- Physical Design

## Notes for Future Continuation

Before continuing, read:

1. TODO.md
2. AGENTS.md
3. docs/00_project_spec/m0_plan.md
4. docs/00_project_spec/fips203_algorithm_tracking.md
5. docs/01_standard/source_provenance.md
6. reports/m0_source_audit.md
7. reports/m0_3_c_kat_harness.md
8. ref_model/kat/kyber768_legacy_provenance.md
9. reports/m0_4a_python_foundations.md
10. reports/m0_4b_python_mlkem_model.md
11. reports/m0_5_comparison_tools.md
12. reports/m0_completion_report.md
13. docs/00_project_spec/m1_plan.md
14. docs/03_architecture/interface_contract.md
15. docs/03_architecture/representation_domain_contract.md
16. docs/03_architecture/reset_control_contract.md
17. docs/03_architecture/pipeline_contract.md
18. docs/04_verification/m1_architecture_verification_plan.md
19. reports/m1_architecture_freeze_v0_1.md
