# ML-KEM-768 / Kyber-768 RTL and Verification Workspace

This repository is currently focused on the algorithm and verification foundation for a hardware-oriented ML-KEM-768 / Kyber-768 implementation.

Current workflow:

```text
standard reading -> reference model -> test vectors -> arithmetic RTL -> unit verification
```

Existing Verilog files are structural scaffolding only. They are not a verified ML-KEM implementation, and no RTL behavior was changed during the latest repository cleanup.

## Current Milestone

M1: Algorithm and Verification Foundation

## Current Scope

Active work includes:

- ML-KEM/Kyber standards, papers, and reading notes
- C/Python reference model workspace
- Known Answer Test vector workspace
- Verilog RTL workspace
- Unit, block, and system testbench workspace
- Simulation scripts, logs, waveforms, outputs, and comparison workspace
- Architecture and verification documentation

Explicitly excluded from the current phase:

- Genus
- Innovus
- PnR
- STA
- GDSII
- Physical Design

The `pd/` directory is intentionally left as a placeholder for later manual use.

## Active Repository Structure

```text
.
├── docs/                  # Project notes, math notes, architecture docs, verification plans
├── references/            # Original standards, PDFs, papers, datasheets, and external links
├── ref_model/             # C/Python reference model, KATs, and comparison scripts
├── rtl/                   # Verilog RTL source organized by function block
├── tb/                    # Unit, block, and system testbenches
├── sim/                   # Simulation scripts, logs, waveforms, and outputs
├── reports/simulation/    # Curated simulation reports
├── figures/               # Diagrams, waveforms, and charts
├── scripts/               # Utility scripts
├── archive/               # Preserved legacy or inactive material
└── pd/                    # Untouched placeholder for future physical design work
```

## Where Things Go

- Put original PDFs and standards in `references/`.
- Put project-written notes and plans in `docs/`.
- Put C reference code in `ref_model/c_ref/`.
- Put Python modeling code in `ref_model/python_model/`.
- Put KAT files in `ref_model/kat/`.
- Put golden-versus-RTL comparison scripts in `ref_model/compare/` or `sim/scripts/`.
- Put synthesizable RTL in `rtl/`.
- Put testbenches in `tb/unit/`, `tb/block/`, or `tb/system/`.
- Put simulation commands and filelists in `sim/scripts/`.
- Put generated simulation logs, waveforms, and outputs in `sim/logs/`, `sim/waves/`, and `sim/outputs/`.
- Put curated simulation summaries in `reports/simulation/`.

## Recommended Reading Order

1. `TODO.md`
2. `docs/00_project_spec/milestone_status.md`
3. `docs/01_standard/fips203_notes.md`
4. `docs/02_math/modular_arithmetic_notes.md`
5. `docs/04_verification/verification_plan.md`

## Current Next Target

Collect mandatory ML-KEM documents, fill the FIPS 203 notes, prepare the reference model workspace, and define the first arithmetic RTL unit verification flow.
