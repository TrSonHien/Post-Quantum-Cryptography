# Milestone Status

## Current Milestone

M0: Standards, algorithm tracking, KAT, and independent golden models

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

## In Progress

- None. Do not start M1 without explicit approval.

## Blocked By

- None

## Latest Failing Test

None

## Next Target

Await explicit approval and architecture decisions before M1. Final CAVP/ACVP
ML-KEM KAT verification remains pending and must be added when authoritative
vectors are obtained.

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
