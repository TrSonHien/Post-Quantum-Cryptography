# Full RTL-to-GDSII Hardware Implementation of ML-KEM-768 / Kyber-768

This repository is a long-term learning and research project for building a hardware-oriented ML-KEM-768 accelerator from reference study through RTL, verification, synthesis handoff, physical-design execution on a server, timing analysis, and final reporting.

The project is currently in the foundation phase. Existing Verilog files are structural simulation scaffolding only; they are not a verified ML-KEM implementation and are not claimed to be ASIC-ready.

## Current Milestone

M1: Project Foundation

Current focus:

- Organize mandatory documents and notes.
- Prepare reference model and KAT workspaces.
- Define RTL, testbench, simulation, synthesis, and PD handoff locations.
- Keep roadmap and milestone status easy to resume.

## Repository Structure

```text
.
├── docs/                 # Project specs, standards notes, math notes, architecture, verification, report
├── references/           # Standards, papers, datasheets, and external links
├── ref_model/            # C/Python reference models, KAT vectors, and comparison scripts
├── rtl/                  # Synthesizable RTL organized by ML-KEM function block
├── tb/                   # Unit, block, and system testbenches
├── sim/                  # Simulation scripts, logs, waves, and outputs
├── synth/genus/          # Cadence Genus scripts, constraints, reports, and outputs
├── pd/                   # Empty placeholder for future server-controlled PD structure
├── reports/              # Curated simulation, synthesis, PNR, timing, and power reports
├── figures/              # Architecture diagrams, waveforms, layout images, and charts
├── scripts/              # Utility scripts that are not tool-flow-specific
└── archive/              # Preserved ambiguous or retired project material
```

## How To Navigate

- Start every session with `TODO.md`, `docs/00_project_spec/milestone_status.md`, and `Roadmap.md`.
- Use `docs/00_project_spec/` for project definition, roadmap mapping, and milestone status.
- Use `references/standards/` for local standards PDFs and `references/papers/` for papers.
- Use `docs/01_standard/` for reading notes on FIPS 203, Kyber Round 3, FIPS 202, and Keccak-related standards.
- Use `docs/02_math/` for ML-KEM math notes: Module-LWE, polynomial rings, NTT, and modular arithmetic.
- Use `docs/03_architecture/` for top-level, NTT, Keccak, memory, and PPA architecture planning.
- Use `docs/04_verification/` for verification strategy, test vectors, and regression planning.
- Use `docs/06_report/` for paper/report outlines and survey tables.

## Where To Work By Phase

- Phase 0: `docs/00_project_spec/`, `references/`, `TODO.md`
- Phase 1: `ref_model/c_ref/`, `ref_model/python_model/`, `ref_model/kat/`, `ref_model/compare/`, `docs/04_verification/`
- Phase 2: `rtl/arithmetic/`, `tb/unit/`, `sim/scripts/`, `sim/logs/`, `docs/02_math/`
- Phase 3: `rtl/ntt/`, `rtl/arithmetic/`, `tb/unit/`, `tb/block/`, `docs/02_math/`, `docs/03_architecture/`
- Phase 4: `rtl/memory/`, `docs/03_architecture/memory_architecture.md`, `tb/block/`
- Phase 5: `rtl/keccak/`, `tb/unit/`, `tb/block/`, `docs/01_standard/fips202_keccak_notes.md`, `docs/03_architecture/keccak_architecture.md`
- Phase 6: `rtl/sampler/`, `rtl/codec/`, `tb/unit/`, `tb/block/`, `docs/04_verification/`
- Phase 7: `rtl/control/`, `rtl/top/`, `tb/system/`, `ref_model/kat/`, `sim/scripts/`
- Phase 8: `rtl/control/`, `rtl/top/`, `tb/system/`, `ref_model/kat/`, `sim/scripts/`
- Phase 9: `rtl/control/`, `rtl/top/`, `tb/system/`, `ref_model/kat/`, `sim/scripts/`
- Phase 10: `rtl/top/`, `rtl/control/`, `tb/system/`, `sim/scripts/`
- Phase 11: `docs/03_architecture/ppa_plan.md`, `synth/genus/`, `reports/synthesis/`
- Phase 12: `synth/genus/scripts/`, `synth/genus/constraints/`, `synth/genus/reports/`, `synth/genus/outputs/`
- Phase 13: `pd/` for server-controlled physical design structure.
- Phase 14: `pd/`, `reports/timing/`, `reports/power/`, `figures/layout/`
- Phase 15: `docs/06_report/`, `reports/`, `figures/`

## Placement Rules

- Place documents and reading notes in `docs/`.
- Place official PDFs, papers, datasheets, and external source links in `references/`.
- Place C/Python golden model work and KAT material in `ref_model/`.
- Place synthesizable RTL in `rtl/`, grouped by function block.
- Place testbenches in `tb/unit/`, `tb/block/`, or `tb/system/`.
- Place simulation scripts in `sim/scripts/`; generated logs, waves, and outputs stay under `sim/`.
- Place Genus synthesis material under `synth/genus/`.
- Place physical-design material under `pd/` when the server-side structure is defined.
- Place curated result summaries under `reports/`.
- Place diagrams, waveforms, layout images, and charts under `figures/`.

## Roadmap Reference

The main two-year roadmap is `Roadmap.md`. The current milestone tracker is `docs/00_project_spec/milestone_status.md`.
