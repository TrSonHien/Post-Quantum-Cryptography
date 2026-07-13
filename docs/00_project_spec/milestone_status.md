# Milestone Status

## Current Milestone

M5 complete; M6 codec and sampler architecture is next (not started)

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
- M2.2.1 pipelined modular addition and subtraction (mod_add_pipe, mod_sub_pipe).
- M2.2.2 pipelined Montgomery reduction (montgomery_reduce_pipe).
- M2.2.3 pipelined modular multiplier (mod_mul_pipe).
- M2.2.4 pipelined Barrett reduction (barrett_reduce_pipe).
- M2.2.5 pipelined forward butterfly (butterfly_pipe).
- M2.2.6 pipelined inverse butterfly (intt_butterfly_pipe).
- M2.2.7 unified arithmetic-pipeline regression & M2.3 handoff.
- M2.3a pipelined arithmetic synthesis infrastructure preparation (reproducible scripts, wrappers, and constraints completed).
- M3.0 Fmax-oriented NTT/INTT audit and implementation plan (completed).
- M3.1 Fmax-oriented forward NTT scheduler (completed).
- M3.2 banked pipelined forward NTT core candidate v0 (completed).
- M3.3 banked pipelined inverse NTT scheduler and seven-stage core (completed).
- M3.4 two-lane final inverse scaling pass (completed).
- M3.5 independent NTT/INTT differential and roundtrip verification (completed).
- M3.6 unified NTT/INTT regression, architecture closure, interface freeze,
  and M4 handoff (completed).
- M4.0 polynomial/polyvec architecture audit, domain contract, workspace
  ownership, and external interface freeze (completed).
- M4.1 synchronous polynomial workspace and two-lane canonical add, subtract,
  and 32-bit reduction controllers (completed).
- M4.2 polynomial forward/inverse NTT adapters, independent differential, and
  adapter roundtrip verification (completed).
- M4.3 exact ordinary modular multiplication, BaseCaseMultiply, and polynomial
  MultiplyNTTs with frozen Montgomery-factor proof (completed).
- M4.4 K=3 polyvec workspace and serialized add/sub/reduce/NTT/INTT controllers
  with independent vector roundtrip (completed).
- M4.5 exact K=3 polyvec MultiplyNTTs accumulation and M7 row handoff
  (completed).
- M4.6 unified 33-program regression, architecture freeze, and M5 handoff
  (completed).
- M5.0-M5.6 Keccak-f[1600], sponge, SHA3, SHAKE, H/G/J/PRF/XOF, unified
  regression, architecture freeze, and M6 handoff (completed).

## In Progress

- M2.3b: Server ASIC synthesis comparison and candidate selection (pending server execution).

## Blocked By

- None

## Latest Failing Test

None

## Next Target

M6 codec/sampler architecture audit. M2.3b server ASIC synthesis and final
CAVP/ACVP ML-KEM verification remain pending. M6 functional RTL is not started.

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
