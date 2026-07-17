# ML-KEM-768 / Kyber-768 RTL and Verification Workspace

This repository is currently focused on the algorithm and verification foundation for a high-frequency ASIC-oriented ML-KEM-768 / Kyber-768 hardware implementation.

The implementation direction is correctness first, then timing closure / high operating frequency / Fmax, then throughput, then area. Area is still tracked, but the main datapath should prefer pipelined high-frequency RTL over area-saving resource sharing.

Current workflow:

```text
standard reading -> reference model -> test vectors -> arithmetic RTL -> unit verification
```

The RTL is being built and verified incrementally. Passing unit/block tests are local confidence points, not a full ML-KEM cryptographic correctness claim until trusted KAT or golden-reference comparison is in place.

## Current Milestone

M9 academic RTL release: functional verification and complete hierarchy
elaboration are complete.  Technology-mapped synthesis remains
environment-blocked locally because Yosys, Genus, and a standard-cell Liberty
library are unavailable.

## Current Scope

Active work includes:

- ML-KEM/Kyber standards, papers, and reading notes
- C/Python reference model workspace
- Known Answer Test vector workspace
- Verilog RTL workspace
- Unit, block, and system testbench workspace
- Simulation scripts, logs, waveforms, outputs, and comparison workspace
- Architecture and verification documentation

Current verified milestones include:

- arithmetic foundation
- NTT core
- INTT core
- NTT -> INTT round-trip
- basemul foundation
- M8 internal/public ML-KEM KeyGen, Encaps, Decaps, implicit rejection, and
  reduced Python differential/end-to-end verification
- M9 complete `mlkem768_top` elaboration with Verilator and Icarus

The academic baseline provides selected M8-local secret clearing and control
invalidation, not exhaustive lower-datapath physical zeroization or complete
side-channel hardening.  It has no final authoritative NIST CAVP/ACVP closure.
No post-layout timing, power, ASIC area, or achieved-Fmax claim is made.

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

Run the prepared M2.3b and full-top synthesis scripts on a server with Yosys
or Genus plus an intended technology library, then import authoritative NIST
CAVP/ACVP vectors in a later verification milestone.  The optional full-project
regression remains a manual overnight task.
