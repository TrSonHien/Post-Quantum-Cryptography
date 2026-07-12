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

## In Progress

- M0.1 source, standards, and provenance audit.
- FIPS 203 algorithm tracking for ML-KEM-768.
- Source classification for local standards, Kyber Round-3 material, and the Kyber 2020 C/KAT package.
- SHA-256 manifest for local standards.
- M0.1 audit report.

## Blocked By

- None

## Latest Failing Test

None

## Next Target

Complete M0.1, then continue to M0.2 FIPS 203 algorithm tracking.

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
