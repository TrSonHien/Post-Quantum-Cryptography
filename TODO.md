# TODO

## Current Milestone

M1: Algorithm and Verification Foundation

## Completed

- [x] Initial repository exists
- [x] Roadmap file exists
- [x] Repository structure reorganized for ML-KEM-768 RTL and verification work
- [x] Current active phase excludes Genus, Innovus, PnR, STA, GDSII, and Physical Design

## In Progress

- [ ] Collect mandatory ML-KEM documents
- [ ] Create reading notes for FIPS 203
- [ ] Prepare reference C/Python model workspace
- [ ] Prepare Known Answer Test vector workspace
- [ ] Prepare RTL output comparison workspace
- [ ] Prepare first arithmetic RTL unit verification plan
- [ ] Validate pipelined basemul as the main basemul architecture
- [ ] Update the poly-level plan to use pipelined basemul
- [ ] Later pipeline `mod_mul` / Montgomery reduction if synthesis shows it is the critical path

## Blocked By

- None

## Next Target

Collect mandatory documents, start reading FIPS 203, and define the first reference-model-to-RTL comparison path.

## Current Focus

```text
standard reading -> reference model -> test vectors -> arithmetic RTL -> unit verification
```

## Project Priority

```text
1. Correctness
2. Timing closure / high operating frequency / Fmax
3. Throughput
4. Area
```

Fmax/timing closure is the main implementation priority after correctness.
Area is tracked, but it is not the leading objective. Main datapaths should
prefer pipelined high-frequency architecture; area-saving sequential variants
are comparison/reference variants only.

## Explicitly Excluded From Current Phase

- Genus
- Innovus
- PnR
- STA
- GDSII
- Physical Design

## Archived Prior Notes

The original `thoughts.txt` was preserved as `archive/thoughts.txt`. It contains early PQC hardware notes, including broader ML-DSA ideas. Current repository scope is ML-KEM-768 unless the project direction changes explicitly.

## Session Log

### 2026-07-04 Repository Reorganization

Requested:

- Reorganize the repository into a professional research, RTL, simulation, synthesis, PNR, report, and archive structure for a two-year ML-KEM-768 RTL-to-GDSII project.

Files changed:

- Moved reference PDFs, Kyber reference package, math/architecture papers, RTL, testbench, simulation files, and old notes into the new structure.
- Created documentation scaffold, folder READMEs, `CHANGELOG.md`, `TODO.md`, `references/links.md`, and project status files.
- Updated `README.md`.
- Updated simulation filelists to point at the moved RTL and testbench paths.

Commands run:

- `pwd`
- `find . -maxdepth 3 -type f | sort`
- `find . -maxdepth 3 -type d | sort`
- `git status --short`
- `sed -n ...` on project docs, workflow, RTL, testbench, and simulation files
- `git branch --show-current`
- `git log --oneline -n 5`
- `mkdir -p ...`
- `mv ...`
- `rmdir ...`
- `apply_patch` for README, TODO, CHANGELOG, filelists, and documentation scaffold
- `find . -maxdepth 3 -type d | sort`
- `git status --short`

Verified:

- Existing Verilog files were moved without logic changes.
- Legacy empty directories were removed only after their useful contents were moved.
- Final directory tree and Git status were inspected.

Remains to do:

- Review mandatory standards and populate notes.
- Decide exact golden reference model source and KAT format.
- Review RTL before claiming synthesizability or cryptographic correctness.

### 2026-07-04 PD Placeholder Adjustment

Requested:

- Keep PD as an empty placeholder because physical design will run on the server and the folder structure will be controlled later.

Files changed:

- Removed the active generated PD documentation/PNR scaffold from the project structure.
- Created `pd/` as the active server-controlled PD placeholder.
- Updated README, project spec, roadmap, docs overview, PPA plan, CHANGELOG, and TODO references.

Commands run:

- `sed -n '1,260p' TODO.md`
- `find docs/05_physical_design pnr synth -maxdepth 4 -type f | sort`
- `find docs/05_physical_design pnr synth -maxdepth 4 -type d | sort`
- `git status --short`
- `mkdir -p pd`
- `rg -n ...`
- `apply_patch`
- `find . -maxdepth 3 -type d | sort`
- `find pd -maxdepth 2 -type f -o -type d | sort`
- `rg -n 'docs/05_physical_design|pnr/innovus|Place Innovus|physical design planning' README.md docs CHANGELOG.md`
- `git status --short`

Verified:

- Active PD workspace is now the empty `pd/` directory.
- Active README/docs no longer point to `docs/05_physical_design/` or `pnr/innovus/`.

Remains to do:

- Define the `pd/` structure later when the server-side flow is ready.

### 2026-07-04 Git Ignore And GitHub Push

Requested:

- Rewrite `.gitignore` and push the repository to GitHub.

Files changed:

- Rewrote `.gitignore` for simulator, reference-model, synthesis, PD, editor, cache, and temporary artifacts.
- Added `.gitkeep` placeholders so empty project workspaces appear on GitHub, including `pd/`.
- Preserved the old tracked root `thoughts.txt` content under `archive/thoughts.txt`.
- Updated roadmap filename references to the current `Roadmap.md`.
- Restored the `synth/genus/` placeholder documentation and subfolders.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,260p' TODO.md`
- `sed -n '1,260p' .gitignore`
- `git status --short`
- `git remote -v`
- `find . -maxdepth 3 -type f | sort`
- `ls -la`
- `git ls-files`
- `rg -n ...`
- `du -sh . references docs ref_model`
- `apply_patch`
- `git check-ignore -v sim/logs/test.log pd/runs/run1/foo.rpt references/standards/NIST.FIPS.203.pdf pd/.gitkeep sim/logs/.gitkeep`
- `find . -maxdepth 3 -type d | sort`
- `git add -A`
- `git diff --cached --stat`
- `git diff --cached --name-status`
- `git commit -m "chore: reorganize mlkem project structure"`
- `git push origin main`

Verified:

- Generated simulation logs and PD run outputs are ignored.
- `pd/.gitkeep` and other workspace placeholders are trackable.
- Reference PDFs are not ignored.
- Active docs reference `Roadmap.md`.

Remains to do:

- Continue Phase 0 document control.

### 2026-07-04 Current Phase Simplification

Requested:

- Simplify the active repository focus to ML-KEM/Kyber documents and notes, reference models, KATs, Verilog RTL, testbenches, simulation, architecture, and verification.
- Move all original PDF papers and standards into `references/`.
- Keep `docs/` for notes and plans written by us.
- Leave `pd/` untouched.
- Update README, TODO, and milestone status to `M1: Algorithm and Verification Foundation`.

Files changed:

- Moved PDFs from `docs/02_math/`, `docs/03_architecture/`, and the Kyber submission supporting documentation folder into `references/papers/`.
- Moved inactive `synth/` scaffold and non-simulation report placeholders into `archive/inactive_flow_scaffold_2026-07-04/`.
- Moved `docs/03_architecture/ppa_plan.md` into `archive/inactive_flow_scaffold_2026-07-04/`.
- Updated `README.md`, `TODO.md`, `docs/00_project_spec/milestone_status.md`, `docs/00_project_spec/project_spec.md`, `docs/00_project_spec/roadmap.md`, `reports/README.md`, `references/links.md`, `docs/03_architecture/README.md`, and `CHANGELOG.md`.

Commands run:

- `sed -n '1,260p' TODO.md`
- `find . -maxdepth 3 -type d | sort`
- `find . -maxdepth 4 -type f | sort`
- `git status --short`
- `rg -n ...`
- `mv ...`
- `mkdir -p archive/inactive_flow_scaffold_2026-07-04/reports`
- `mkdir -p references/papers/kyber_submission`
- `apply_patch`

Verified:

- `pd/` was not renamed or reorganized.
- Original PDFs were moved into `references/`.
- Active documentation states the current focus and explicitly excludes Genus, Innovus, PnR, STA, GDSII, and Physical Design.

Remains to do:

- Fill FIPS 203 notes.
- Choose the exact ML-KEM/Kyber-768 KAT baseline.
- Define the first arithmetic RTL unit test and comparison format.

### 2026-07-05 Markdown Orientation

Requested:

- Read `TODO.md` to understand the project.
- Read all Markdown files in the repository.

Files changed:

- Updated `TODO.md` with this handoff entry.

Commands run:

- `ls`
- `sed -n '1,240p' TODO.md`
- `rg --files -g '*.md'`
- `find . -name '*.md' -maxdepth 5 -type f | wc -l`
- `wc -l $(rg --files -g '*.md' | sort)`
- `awk ...` over short Markdown files
- `sed -n '1,260p' Roadmap.md`
- `sed -n '261,560p' Roadmap.md`
- `sed -n '561,860p' Roadmap.md`
- `sed -n '861,1160p' Roadmap.md`
- `sed -n '1161,1500p' Roadmap.md`
- `git status --short`
- `tail -n 80 TODO.md`
- `apply_patch`

Verified:

- Found 43 Markdown files.
- Read the active project documentation, folder README files, archived Markdown scaffolds, `CHANGELOG.md`, `TODO.md`, and the full `Roadmap.md`.
- Confirmed active project status remains `M1: Algorithm and Verification Foundation`.
- Confirmed active docs still exclude Genus, Innovus, PnR, STA, GDSII, and Physical Design from the current phase.

Remains to do:

- Fill `docs/01_standard/fips203_notes.md`.
- Select the exact trusted ML-KEM/Kyber-768 KAT baseline.
- Define the first arithmetic RTL unit test and reference comparison format.

### 2026-07-05 Kyber768 Parameter Header

Requested:

- Create the shared Verilog parameter header for Kyber768.
- Use `kyber768/params.h` and `kyber768/api.h` as references.
- Do not use `kyber768-90s` as the primary source.
- Do not create any arithmetic RTL module.

Files changed:

- Added `rtl/common/kyber_params.vh`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `pwd`
- `sed -n '1,280p' TODO.md`
- `rg --files | rg '(^|/)kyber768/(params|api)\\.h$|(^|/)kyber768-90s/(params|api)\\.h$'`
- `sed -n '1,220p' ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/Reference_Implementation/crypto_kem/kyber768/params.h`
- `sed -n '1,220p' ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/Reference_Implementation/crypto_kem/kyber768/api.h`
- `find rtl -maxdepth 2 -type d | sort`
- `git status --short -- rtl TODO.md`
- `ls -la rtl/common`
- `test -e rtl/common/kyber_params.vh && sed -n '1,220p' rtl/common/kyber_params.vh || true`
- `apply_patch`
- `sed -n '1,220p' rtl/common/kyber_params.vh`
- `git diff -- rtl/common/kyber_params.vh`
- `git status --short -- rtl/common/kyber_params.vh TODO.md`
- `rg -n '^\\s*module\\b|KYBER_PARAMS_VH|KYBER_DU|KYBER_CIPHERTEXTBYTES' rtl/common/kyber_params.vh`

Verified:

- `rtl/common/kyber_params.vh` exists.
- Header uses Verilog include guards.
- Header contains macro-style constants only.
- Header does not declare a Verilog module.
- Primary reference files were the non-90s `kyber768/params.h` and `kyber768/api.h`.

Remains to do:

- Review parameter naming against FIPS 203 terminology if the project switches from Kyber Round 3 names to ML-KEM-only names.
- Use this header from future arithmetic/unit-test RTL only after a concrete module test plan exists.

### 2026-07-05 Modular Addition RTL

Requested:

- Implement the first arithmetic RTL block: modular addition modulo `KYBER_Q = 3329`.
- Create `rtl/arithmetic/mod_add.v`.
- Create `tb/unit/tb_mod_add.v`.
- Create `sim/scripts/run_mod_add.sh`.
- Create `reports/simulation/mod_add_report.md`.
- Do not implement Montgomery reduction, Barrett reduction, modular subtraction, or modular multiplication.

Files changed:

- Added `rtl/arithmetic/mod_add.v`.
- Added `tb/unit/tb_mod_add.v`.
- Added `sim/scripts/run_mod_add.sh`.
- Added `reports/simulation/mod_add_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,360p' TODO.md`
- `sed -n '1,160p' rtl/common/kyber_params.vh`
- `sed -n '1,220p' ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/Reference_Implementation/crypto_kem/kyber768/reduce.c`
- `find rtl/arithmetic tb/unit sim/scripts reports/simulation -maxdepth 2 -type f | sort`
- `sed -n '1,200p' sim/scripts/Makefile`
- `sed -n '1,160p' sim/scripts/rtl.f`
- `sed -n '1,160p' sim/scripts/tb.f`
- `sed -n '1,160p' sim/scripts/compile.f`
- `find tb -maxdepth 3 -type f | sort`
- `command -v iverilog`
- `command -v vvp`
- `git status --short -- rtl/arithmetic tb/unit sim/scripts reports/simulation sim/logs sim/outputs TODO.md`
- `apply_patch`
- `chmod +x sim/scripts/run_mod_add.sh`
- `sed -n '1,220p' rtl/arithmetic/mod_add.v`
- `sed -n '1,260p' tb/unit/tb_mod_add.v`
- `sed -n '1,180p' sim/scripts/run_mod_add.sh`
- `./sim/scripts/run_mod_add.sh`
- `git status --short -- rtl/arithmetic/mod_add.v tb/unit/tb_mod_add.v sim/scripts/run_mod_add.sh reports/simulation/mod_add_report.md TODO.md sim/logs sim/outputs`
- `sed -n '1,220p' reports/simulation/mod_add_report.md`
- `tail -n 80 sim/logs/mod_add.log`

Verified:

- `mod_add` includes `rtl/common/kyber_params.vh` and uses `KYBER_Q`, `KYBER_Q_WIDTH`, and `KYBER_SUM_WIDTH`.
- Internal sum is 13 bits, covering the maximum `3328 + 3328 = 6656`.
- RTL uses one clear conditional subtract of `KYBER_Q`; it does not copy the signed C trick from `csubq`.
- No Montgomery reduction, Barrett reduction, modular subtraction, or modular multiplication RTL was added.
- Self-checking testbench covers directed corner cases plus 1000 random in-range operand pairs.
- `./sim/scripts/run_mod_add.sh` completed with `PASS tb_mod_add`, `pass_count=1009`, and `fail_count=0`.

Remains to do:

- Decide the next arithmetic unit only after writing its unit test plan.
- Consider adding this unit to a broader regression target once more arithmetic blocks exist.

### 2026-07-05 Questa Include Directory Fix

Requested:

- Fix the `make build` failure from `sim/scripts` where Questa could not find `kyber_params.vh`.

Files changed:

- Updated `sim/scripts/compile.f`.
- Updated `reports/simulation/mod_add_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,380p' TODO.md`
- `sed -n '1,160p' sim/scripts/compile.f`
- `sed -n '1,160p' sim/scripts/rtl.f`
- `sed -n '1,160p' sim/scripts/tb.f`
- `sed -n '1,140p' tb/unit/tb_mod_add.v`
- `apply_patch`
- `make build`
- `make run TB_NAME=tb_mod_add TESTNAME=mod_add`
- `vsim -c -l mod_add.log tb_mod_add -do "run -all; quit -f"`
- `tail -n 40 sim/scripts/compile.log`
- `git diff -- sim/scripts/compile.f`
- `git status --short -- sim/scripts/compile.f TODO.md reports/simulation/mod_add_report.md`

Verified:

- `sim/scripts/compile.f` now adds `+incdir+../../rtl/common`.
- `make build` from `sim/scripts` compiles `mod_add` and `tb_mod_add`.
- Questa compile result is `Errors: 0, Warnings: 0`.
- The prior standalone simulation result remains `PASS tb_mod_add`.

Remains to do:

- `make run` still does not execute in this local environment because `vsim` exits at startup with `Error: couldn't open socket: not owner` and `Trouble making server.` This is separate from the fixed include-path compile error.

### 2026-07-05 Questa Make Run Top Fix

Requested:

- Explain and fix why plain `make run` from `sim/scripts` failed with `Could not find work.test_bench`.

Files changed:

- Updated `sim/scripts/Makefile`.
- Updated `reports/simulation/mod_add_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,80p' sim/scripts/Makefile`
- `sed -n '1,420p' TODO.md`
- `tail -n 80 sim/scripts/compile.log`
- `apply_patch`
- `make run`

Verified:

- Root cause was the Makefile default `TB_NAME ?= test_bench` while `make build` compiled top module `tb_mod_add`.
- Makefile default now uses `TESTNAME ?= mod_add` and `TB_NAME ?= tb_mod_add`.
- The generated `make run` command now targets `tb_mod_add`: `vsim ... -c tb_mod_add ...`.

Remains to do:

- In this local shell, `vsim` still exits before simulation startup with `Error: couldn't open socket: not owner` and `Trouble making server.` The user's transcript shows their `vsim` starts and reaches design optimization, so the Makefile top-name fix should address the reported `work.test_bench` error in that environment.

### 2026-07-05 Modular Subtraction Testbench

Requested:

- User wrote `rtl/arithmetic/mod_sub.v`.
- Add a testbench and test it.
- Do not edit `mod_sub.v`; report any RTL errors for the user to fix.

Files changed:

- Added `tb/unit/tb_mod_sub.v`.
- Added `sim/scripts/run_mod_sub.sh`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,460p' TODO.md`
- `sed -n '1,220p' rtl/arithmetic/mod_sub.v`
- `sed -n '1,220p' tb/unit/tb_mod_add.v`
- `sed -n '1,80p' sim/scripts/Makefile`
- `sed -n '1,80p' sim/scripts/rtl.f`
- `sed -n '1,80p' sim/scripts/tb.f`
- `sed -n '1,80p' sim/scripts/compile.f`
- `apply_patch`
- `chmod +x sim/scripts/run_mod_sub.sh`
- `sed -n '1,180p' tb/unit/tb_mod_sub.v`
- `sed -n '1,120p' sim/scripts/run_mod_sub.sh`
- `./sim/scripts/run_mod_sub.sh`
- `nl -ba rtl/arithmetic/mod_sub.v`
- `tail -n 80 sim/logs/mod_sub.log`
- `git status --short -- rtl/arithmetic/mod_sub.v tb/unit/tb_mod_sub.v sim/scripts/run_mod_sub.sh TODO.md`

Verified:

- The new `tb_mod_sub` is self-checking.
- It covers directed no-wrap and wraparound subtraction cases plus 1000 random in-range operand pairs.
- Simulation could not run because `mod_sub.v` did not compile.
- `mod_sub.v` was not edited.

Remains to do:

- User should fix `mod_sub.v` line 10 and line 11 by terminating the wire declarations.
- User should review line 7 because `c` is declared as an input while line 16 assigns to `c`.
- After those RTL fixes, rerun `./sim/scripts/run_mod_sub.sh`.

### 2026-07-05 Reduction And Modular Multiplication Tests

Requested:

- User wrote `rtl/arithmetic/reduction.v` and `rtl/arithmetic/mod_mul.v`.
- Add tests and run them.
- Report errors; do not edit the user's RTL.

Files changed:

- Added `tb/unit/tb_reduction.v`.
- Added `tb/unit/tb_mod_mul.v`.
- Added `sim/scripts/run_reduction.sh`.
- Added `sim/scripts/run_mod_mul.sh`.
- Added `reports/simulation/reduction_mod_mul_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,560p' TODO.md`
- `sed -n '1,240p' rtl/arithmetic/reduction.v`
- `sed -n '1,240p' rtl/arithmetic/mod_mul.v`
- `find rtl/arithmetic tb/unit sim/scripts reports/simulation -maxdepth 2 -type f | sort`
- `apply_patch`
- `chmod +x sim/scripts/run_reduction.sh sim/scripts/run_mod_mul.sh`
- `sed -n '1,220p' tb/unit/tb_reduction.v`
- `sed -n '1,220p' tb/unit/tb_mod_mul.v`
- `./sim/scripts/run_reduction.sh`
- `./sim/scripts/run_mod_mul.sh`
- `nl -ba rtl/arithmetic/mod_mul.v`
- `nl -ba rtl/arithmetic/reduction.v`
- `tail -n 80 sim/logs/reduction.log`
- `tail -n 80 sim/logs/mod_mul.log`

Verified:

- `tb_reduction` is self-checking and tests `montgomery_reduce`, `barrett_reduce`, and `conditional_sub_q`.
- `./sim/scripts/run_reduction.sh` completed with `PASS tb_reduction`, `pass_count=620`, and `fail_count=0`.
- `tb_mod_mul` is self-checking and compares `mod_mul` against a Montgomery-reduction reference model.
- `./sim/scripts/run_mod_mul.sh` could not simulate because `mod_mul.v` did not compile.
- `reduction.v` and `mod_mul.v` were not edited.

Remains to do:

- User should fix `rtl/arithmetic/mod_mul.v` line 9 by removing the trailing comma after output port `c`.
- After that fix, rerun `./sim/scripts/run_mod_mul.sh`.

### 2026-07-05 Arithmetic And NTT Smoke Tests

Requested:

- User modified `mod_sub.v`, `mod_mul.v`, and added code to `zetas_rom.v` and `butterfly_unit.v`.
- Test everything and report errors.

Files changed:

- Updated `tb/unit/tb_mod_mul.v` to match the current canonical unsigned `mod_mul` interface.
- Added `tb/unit/tb_zetas_rom.v`.
- Added `tb/unit/tb_butterfly_unit.v`.
- Added `sim/scripts/run_zetas_rom.sh`.
- Added `sim/scripts/run_butterfly_unit.sh`.
- Added `reports/simulation/arithmetic_ntt_smoke_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,680p' TODO.md`
- `sed -n '1,220p' rtl/arithmetic/mod_sub.v`
- `sed -n '1,220p' rtl/arithmetic/mod_mul.v`
- `sed -n '1,260p' rtl/arithmetic/reduction.v`
- `sed -n '1,260p' rtl/ntt/zetas_rom.v`
- `sed -n '261,560p' rtl/ntt/zetas_rom.v`
- `sed -n '1,280p' rtl/ntt/butterfly_unit.v`
- `sed -n '42,70p' ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/Reference_Implementation/crypto_kem/kyber768/ntt.c`
- `sed -n '90,115p' ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/Reference_Implementation/crypto_kem/kyber768/ntt.c`
- `rg -n "module zetas|module butterfly|zetas_rom|butterfly_unit" -S .`
- `rg -n "zetas|KYBER_ROOT|17|2285|2571|2970" ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/Reference_Implementation/crypto_kem/kyber768 -S`
- `apply_patch`
- `./sim/scripts/run_mod_add.sh`
- `./sim/scripts/run_mod_sub.sh`
- `./sim/scripts/run_reduction.sh`
- `./sim/scripts/run_mod_mul.sh`
- `chmod +x sim/scripts/run_zetas_rom.sh sim/scripts/run_butterfly_unit.sh`
- `./sim/scripts/run_zetas_rom.sh`
- `./sim/scripts/run_butterfly_unit.sh`
- `nl -ba rtl/ntt/butterfly_unit.v`
- `tail -n 40 sim/logs/mod_add.log`
- `tail -n 40 sim/logs/mod_sub.log`
- `tail -n 40 sim/logs/reduction.log`
- `tail -n 40 sim/logs/mod_mul.log`
- `tail -n 40 sim/logs/zetas_rom.log`
- `tail -n 80 sim/logs/butterfly_unit.log`
- `git status --short -- rtl/arithmetic/mod_sub.v rtl/arithmetic/mod_mul.v rtl/ntt/zetas_rom.v rtl/ntt/butterfly_unit.v tb/unit sim/scripts reports/simulation TODO.md`

Verified:

- `./sim/scripts/run_mod_add.sh`: `PASS tb_mod_add`, `pass_count=1009`, `fail_count=0`.
- `./sim/scripts/run_mod_sub.sh`: `PASS tb_mod_sub`, `pass_count=1012`, `fail_count=0`.
- `./sim/scripts/run_reduction.sh`: `PASS tb_reduction`, `pass_count=620`, `fail_count=0`.
- `./sim/scripts/run_mod_mul.sh`: `PASS tb_mod_mul`, `pass_count=1010`, `fail_count=0`.
- `./sim/scripts/run_zetas_rom.sh`: `PASS tb_zetas_rom`, `pass_count=16`, `fail_count=0`.
- `./sim/scripts/run_butterfly_unit.sh` could not elaborate `butterfly_unit.v`.

Remains to do:

- User should fix `rtl/ntt/butterfly_unit.v` line 40: `wire [KYBER_Q_WIDTH:0] t;` is missing the macro backtick before `KYBER_Q_WIDTH`.
- After that fix, rerun `./sim/scripts/run_butterfly_unit.sh`.
- Review width consistency after elaboration: `butterfly_unit` uses `[`KYBER_Q_WIDTH:0]`, while `mod_add` and `mod_sub` use `[`KYBER_Q_WIDTH-1:0]`; current tool warnings show pruning/padding at those ports.

### 2026-07-06 NTT Address Generator Testbench

Requested:

- Create a self-checking Verilog testbench for `rtl/ntt/ntt_addr_gen.v`.
- Create `tb/unit/tb_ntt_addr_gen.v`.
- Create `sim/scripts/run_ntt_addr_gen.sh`.
- Create `reports/simulation/ntt_addr_gen_report.md`.
- Do not modify `rtl/ntt/ntt_addr_gen.v`, any RTL source file, `kyber_params.vh`, or arithmetic modules.

Files changed:

- Added `tb/unit/tb_ntt_addr_gen.v`.
- Added `sim/scripts/run_ntt_addr_gen.sh`.
- Added `reports/simulation/ntt_addr_gen_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,760p' TODO.md`
- `sed -n '1,260p' rtl/ntt/ntt_addr_gen.v`
- `find tb/unit sim/scripts reports/simulation -maxdepth 1 -type f | sort`
- `git status --short -- rtl/ntt/ntt_addr_gen.v tb/unit/tb_ntt_addr_gen.v sim/scripts/run_ntt_addr_gen.sh reports/simulation/ntt_addr_gen_report.md TODO.md`
- `apply_patch`
- `chmod +x sim/scripts/run_ntt_addr_gen.sh`
- `sed -n '1,320p' tb/unit/tb_ntt_addr_gen.v`
- `sed -n '1,120p' sim/scripts/run_ntt_addr_gen.sh`
- `./sim/scripts/run_ntt_addr_gen.sh`
- `nl -ba rtl/ntt/ntt_addr_gen.v | sed -n '34,120p'`
- `nl -ba rtl/ntt/ntt_addr_gen.v | sed -n '120,190p'`
- `sed -n '1,120p' sim/logs/ntt_addr_gen_sim.log`
- `git status --short -- rtl/ntt/ntt_addr_gen.v tb/unit/tb_ntt_addr_gen.v sim/scripts/run_ntt_addr_gen.sh reports/simulation/ntt_addr_gen_report.md TODO.md sim/logs/ntt_addr_gen_sim.log sim/outputs/tb_ntt_addr_gen.out sim/waves/ntt_addr_gen.vcd`

Verified:

- The new testbench builds a behavioral reference model of the forward and inverse nested loops from `kyber768/ntt.c`.
- The testbench checks every valid cycle for `len_out`, `addr_a`, `addr_b`, and `zeta_addr`.
- The testbench checks total valid cycles, one-cycle `done`, `valid` low after done, and `busy` low after done.
- The run script creates `sim/outputs`, `sim/logs`, and `sim/waves`, compiles with `iverilog -g2012`, uses include path `rtl/common`, and writes logs/waves to the requested paths.
- RTL simulation could not run because `rtl/ntt/ntt_addr_gen.v` failed to compile at line 42.
- No RTL source file, `kyber_params.vh`, or arithmetic module was modified.

Remains to do:

- User should fix `rtl/ntt/ntt_addr_gen.v` line 42: `paremeter ZETA_WIDTH = 7`.
- After that, review visible RTL issues at line 73 (`next-start` vs `next_start`), line 92 (`alway`), and lines 130-131 (`start_stage`/`j_stage` vs declared `start_reg`/`j_reg`).
- Rerun `./sim/scripts/run_ntt_addr_gen.sh` after RTL fixes.

### 2026-07-06 NTT Address Generator Rerun

Requested:

- Rerun the `ntt_addr_gen` test.

Files changed:

- Updated `reports/simulation/ntt_addr_gen_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `tail -n 140 TODO.md`
- `sed -n '1,220p' rtl/ntt/ntt_addr_gen.v`
- `sed -n '1,80p' sim/scripts/run_ntt_addr_gen.sh`
- `./sim/scripts/run_ntt_addr_gen.sh`

Verified:

- Test remains blocked at RTL compile.
- Current first compiler error is still `rtl/ntt/ntt_addr_gen.v:42: syntax error`.
- `rtl/ntt/ntt_addr_gen.v` was not modified.

Remains to do:

- User should fix `rtl/ntt/ntt_addr_gen.v` line 42: `paremeter ZETA_WIDTH = 7`.
- After that, review lines 130-131 because `start_stage` and `j_stage` are assigned but the declared registers are `start_reg` and `j_reg`.
- Rerun `./sim/scripts/run_ntt_addr_gen.sh`.

### 2026-07-06 NTT Address Generator Rerun 2

Requested:

- Rerun the `ntt_addr_gen` test again.

Files changed:

- Updated `reports/simulation/ntt_addr_gen_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '34,150p' rtl/ntt/ntt_addr_gen.v`
- `./sim/scripts/run_ntt_addr_gen.sh`

Verified:

- Test remains blocked at RTL compile.
- Current first compiler error is still `rtl/ntt/ntt_addr_gen.v:42: syntax error`.
- `rtl/ntt/ntt_addr_gen.v` was not modified.

Remains to do:

- User should fix `rtl/ntt/ntt_addr_gen.v` line 42: `paremeter ZETA_WIDTH = 7`.
- Rerun `./sim/scripts/run_ntt_addr_gen.sh`.

### 2026-07-06 NTT Address Generator Failure Diagnosis

Requested:

- Inspect why the user's `ntt_addr_gen` test fails after RTL syntax fixes.

Files changed:

- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,220p' TODO.md`
- `nl -ba rtl/ntt/ntt_addr_gen.v | sed -n '1,220p'`
- `sed -n '1,220p' sim/logs/ntt_addr_gen_sim.log`
- `sed -n '1,260p' tb/unit/tb_ntt_addr_gen.v`
- `tail -n 80 sim/logs/ntt_addr_gen_sim.log`
- `grep -n "PASS\\|FAIL\\|INFO tb_ntt_addr_gen: pass_count" sim/logs/ntt_addr_gen_sim.log | tail -n 20`
- `grep -n "mode=1 cycle=0\\|mode=0 cycle=0\\|expected done" sim/logs/ntt_addr_gen_sim.log | head -n 20`

Verified:

- `ntt_addr_gen.v` now compiles far enough for the testbench to run.
- The failure pattern is a one-cycle sampling shift: testbench cycle 0 expects `addr_a=0`, but actual output is already `addr_a=1`.
- The final schedule is similarly shifted: the testbench expects the last valid entry while the DUT is already at `done`.
- Likely root cause is the testbench checking at the first posedge after `pulse_start` returns, which misses the first valid schedule produced immediately after the start-capturing posedge.

Remains to do:

- Adjust `tb/unit/tb_ntt_addr_gen.v` sampling phase, for example sample the first valid output immediately after the start-capturing posedge or sample stable outputs on the following negedge instead of waiting one extra posedge.
- Rerun `./sim/scripts/run_ntt_addr_gen.sh` after testbench timing is corrected.

### 2026-07-06 NTT Address Generator Testbench Timing Fix

Requested:

- Fix only the testbench timing alignment for `ntt_addr_gen`.
- Do not modify RTL, `kyber_params.vh`, or arithmetic modules.

Files changed:

- Updated `tb/unit/tb_ntt_addr_gen.v`.
- Updated `reports/simulation/ntt_addr_gen_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `tail -n 120 TODO.md`
- `sed -n '1,300p' tb/unit/tb_ntt_addr_gen.v`
- `sed -n '1,180p' reports/simulation/ntt_addr_gen_report.md`
- `apply_patch`
- `./sim/scripts/run_ntt_addr_gen.sh`

Verified:

- Testbench now drives `start` and `mode` on a negedge.
- DUT captures `start` on the next posedge.
- Testbench samples cycle 0 on the following negedge without waiting an extra posedge.
- Remaining valid cycles are sampled once per negedge.
- `./sim/scripts/run_ntt_addr_gen.sh` completed with `PASS tb_ntt_addr_gen`.
- Forward mode valid cycles: 896.
- Inverse mode valid cycles: 896.
- Total checked valid cycles: 1792.
- `fail_count=0`.
- No RTL source file, `kyber_params.vh`, or arithmetic module was modified.

Remains to do:

- Use `./sim/scripts/run_ntt_addr_gen.sh` as the current unit regression for `ntt_addr_gen`.

### 2026-07-06 GitHub Checkpoint Push

Requested:

- Push the current checkpoint to GitHub.

Files changed:

- Updated `.gitignore` to ignore file-form `vsim.dbg` simulator artifacts.
- Updated `TODO.md` with this handoff entry.
- Checkpoint includes current documentation cleanup, reference collateral moves, arithmetic/NTT RTL, unit testbenches, simulation scripts, and curated simulation reports.

Commands run:

- `sed -n '1,120p' TODO.md`
- `git status --short`
- `git branch --show-current`
- `git remote -v`
- `sed -n '1,260p' .gitignore`
- `git diff --stat`
- `git diff --name-status`
- `file sim/scripts/vsim.dbg || true`
- `ls -la sim/scripts/vsim.dbg 2>/dev/null || true`
- `git check-ignore -v sim/scripts/vsim.dbg sim/scripts/transcript sim/logs/ntt_addr_gen_sim.log sim/waves/ntt_addr_gen.vcd sim/outputs/tb_ntt_addr_gen.out || true`
- `apply_patch`
- `./sim/scripts/run_mod_add.sh`
- `./sim/scripts/run_mod_sub.sh`
- `./sim/scripts/run_reduction.sh`
- `./sim/scripts/run_mod_mul.sh`
- `./sim/scripts/run_zetas_rom.sh`
- `./sim/scripts/run_ntt_addr_gen.sh`
- `git check-ignore -v sim/scripts/vsim.dbg sim/logs/ntt_addr_gen_sim.log sim/waves/ntt_addr_gen.vcd sim/outputs/tb_ntt_addr_gen.out`

Verified:

- `sim/scripts/vsim.dbg`, generated logs, generated waves, and generated simulation outputs are ignored.
- `run_mod_add.sh`: PASS.
- `run_mod_sub.sh`: PASS.
- `run_reduction.sh`: PASS.
- `run_mod_mul.sh`: PASS.
- `run_zetas_rom.sh`: PASS.
- `run_ntt_addr_gen.sh`: PASS.

Remains to do:

- Stage, commit, and push this checkpoint.

### 2026-07-06 NTT Core Testbench Bring-up

Requested:

- Test `rtl/ntt/ntt_core.v` and write a careful self-checking testbench.

Files changed:

- Added `tb/unit/tb_ntt_core.v`.
- Added `sim/scripts/run_ntt_core.sh`.
- Added `reports/simulation/ntt_core_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `pwd`
- `sed -n '1,220p' TODO.md`
- `rg --files`
- `sed -n '1,260p' rtl/ntt/ntt_core.v`
- `sed -n '1,220p' rtl/ntt/butterfly_unit.v`
- `sed -n '1,220p' rtl/ntt/intt_butterfly_unit.v`
- `sed -n '1,240p' rtl/ntt/ntt_addr_gen.v`
- `sed -n '1,260p' rtl/memory/poly_buffer.v`
- `sed -n '1,220p' rtl/arithmetic/mod_mul.v`
- `sed -n '1,220p' rtl/arithmetic/reduction.v`
- `sed -n '1,180p' rtl/common/kyber_params.vh`
- `sed -n '1,220p' sim/scripts/run_ntt_addr_gen.sh`
- `sed -n '1,360p' rtl/ntt/zetas_rom.v`
- `apply_patch`
- `chmod +x sim/scripts/run_ntt_core.sh`
- `git status --short`
- `./sim/scripts/run_ntt_core.sh`
- `nl -ba rtl/ntt/ntt_core.v | sed -n '60,150p'`
- `sed -n '1,160p' sim/logs/ntt_core_sim.log`

Verified:

- The new testbench is designed to load two full 256-coefficient input patterns,
  run the forward NTT core, wait for `done`, read back all coefficients, and
  compare every output against a behavioral Kyber forward NTT model.
- The run script creates `sim/outputs`, `sim/logs`, and `sim/waves`, compiles
  all required DUT dependencies with `iverilog -g2012`, runs `vvp`, tees the log,
  and returns nonzero unless `PASS tb_ntt_core` is printed.
- Current `ntt_core.v` does not compile, so polynomial-level simulation did not
  run.
- First blocking compile error: `rtl/ntt/ntt_core.v:82` uses `.addr-b`, which is
  not a legal named port connection.
- Additional DUT issues reported by the compiler include `doen`,
  `buf_wr_data-a`, and `buf_wr_data-b`.
- No RTL file was modified during this testbench bring-up.

Remains to do:

- Fix `rtl/ntt/ntt_core.v` compile errors, then rerun
  `./sim/scripts/run_ntt_core.sh`.
- After compilation succeeds, review any polynomial mismatches from
  `tb_ntt_core` as either DUT scheduling/readback issues or reference-model
  issues.

### 2026-07-06 NTT Core Retest

Requested:

- Retest `rtl/ntt/ntt_core.v` after user-side DUT fixes.

Files changed:

- Updated `reports/simulation/ntt_core_report.md`.
- Updated `TODO.md` with this retest entry.

Commands run:

- `sed -n '1,220p' TODO.md`
- `git status --short`
- `nl -ba rtl/ntt/ntt_core.v | sed -n '70,150p'`
- `./sim/scripts/run_ntt_core.sh`
- `nl -ba rtl/ntt/ntt_core.v | sed -n '90,104p'`
- `rg -n "module zeta|module zetas|zeta_rom|zetas_rom" rtl/ntt tb/unit sim/scripts`
- `sed -n '1,120p' sim/logs/ntt_core_sim.log`
- `apply_patch`

Verified:

- The earlier syntax errors around `.addr_b`, `done`, `buf_wr_data_a`, and
  `buf_wr_data_b` are no longer the first blockers in the inspected DUT.
- `./sim/scripts/run_ntt_core.sh` still fails before simulation.
- Current first blocker is elaboration: `rtl/ntt/ntt_core.v:96` instantiates
  `zeta_rom`, but the available module is `zetas_rom` in
  `rtl/ntt/zetas_rom.v`.
- No RTL file was modified during this retest.

Remains to do:

- Fix the `ntt_core.v` ROM instance module name mismatch, then rerun
  `./sim/scripts/run_ntt_core.sh`.
- After elaboration succeeds, use `tb_ntt_core` to check the full polynomial
  output comparison.

### 2026-07-06 NTT Core Polynomial Retest

Requested:

- Retest `rtl/ntt/ntt_core.v` again after user-side ROM instance fix.

Files changed:

- Updated `reports/simulation/ntt_core_report.md`.
- Updated `TODO.md` with this retest entry.

Commands run:

- `sed -n '1,120p' TODO.md`
- `git status --short`
- `nl -ba rtl/ntt/ntt_core.v | sed -n '90,104p'`
- `./sim/scripts/run_ntt_core.sh`
- `apply_patch`

Verified:

- `ntt_core` now compiles, elaborates, and runs simulation.
- `tb_ntt_core` completed both deterministic 256-coefficient polynomial
  patterns.
- Result was `FAIL tb_ntt_core`.
- Final counts: `pass_count=0 fail_count=512`.
- First mismatch: pattern 0, index 0, expected 2429, actual 745.
- Compile warnings show likely DUT width issue: `ntt_core.v` passes an 8-bit
  `zeta` into `butterfly_unit`, while zeta/twiddle data should be coefficient
  width.
- No RTL file was modified during this retest.

Remains to do:

- Inspect and fix the `zeta` signal width in `rtl/ntt/ntt_core.v`; it is
  currently declared with `ADDR_WIDTH` instead of coefficient data width.
- After that, rerun `./sim/scripts/run_ntt_core.sh` and inspect any remaining
  mismatches.

### 2026-07-06 RTL Review And Documentation Notes

Requested:

- Carefully review the current Verilog files, point out potential errors and
  improvements, and add explanatory notes where the code is sound.

Files changed:

- Added explanatory algorithm/source notes to:
  - `rtl/arithmetic/mod_add.v`
  - `rtl/arithmetic/mod_sub.v`
  - `rtl/arithmetic/mod_mul.v`
  - `rtl/arithmetic/reduction.v`
  - `rtl/ntt/butterfly_unit.v`
  - `rtl/ntt/intt_butterfly_unit.v`
  - `rtl/ntt/ntt_addr_gen.v`
  - `rtl/ntt/ntt_core.v`
  - `rtl/ntt/zetas_rom.v`
  - `rtl/memory/poly_buffer.v`
- Cleaned testbench port-width declarations in:
  - `tb/unit/tb_mod_mul.v`
  - `tb/unit/tb_butterfly_unit.v`
  - `tb/unit/tb_zetas_rom.v`
- Updated `reports/simulation/ntt_core_report.md` to the current PASS result.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `pwd`
- `sed -n '1,220p' TODO.md`
- `rg --files -g '*.v' rtl tb`
- `rg -n "Post_Quantum_Cryptography|ML-KEM|Kyber|ntt_core|ntt_addr_gen|arithmetic RTL" /home/hien/.codex/memories/MEMORY.md`
- `git status --short`
- `nl -ba /home/hien/.codex/memories/MEMORY.md | sed -n '1,42p'`
- `sed -n ...` on RTL arithmetic, NTT, memory, testbench, and reference C files
- `./sim/scripts/run_mod_add.sh`
- `./sim/scripts/run_mod_sub.sh`
- `./sim/scripts/run_reduction.sh`
- `./sim/scripts/run_mod_mul.sh`
- `./sim/scripts/run_zetas_rom.sh`
- `./sim/scripts/run_butterfly_unit.sh`
- `./sim/scripts/run_ntt_addr_gen.sh`
- `./sim/scripts/run_ntt_core.sh`
- `iverilog -g2012 -Wall -I rtl/common -o /tmp/intt_butterfly_unit_check.out rtl/arithmetic/mod_add.v rtl/arithmetic/mod_sub.v rtl/arithmetic/reduction.v rtl/arithmetic/mod_mul.v rtl/ntt/intt_butterfly_unit.v`
- `rg -n "KYBER_Q_WIDTH:0|canoninal|Rederence|caculations" rtl tb`
- `git diff --check`
- `git diff --stat`
- `apply_patch`

Verified:

- `run_mod_add.sh`: PASS, `pass_count=1009 fail_count=0`.
- `run_mod_sub.sh`: PASS, `pass_count=1012 fail_count=0`.
- `run_reduction.sh`: PASS, `pass_count=620 fail_count=0`.
- `run_mod_mul.sh`: PASS, `pass_count=1010 fail_count=0`.
- `run_zetas_rom.sh`: PASS, `pass_count=16 fail_count=0`.
- `run_butterfly_unit.sh`: PASS, `pass_count=206 fail_count=0`.
- `run_ntt_addr_gen.sh`: PASS, `pass_count=1792 fail_count=0`.
- `run_ntt_core.sh`: PASS, `pass_count=512 fail_count=0`.
- `intt_butterfly_unit.v` compiles cleanly with its arithmetic dependencies.
- The old testbench width warnings for `mod_mul`, `butterfly_unit`, and
  `zetas_rom` were removed.
- Review notes added to the RTL explain the reference C source, datapath range,
  address schedule, memory timing, and current verification assumptions.

Review findings and improvement notes:

- `barrett_reduce` previously had a misleading 48-bit concatenate assigned into
  a 32-bit wire. It was behavior-equivalent for current callers but fragile, so
  it was replaced with a direct signed assignment and documented.
- `mod_sub` is functionally correct in the current tests, but it relies on
  fixed-width wraparound on underflow. The added comment explains that behavior;
  a future style cleanup could rewrite it with an explicit wider add/sub path.
- `ntt_core` still depends on the caller obeying the interface rule not to
  assert `load_en` in the same cycle as `start`. A future hardening change could
  gate `load_allowed` with `!start` as well.
- `intt_butterfly_unit.v` has no dedicated self-checking unit test yet. It
  compiles cleanly, but should not be treated as fully verified until a testbench
  is added.

Remains to do:

- Add a self-checking testbench and run script for `intt_butterfly_unit.v`.
- Consider converting `zetas_rom` constants from `16'sd...` literals to
  coefficient-width unsigned literals for stricter lint cleanliness.
- Consider hardening the `ntt_core` load/start interface.

### 2026-07-06 GitHub Push After RTL Review

Requested:

- Push the current RTL review/documentation checkpoint to GitHub.

Files changed:

- Updated `TODO.md` with this checkpoint entry.
- Checkpoint includes the reviewed RTL documentation notes, testbench width
  cleanup, `ntt_core` verification files, and the current `ntt_core` simulation
  report.

Commands run:

- `pwd`
- `sed -n '1,120p' TODO.md`
- `rg -n "Post_Quantum_Cryptography|M1: Algorithm|reports/simulation|pd/" /home/hien/.codex/memories/MEMORY.md`
- `git status --short`
- `./sim/scripts/run_mod_add.sh`
- `./sim/scripts/run_mod_sub.sh`
- `./sim/scripts/run_reduction.sh`
- `./sim/scripts/run_mod_mul.sh`
- `./sim/scripts/run_zetas_rom.sh`
- `./sim/scripts/run_butterfly_unit.sh`
- `./sim/scripts/run_ntt_addr_gen.sh`
- `./sim/scripts/run_ntt_core.sh`
- `git diff --check`
- `iverilog -g2012 -Wall -I rtl/common -o /tmp/intt_butterfly_unit_check.out rtl/arithmetic/mod_add.v rtl/arithmetic/mod_sub.v rtl/arithmetic/reduction.v rtl/arithmetic/mod_mul.v rtl/ntt/intt_butterfly_unit.v`
- `git remote -v`
- `apply_patch`

Verified:

- `run_mod_add.sh`: PASS, `pass_count=1009 fail_count=0`.
- `run_mod_sub.sh`: PASS, `pass_count=1012 fail_count=0`.
- `run_reduction.sh`: PASS, `pass_count=620 fail_count=0`.
- `run_mod_mul.sh`: PASS, `pass_count=1010 fail_count=0`.
- `run_zetas_rom.sh`: PASS, `pass_count=16 fail_count=0`.
- `run_butterfly_unit.sh`: PASS, `pass_count=206 fail_count=0`.
- `run_ntt_addr_gen.sh`: PASS, `pass_count=1792 fail_count=0`.
- `run_ntt_core.sh`: PASS, `pass_count=512 fail_count=0`.
- `git diff --check`: clean.
- `intt_butterfly_unit.v` compiles cleanly with its arithmetic dependencies.

Remains to do:

- Confirm the pushed commit hash and clean working tree in the final response.

### 2026-07-06 Post-Push RTL Cleanup Checkpoint

Requested:

- Save all remaining local progress to GitHub after the first checkpoint push.

Files changed:

- Updated `rtl/ntt/ntt_core.v` to block external load writes during the same
  cycle as `start`.
- Updated `rtl/ntt/zetas_rom.v` constants from 16-bit signed literals to
  12-bit unsigned coefficient-width literals.
- Updated `TODO.md` with this checkpoint entry.

Commands run:

- `git status --short`
- `git log -1 --oneline`
- `git rev-parse --short HEAD`
- `git diff -- rtl/ntt/ntt_core.v`
- `git diff -- rtl/ntt/zetas_rom.v`
- `git diff --stat`
- `git diff --check`
- `./sim/scripts/run_zetas_rom.sh`
- `./sim/scripts/run_ntt_core.sh`
- `./sim/scripts/run_butterfly_unit.sh`
- `apply_patch`

Verified:

- `git diff --check`: clean.
- `run_zetas_rom.sh`: PASS, `pass_count=16 fail_count=0`.
- `run_ntt_core.sh`: PASS, `pass_count=512 fail_count=0`.
- `run_butterfly_unit.sh`: PASS, `pass_count=206 fail_count=0`.

Remains to do:

- Confirm the final pushed commit hash and clean working tree in the final
  response.

## Next Session Start Here

1. Read `TODO.md`.
2. Read `docs/00_project_spec/milestone_status.md`.
3. Read `README.md`.
4. Read `docs/04_verification/verification_plan.md`.
5. Start by adding self-checking verification for `intt_butterfly_unit.v`, then
   decide whether to harden `ntt_core` load/start gating.

### 2026-07-06 Repository Orientation For Project Understanding

Requested:

- Understand the current repository and explain the project status.

Files changed:

- Updated `reports/simulation/arithmetic_ntt_smoke_report.md` to match the
  current passing arithmetic and NTT simulation results.
- Updated `reports/simulation/reduction_mod_mul_report.md` to remove stale
  blocked status for `mod_mul.v`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `pwd`
- `rg -n "Post_Quantum_Cryptography|ML-KEM|Kyber|TODO|M1|simulation|pd" /home/hien/.codex/memories/MEMORY.md`
- `ls`
- `sed -n ... TODO.md`
- `find . -maxdepth 3 -type f | sort`
- `find . -maxdepth 3 -type d | sort`
- `git status --short`
- `sed -n ... README.md docs/00_project_spec/project_spec.md docs/00_project_spec/milestone_status.md docs/README.md rtl/README.md sim/README.md`
- `sed -n ... docs/04_verification/verification_plan.md docs/04_verification/test_vector_plan.md docs/02_math/modular_arithmetic_notes.md docs/03_architecture/ntt_architecture.md`
- `sed -n ... reports/simulation/mod_add_report.md reports/simulation/ntt_core_report.md`
- `sed -n ... rtl/common/kyber_params.vh rtl/arithmetic/mod_add.v rtl/arithmetic/mod_sub.v rtl/arithmetic/mod_mul.v rtl/ntt/ntt_core.v`
- `rg -n '^module ' ...` over RTL and unit testbench files
- `./sim/scripts/run_mod_add.sh`
- `./sim/scripts/run_mod_sub.sh`
- `./sim/scripts/run_reduction.sh`
- `./sim/scripts/run_mod_mul.sh`
- `./sim/scripts/run_zetas_rom.sh`
- `./sim/scripts/run_butterfly_unit.sh`
- `./sim/scripts/run_ntt_addr_gen.sh`
- `./sim/scripts/run_ntt_core.sh`
- `sed -n ... Roadmap.md ref_model/README.md sim/scripts/rtl.f sim/scripts/tb.f sim/scripts/Makefile`
- `git diff --stat`
- `git diff -- rtl/ntt/ntt_core.v`
- `git diff -- .agents/workflows/startpqc.md`
- `apply_patch`

Verified:

- Current milestone is still `M1: Algorithm and Verification Foundation`.
- Active repo scope is standards/reference model/KAT/RTL/testbench/simulation/
  architecture/verification; physical design remains out of current scope.
- Existing arithmetic and NTT simulation scripts pass:
  `mod_add`, `mod_sub`, `reduction`, `mod_mul`, `zetas_rom`,
  `butterfly_unit`, `ntt_addr_gen`, and `ntt_core`.
- `sim/scripts/Makefile`, `rtl.f`, and `tb.f` still default to the original
  `mod_add` flow; broader checks are run through individual scripts.
- Pre-existing local modifications were observed in `.agents/workflows/startpqc.md`
  and `rtl/ntt/ntt_core.v`.

Remains to do:

- Add self-checking verification for `intt_butterfly_unit.v`.
- Decide whether to create a single top-level regression script for all current
  unit simulations.
- Fill FIPS 203 notes and connect future RTL checks to a trusted KAT/golden
  reference flow.

## Next Session Start Here

1. Read `TODO.md`.
2. Read `README.md` and `docs/00_project_spec/milestone_status.md`.
3. Run the current unit checks with the individual scripts under `sim/scripts/`.
4. Start the next technical task with `intt_butterfly_unit.v` verification or a
   unified regression script.

### 2026-07-06 intt_core Verification

Requested:

- Verify and test the newly written inverse NTT core, `rtl/ntt/intt_core.v`.

Files changed:

- Fixed compile/connectivity issues in `rtl/ntt/intt_core.v` while preserving
  the intended inverse NTT architecture.
- Added `tb/unit/tb_intt_core.v`.
- Added `sim/scripts/run_intt_core.sh`.
- Added `reports/simulation/intt_core_report.md`.
- Updated `reports/simulation/arithmetic_ntt_smoke_report.md` to include
  `intt_core`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,180p' TODO.md`
- `rg -n "intt|innt|ntt_core|butterfly" /home/hien/.codex/memories/MEMORY.md`
- `find rtl tb sim/scripts reports/simulation -maxdepth 3 -type f | sort | rg 'intt|innt|ntt_core|butterfly|ntt_addr'`
- `git status --short`
- `sed -n ... rtl/ntt/intt_core.v`
- `sed -n ... tb/unit/tb_ntt_core.v`
- `sed -n ... rtl/ntt/ntt_addr_gen.v`
- `sed -n ... rtl/ntt/intt_butterfly_unit.v`
- `sed -n ... sim/scripts/run_ntt_core.sh`
- `sed -n ... rtl/ntt/zetas_rom.v rtl/memory/poly_buffer.v tb/unit/tb_butterfly_unit.v`
- `sed -n ... ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/Reference_Implementation/crypto_kem/kyber768/ntt.c`
- `iverilog -g2012 -Wall -I rtl/common -o /tmp/intt_core_check.out ... rtl/ntt/intt_core.v`
- `chmod +x sim/scripts/run_intt_core.sh`
- `./sim/scripts/run_intt_core.sh`
- `./sim/scripts/run_zetas_rom.sh`
- `./sim/scripts/run_butterfly_unit.sh`
- `./sim/scripts/run_ntt_addr_gen.sh`
- `./sim/scripts/run_ntt_core.sh`
- `./sim/scripts/run_mod_add.sh`
- `./sim/scripts/run_mod_sub.sh`
- `./sim/scripts/run_reduction.sh`
- `./sim/scripts/run_mod_mul.sh`
- `apply_patch`

Verified:

- `intt_core.v` elaborates with Icarus Verilog after fixes.
- `run_intt_core.sh`: PASS, `pass_count=768 fail_count=0`.
- `run_zetas_rom.sh`: PASS, `pass_count=16 fail_count=0`.
- `run_butterfly_unit.sh`: PASS, `pass_count=206 fail_count=0`.
- `run_ntt_addr_gen.sh`: PASS, `pass_count=1792 fail_count=0`.
- `run_ntt_core.sh`: PASS, `pass_count=512 fail_count=0`.
- `run_mod_add.sh`: PASS, `pass_count=1009 fail_count=0`.
- `run_mod_sub.sh`: PASS, `pass_count=1012 fail_count=0`.
- `run_reduction.sh`: PASS, `pass_count=620 fail_count=0`.
- `run_mod_mul.sh`: PASS, `pass_count=1010 fail_count=0`.

Remains to do:

- Add a dedicated self-checking unit test for `intt_butterfly_unit.v`, or
  replace duplicated inverse butterfly logic in `intt_core.v` with the existing
  unit after that unit is verified.
- Consider adding one top-level regression script that runs all current
  arithmetic, NTT, and INTT tests.
- Connect NTT/INTT validation to trusted KAT/golden-reference vectors before
  making cryptographic correctness claims.

## Next Session Start Here

1. Read `TODO.md`.
2. Run `./sim/scripts/run_intt_core.sh`.
3. Review `reports/simulation/intt_core_report.md`.
4. Next best task: add `tb/unit/tb_intt_butterfly_unit.v` or create a unified
   regression script for all current unit tests.

### 2026-07-06 NTT-INTT Round-Trip Verification

Requested:

- Test the flow `poly -> NTT -> INTT -> poly`.
- Write a testbench.
- Do not modify RTL code.

Files changed:

- Added `tb/block/tb_ntt_intt_roundtrip.v`.
- Added `sim/scripts/run_ntt_intt_roundtrip.sh`.
- Added `reports/simulation/ntt_intt_roundtrip_report.md`.
- Updated `reports/simulation/arithmetic_ntt_smoke_report.md` to include the
  round-trip test.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,180p' TODO.md`
- `git status --short`
- `sed -n ... rtl/ntt/ntt_core.v`
- `sed -n ... rtl/ntt/intt_core.v`
- `sed -n ... tb/unit/tb_intt_core.v`
- `chmod +x sim/scripts/run_ntt_intt_roundtrip.sh`
- `./sim/scripts/run_ntt_intt_roundtrip.sh`
- `./sim/scripts/run_ntt_core.sh`
- `./sim/scripts/run_intt_core.sh`
- `apply_patch`

Verified:

- No RTL files were intentionally modified for this task.
- Initial exact raw-poly comparison exposed the expected Kyber representation:
  `NTT -> INTT` returns `input * R mod q`, not raw input, where
  `R = 2^16 mod 3329 = 2285`.
- `run_ntt_intt_roundtrip.sh`: PASS, `pass_count=1024 fail_count=0`, checking
  four 256-coefficient patterns against Montgomery-domain output.
- `run_ntt_core.sh`: PASS, `pass_count=512 fail_count=0`.
- `run_intt_core.sh`: PASS, `pass_count=768 fail_count=0`.

Remains to do:

- If a raw polynomial output is required after INTT, add a planned conversion
  step after the current Montgomery-domain result, or define a separate
  non-Montgomery inverse flow.
- Add `tb/unit/tb_intt_butterfly_unit.v`.
- Consider adding a unified regression script for all current arithmetic, NTT,
  INTT, and round-trip checks.

## Next Session Start Here

1. Read `TODO.md`.
2. Run `./sim/scripts/run_ntt_intt_roundtrip.sh`.
3. Review `reports/simulation/ntt_intt_roundtrip_report.md`.
4. Decide whether the next target is raw-domain post-INTT conversion,
   `intt_butterfly_unit` verification, or a unified regression script.

### 2026-07-06 basemul_unit Verification

Requested:

- Test `rtl/ntt/basemul_unit.v`.

Files changed:

- Fixed mechanical compile blockers in `rtl/ntt/basemul_unit.v`:
  trailing output-port comma, duplicate `a0_reg`, `status` typo, `to_reg`
  typo, missing case-label colon, and `ST_MUL_T0_ZETA` state-name mismatch.
- Added `tb/unit/tb_basemul_unit.v`.
- Added `sim/scripts/run_basemul_unit.sh`.
- Added `reports/simulation/basemul_unit_report.md`.
- Updated `reports/simulation/arithmetic_ntt_smoke_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,160p' TODO.md`
- `rg -n "basemul|ntt_core|intt_core|butterfly" /home/hien/.codex/memories/MEMORY.md`
- `find rtl tb sim/scripts reports/simulation -maxdepth 3 -type f | sort | rg 'basemul|ntt|mul|butterfly'`
- `git status --short`
- `sed -n ... rtl/ntt/basemul_unit.v`
- `sed -n ... ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/Reference_Implementation/crypto_kem/kyber768/ntt.c`
- `sed -n ... tb/unit/tb_mod_mul.v`
- `sed -n ... sim/scripts/run_mod_mul.sh`
- `iverilog -g2012 -Wall -I rtl/common -o /tmp/basemul_unit_check.out ... rtl/ntt/basemul_unit.v`
- `chmod +x sim/scripts/run_basemul_unit.sh`
- `./sim/scripts/run_basemul_unit.sh`
- `./sim/scripts/run_mod_mul.sh`
- `./sim/scripts/run_mod_add.sh`
- `apply_patch`

Verified:

- `basemul_unit.v` elaborates with Icarus Verilog after mechanical fixes.
- `run_basemul_unit.sh`: PASS, `pass_count=507 fail_count=0`.
- `run_mod_mul.sh`: PASS, `pass_count=1010 fail_count=0`.
- `run_mod_add.sh`: PASS, `pass_count=1009 fail_count=0`.
- Testbench covers seven directed cases and 500 random canonical coefficient
  tuples against the Kyber `basemul()` equation.

Remains to do:

- Decide whether to integrate `basemul_unit` into a higher-level pointwise
  polynomial/vector multiplication block.
- Add a unified regression script for arithmetic, butterfly, basemul, NTT,
  INTT, and round-trip checks.
- Continue KAT/golden-reference planning before cryptographic correctness
  claims.

## Next Session Start Here

1. Read `TODO.md`.
2. Run `./sim/scripts/run_basemul_unit.sh`.
3. Review `reports/simulation/basemul_unit_report.md`.
4. Next useful target: pointwise multiplication planning or a unified regression
   script.

### 2026-07-06 GitHub Push Checkpoint

Requested:

- Push the current code to GitHub to save progress.

Files changed:

- Included the current INTT core, NTT/INTT round-trip, basemul unit, testbench,
  run-script, report, TODO, and agent-workflow updates in one checkpoint.
- Removed trailing whitespace from `.agents/workflows/startpqc.md` and
  `rtl/ntt/ntt_core.v` so `git diff --check` is clean.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `tail -n 140 TODO.md`
- `git status --short`
- `git diff --stat`
- `git remote -v`
- `git branch --show-current`
- `./sim/scripts/run_basemul_unit.sh`
- `./sim/scripts/run_intt_core.sh`
- `./sim/scripts/run_ntt_intt_roundtrip.sh`
- `./sim/scripts/run_ntt_core.sh`
- `git diff --check`
- `apply_patch`

Verified:

- `run_basemul_unit.sh`: PASS, `pass_count=507 fail_count=0`.
- `run_intt_core.sh`: PASS, `pass_count=768 fail_count=0`.
- `run_ntt_intt_roundtrip.sh`: PASS, `pass_count=1024 fail_count=0`.
- `run_ntt_core.sh`: PASS, `pass_count=512 fail_count=0`.
- `git diff --check` was run before staging; trailing whitespace was fixed.
- Created commit `3646f2b` with the RTL and verification checkpoint.
- Pushed `3646f2b` to `origin/main`.

Remains to do:

- Continue from the pushed checkpoint on `origin/main`.

## Next Session Start Here

1. Read `TODO.md`.
2. Confirm the latest pushed commit hash.
3. Run the desired next regression script or start pointwise multiplication
   planning.

### 2026-07-06 High-Frequency Basemul Direction Update

Requested:

- Update the project direction globally from area-saving/resource-optimized
  style to correctness-first, high-frequency/Fmax-first RTL after correctness.
- Keep the repository structure unchanged.
- Convert `rtl/ntt/basemul_unit.v` into the main high-throughput pipelined
  basemul implementation.
- Update the basemul testbench, run script, reports, and project handoff.

Files changed:

- Updated `.agents/workflows/AGENT.md` with architecture priority and future
  agent behavior.
- Updated `README.md`.
- Updated `docs/00_project_spec/project_spec.md`.
- Updated `docs/00_project_spec/roadmap.md`.
- Updated `docs/03_architecture/ntt_architecture.md`.
- Updated `rtl/ntt/basemul_unit.v` from sequential `start/busy/done` style to
  a valid-only 3-stage pipelined implementation.
- Updated `tb/unit/tb_basemul_unit.v` for the pipeline interface and latency
  checks.
- Updated `sim/scripts/run_basemul_unit.sh`.
- Updated `reports/simulation/basemul_unit_report.md`.
- Updated `reports/simulation/arithmetic_ntt_smoke_report.md`.
- Updated `TODO.md` with priority and this handoff entry.

Commands run:

- `pwd`
- `sed -n '1,180p' TODO.md`
- `rg -n "basemul|high-frequency|Fmax|Architecture Priority|area|pipeline|pipelined|Post_Quantum_Cryptography" /home/hien/.codex/memories/MEMORY.md`
- `git status --short`
- `find . -name 'AGENTS.md' -o -name 'AGENT.md' -o -name 'agent.md' | sort`
- `sed -n ... .agents/workflows/AGENT.md README.md docs/00_project_spec/project_spec.md docs/00_project_spec/roadmap.md docs/03_architecture/ntt_architecture.md`
- `sed -n ... rtl/ntt/basemul_unit.v tb/unit/tb_basemul_unit.v sim/scripts/run_basemul_unit.sh reports/simulation/basemul_unit_report.md reports/simulation/arithmetic_ntt_smoke_report.md`
- `./sim/scripts/run_basemul_unit.sh`
- `./sim/scripts/run_mod_mul.sh`
- `./sim/scripts/run_mod_add.sh`
- `./sim/scripts/run_ntt_core.sh`
- `./sim/scripts/run_intt_core.sh`
- `./sim/scripts/run_ntt_intt_roundtrip.sh`
- `git diff --check`
- `git status --short`
- `git diff --stat`
- `apply_patch`

Verified:

- `run_basemul_unit.sh`: PASS, `tx_count=514`, `pass_count=514`,
  `fail_count=0`.
- `run_mod_mul.sh`: PASS, `pass_count=1010 fail_count=0`.
- `run_mod_add.sh`: PASS, `pass_count=1009 fail_count=0`.
- `run_ntt_core.sh`: PASS, `pass_count=512 fail_count=0`.
- `run_intt_core.sh`: PASS, `pass_count=768 fail_count=0`.
- `run_ntt_intt_roundtrip.sh`: PASS, `pass_count=1024 fail_count=0`.
- `git diff --check`: clean after final edits.

Remains to do:

- Integrate the pipelined `basemul_unit` into future poly-level pointwise
  multiplication.
- Delay write addresses, zeta indices, coefficient-pair indices, and valid
  strobes by the basemul pipeline latency in future poly-level users.
- Pipeline `mod_mul` / Montgomery reduction later if synthesis or timing review
  identifies it as the critical path; this will require basemul latency
  realignment.
- Connect these block tests to trusted KAT/golden-reference verification before
  full ML-KEM correctness claims.

## Next Session Start Here

1. Read `TODO.md`.
2. Run `./sim/scripts/run_basemul_unit.sh`.
3. Review `reports/simulation/basemul_unit_report.md`.
4. Start poly-level pointwise multiplication planning around the 3-cycle
   valid-only pipelined `basemul_unit` interface.

### 2026-07-06 Markdown Project Orientation Refresh

Requested:

- Read the project Markdown files to understand what the project needs to do.

Files changed:

- Updated `TODO.md` with this handoff entry.

Commands run:

- `pwd`
- `rg --files -g 'TODO.md' -g '*.md'`
- `rg -n "Post_Quantum_Cryptography|ML-KEM|Kyber|TODO|M1|Algorithm|Verification" /home/hien/.codex/memories/MEMORY.md`
- `sed -n ... TODO.md`
- `sed -n ... README.md`
- `sed -n ... Roadmap.md`
- `sed -n ... CHANGELOG.md`
- `wc -l ...` over repository Markdown files
- `awk ...` over active docs, report docs, reference docs, folder READMEs, and archived Markdown scaffolds
- `git status --short`
- `tail -n 80 TODO.md`

Verified:

- `TODO.md` exists in the project root and is the persistent handoff file.
- Repository Markdown files were reviewed, including active project docs,
  standards/math/architecture/verification notes, simulation reports, reference
  docs, folder READMEs, and archived scaffold notes.
- Current milestone remains `M1: Algorithm and Verification Foundation`.
- Active scope remains standards/reference model/KAT/RTL/testbench/simulation/
  architecture/verification.
- Current phase still excludes Genus, Innovus, PnR, STA, GDSII, and Physical
  Design.
- Existing docs point the next technical work toward pipelined basemul
  integration, pointwise multiplication planning, unified regression, and
  trusted KAT/golden-reference comparison.

Remains to do:

- Integrate the 3-cycle valid-only pipelined `basemul_unit` into future
  poly-level pointwise multiplication.
- Add or finish a unified regression script for current unit/block tests.
- Fill FIPS 203 notes and choose the exact trusted ML-KEM/Kyber-768 KAT
  baseline.
- Connect RTL simulation outputs to a trusted golden-reference/KAT comparison
  before making full cryptographic correctness claims.

## Next Session Start Here

1. Read `TODO.md`.
2. Review `README.md`, `docs/00_project_spec/roadmap.md`, and
   `docs/03_architecture/ntt_architecture.md`.
3. Run the relevant current script, especially
   `./sim/scripts/run_basemul_unit.sh`, before changing datapath logic.
4. Start from poly-level pointwise multiplication planning around the 3-cycle
   valid-only pipelined `basemul_unit`, or create the unified regression script.

### 2026-07-06 poly_basemul_addr_gen Verification

Requested:

- User wrote `rtl/poly/poly_basemul_addr_gen.v`.
- Add a self-checking testbench and test it.
- Do not modify the user's RTL.

Files changed:

- Added `tb/unit/tb_poly_basemul_addr_gen.v`.
- Added `sim/scripts/run_poly_basemul_addr_gen.sh`.
- Added `reports/simulation/poly_basemul_addr_gen_report.md`.
- Updated `reports/simulation/arithmetic_ntt_smoke_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,220p' TODO.md`
- `rg --files rtl tb sim/scripts reports/simulation | sort`
- `rg -n "poly_basemul|basemul|pointwise|poly" /home/hien/.codex/memories/MEMORY.md`
- `nl -ba rtl/poly/poly_basemul_addr_gen.v`
- `sed -n ... tb/unit/tb_ntt_addr_gen.v`
- `sed -n ... tb/unit/tb_basemul_unit.v`
- `sed -n ... sim/scripts/run_ntt_addr_gen.sh`
- `sed -n ... sim/scripts/run_basemul_unit.sh`
- `sed -n '1,180p' rtl/common/kyber_params.vh`
- `git status --short`
- `apply_patch`
- `chmod +x sim/scripts/run_poly_basemul_addr_gen.sh`
- `./sim/scripts/run_poly_basemul_addr_gen.sh`

Verified:

- The new testbench checks the documented Kyber `poly_basemul_montgomery`
  schedule for all 128 base-multiplication operations.
- Checked every generated operation for `op_index`, `a_addr0/a_addr1`,
  `b_addr0/b_addr1`, `r_addr0/r_addr1`, `zeta_addr`, and `zeta_neg`.
- Checked reset idle behavior, active `valid`/`busy`, one-cycle `done`, and
  idle state after completion.
- Ran the full 128-operation schedule twice.
- During the second run, pulsed `start` while `busy` was already high and
  verified that the active schedule continued instead of restarting.
- `./sim/scripts/run_poly_basemul_addr_gen.sh`: PASS,
  `pass_count=256 fail_count=0`.
- `rtl/poly/poly_basemul_addr_gen.v` was not modified.

Remains to do:

- Integrate this address generator with the 3-cycle pipelined `basemul_unit` in
  the future poly-level pointwise multiplication block.
- Delay output write addresses, coefficient-pair metadata, zeta-control
  metadata, and valid strobes to match basemul pipeline latency.
- Continue connecting poly-level tests to trusted KAT/golden-reference
  comparison before full cryptographic correctness claims.

## Next Session Start Here

1. Read `TODO.md`.
2. Run `./sim/scripts/run_poly_basemul_addr_gen.sh`.
3. Review `reports/simulation/poly_basemul_addr_gen_report.md`.
4. Next best technical target: integrate `poly_basemul_addr_gen` with the
   3-cycle valid-only pipelined `basemul_unit` while delaying write/control
   metadata by the same latency.

### 2026-07-06 poly_basemul_montgomery Testbench Bring-up

Requested:

- User wrote `rtl/poly/poly_basemul_montgomery.v`.
- Add a testbench and test it.
- Do not modify the user's RTL.

Files changed:

- Added `tb/unit/tb_poly_basemul_montgomery.v`.
- Added `sim/scripts/run_poly_basemul_montgomery.sh`.
- Added `reports/simulation/poly_basemul_montgomery_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,180p' TODO.md`
- `rg --files rtl tb sim/scripts reports/simulation | sort`
- `git status --short`
- `nl -ba rtl/poly/poly_basemul_montgomery.v`
- `nl -ba rtl/poly/poly_basemul_addr_gen.v`
- `nl -ba rtl/ntt/basemul_unit.v`
- `sed -n ... tb/unit/tb_poly_basemul_addr_gen.v`
- `nl -ba rtl/memory/poly_buffer.v`
- `nl -ba rtl/ntt/zetas_rom.v`
- `rg -n "poly_basemul_montgomery|poly_basemul" ref_model/c_ref docs rtl tb sim reports -S`
- `apply_patch`
- `chmod +x sim/scripts/run_poly_basemul_montgomery.sh`
- `./sim/scripts/run_poly_basemul_montgomery.sh`
- `git diff --check`
- `tail -n 120 sim/logs/poly_basemul_montgomery.log`

Verified:

- Added a self-checking full-polynomial testbench for the intended
  `poly_basemul_montgomery` interface.
- The testbench is designed to load full A and B polynomials, compute expected
  output with the Kyber `poly_basemul_montgomery` / `basemul` equations, wait
  for `done`, and compare all 256 R coefficients for three deterministic
  polynomial patterns.
- The run script compiles all current dependencies:
  `reduction`, `mod_mul`, `mod_add`, `basemul_unit`, `zetas_rom`,
  `poly_buffer`, `poly_basemul_addr_gen`, and `poly_basemul_montgomery`.
- Current DUT test is blocked at RTL compile.
- First compiler blocker:
  `rtl/poly/poly_basemul_montgomery.v:85: error: Superfluous comma in port declaration list.`
- Additional visible RTL blockers include malformed `poly_buffer` instance
  punctuation, duplicate `r_addr0_d0`, typo `always $(`, missing semicolon after
  `r_addr1_d1 <= r_addr1_d0`, implicit `r_write_valid/r_write_last`, and
  duplicated/misnamed R-buffer write ports.
- `rtl/poly/poly_basemul_montgomery.v` was not modified.
- `git diff --check`: clean.

Remains to do:

- Fix `rtl/poly/poly_basemul_montgomery.v` compile blockers, starting with the
  port list around line 85.
- Add the missing intended A-load ports (`a_load_en`, `a_load_addr`,
  `a_load_data`) to the module interface or otherwise define how polynomial A is
  loaded; the RTL already references those signals internally.
- After RTL compiles, rerun `./sim/scripts/run_poly_basemul_montgomery.sh` for
  functional full-polynomial comparison.

## Next Session Start Here

1. Read `TODO.md`.
2. Fix `rtl/poly/poly_basemul_montgomery.v` compile blockers.
3. Rerun `./sim/scripts/run_poly_basemul_montgomery.sh`.
4. If compile passes but output mismatches remain, inspect address/data latency
   alignment between `poly_basemul_addr_gen`, `poly_buffer`, and the 3-cycle
   pipelined `basemul_unit`.

### 2026-07-07 poly_basemul_montgomery Retest

Requested:

- Retest `rtl/poly/poly_basemul_montgomery.v` after user-side fixes.
- Do not modify RTL.

Files changed:

- Updated `reports/simulation/poly_basemul_montgomery_report.md`.
- Updated `TODO.md` with this retest entry.

Commands run:

- `sed -n '1,220p' TODO.md`
- `git status --short`
- `nl -ba rtl/poly/poly_basemul_montgomery.v | sed -n '1,380p'`
- `./sim/scripts/run_poly_basemul_montgomery.sh`
- `nl -ba rtl/poly/poly_basemul_montgomery.v | sed -n '168,225p'`
- `nl -ba rtl/poly/poly_basemul_montgomery.v | sed -n '288,330p'`
- `tail -n 80 sim/logs/poly_basemul_montgomery.log`

Verified:

- The previous top-level trailing comma and duplicate `r_addr0_d0` declaration
  are fixed.
- Test remains blocked at RTL compile.
- Current first compiler error:
  `rtl/poly/poly_basemul_montgomery.v:191: syntax error`.
- Remaining visible blockers include trailing commas at the final named port
  connections of the A, B, and R `poly_buffer` instances, duplicate instance
  name `u_a_buffer` for the B buffer, misspelled declarations
  `r_wrire_valid/r_wrire_last`, and missing intended A-load ports in the module
  interface.
- `rtl/poly/poly_basemul_montgomery.v` was not modified.

Remains to do:

- Remove trailing commas from final named port connections at the A/B/R
  `poly_buffer` instances.
- Rename the B buffer instance from `u_a_buffer` to a unique name such as
  `u_b_buffer`.
- Rename `r_wrire_valid/r_wrire_last` to `r_write_valid/r_write_last`.
- Add intended `a_load_en`, `a_load_addr`, and `a_load_data` ports to the
  module interface, or define another A-load interface and update the testbench
  accordingly.
- Rerun `./sim/scripts/run_poly_basemul_montgomery.sh`.

## Next Session Start Here

1. Read `TODO.md`.
2. Fix the remaining compile blockers in `rtl/poly/poly_basemul_montgomery.v`.
3. Rerun `./sim/scripts/run_poly_basemul_montgomery.sh`.
4. If it compiles, inspect any coefficient mismatches for basemul/data/address
   latency alignment.

### 2026-07-07 poly_basemul_montgomery Retest 2

Requested:

- Retest `rtl/poly/poly_basemul_montgomery.v` after another user-side fix.
- Do not modify RTL.

Files changed:

- Updated `reports/simulation/poly_basemul_montgomery_report.md`.
- Updated `TODO.md` with this retest entry.

Commands run:

- `sed -n '1,180p' TODO.md`
- `git status --short`
- `nl -ba rtl/poly/poly_basemul_montgomery.v | sed -n '66,340p'`
- `./sim/scripts/run_poly_basemul_montgomery.sh`
- `tail -n 80 sim/logs/poly_basemul_montgomery.log`
- `nl -ba rtl/poly/poly_basemul_montgomery.v | sed -n '72,86p;170,206p'`

Verified:

- The previous final-port trailing commas and `r_write_*` spelling issue are
  fixed.
- Test remains blocked at RTL compile.
- Current hard compiler error:
  `rtl/poly/poly_basemul_montgomery.v:202: error: 'u_a_buffer' has already been declared in this scope.`
- Current warnings show `a_load_addr` and `a_load_data` are still implicit
  wires because the module port list exposes only B-load ports.
- `rtl/poly/poly_basemul_montgomery.v` was not modified.

Remains to do:

- Rename the B buffer instance from `u_a_buffer` to a unique name such as
  `u_b_buffer`.
- Add intended `a_load_en`, `a_load_addr`, and `a_load_data` ports to the
  module interface, or define another A-load interface and update the testbench
  accordingly.
- Rerun `./sim/scripts/run_poly_basemul_montgomery.sh`.

## Next Session Start Here

1. Read `TODO.md`.
2. Rename the B-buffer instance and finish the A-load interface in
   `rtl/poly/poly_basemul_montgomery.v`.
3. Rerun `./sim/scripts/run_poly_basemul_montgomery.sh`.
4. If it compiles, evaluate any full-polynomial coefficient mismatches.

### 2026-07-07 poly_basemul_montgomery Retest PASS

Requested:

- Retest `rtl/poly/poly_basemul_montgomery.v` after user-side fixes.
- Do not modify RTL.

Files changed:

- Updated `reports/simulation/poly_basemul_montgomery_report.md`.
- Updated `reports/simulation/arithmetic_ntt_smoke_report.md`.
- Updated `TODO.md` with this retest entry.

Commands run:

- `sed -n '1,160p' TODO.md`
- `git status --short`
- `nl -ba rtl/poly/poly_basemul_montgomery.v | sed -n '72,220p'`
- `./sim/scripts/run_poly_basemul_montgomery.sh`

Verified:

- `poly_basemul_montgomery.v` now compiles.
- `./sim/scripts/run_poly_basemul_montgomery.sh`: PASS,
  `pass_count=768 fail_count=0`.
- The testbench checked three deterministic full-polynomial A/B patterns.
- All 256 R coefficients per pattern matched the behavioral Kyber
  `poly_basemul_montgomery` / `basemul` reference.
- `rtl/poly/poly_basemul_montgomery.v` was not modified by the reviewer.

Remains to do:

- Add `poly_basemul_montgomery` to any future unified regression script.
- Consider a higher-level polyvec accumulation test after the poly-level
  basemul datapath is stable.
- Continue connecting these RTL checks to trusted KAT/golden-reference flow
  before full ML-KEM correctness claims.

## Next Session Start Here

1. Read `TODO.md`.
2. Run `./sim/scripts/run_poly_basemul_montgomery.sh`.
3. Review `reports/simulation/poly_basemul_montgomery_report.md`.
4. Next useful target: add a unified regression script or start polyvec
   pointwise accumulation planning on top of the verified poly basemul block.

### 2026-07-07 GitHub Checkpoint Push

Requested:

- Push the repository to GitHub to save the current progress.

Files changed:

- `.agents/workflows/AGENT.md`
- `README.md`
- `TODO.md`
- `docs/00_project_spec/project_spec.md`
- `docs/00_project_spec/roadmap.md`
- `docs/03_architecture/ntt_architecture.md`
- `reports/simulation/arithmetic_ntt_smoke_report.md`
- `reports/simulation/basemul_unit_report.md`
- `reports/simulation/poly_basemul_addr_gen_report.md`
- `reports/simulation/poly_basemul_montgomery_report.md`
- `rtl/ntt/basemul_unit.v`
- `rtl/poly/poly_basemul_addr_gen.v`
- `rtl/poly/poly_basemul_montgomery.v`
- `sim/scripts/run_basemul_unit.sh`
- `sim/scripts/run_poly_basemul_addr_gen.sh`
- `sim/scripts/run_poly_basemul_montgomery.sh`
- `tb/unit/tb_basemul_unit.v`
- `tb/unit/tb_poly_basemul_addr_gen.v`
- `tb/unit/tb_poly_basemul_montgomery.v`

Commands run:

- `pwd && git rev-parse --show-toplevel && git status --short --branch`
- `sed -n '1,220p' TODO.md`
- `git diff --cached --stat`
- `git diff --cached --name-status`
- `git diff --cached -- rtl/ntt/basemul_unit.v rtl/poly/poly_basemul_addr_gen.v rtl/poly/poly_basemul_montgomery.v tb/unit/tb_basemul_unit.v tb/unit/tb_poly_basemul_addr_gen.v tb/unit/tb_poly_basemul_montgomery.v sim/scripts/run_basemul_unit.sh sim/scripts/run_poly_basemul_addr_gen.sh sim/scripts/run_poly_basemul_montgomery.sh`
- `tail -n 180 TODO.md`
- `./sim/scripts/run_basemul_unit.sh`
- `./sim/scripts/run_poly_basemul_addr_gen.sh`
- `./sim/scripts/run_poly_basemul_montgomery.sh`
- `git diff --cached --check`
- `nl -ba rtl/poly/poly_basemul_addr_gen.v | sed -n '36,46p'`
- `nl -ba rtl/poly/poly_basemul_montgomery.v | sed -n '64,92p;148,190p;204,218p;242,286p;310,320p'`
- `apply_patch`
- `git diff --check`

Verified:

- `./sim/scripts/run_basemul_unit.sh`: PASS,
  `pass_count=514 fail_count=0`.
- `./sim/scripts/run_poly_basemul_addr_gen.sh`: PASS,
  `pass_count=256 fail_count=0`.
- `./sim/scripts/run_poly_basemul_montgomery.sh`: PASS,
  `pass_count=768 fail_count=0`.
- `git diff --check`: clean after removing staged trailing whitespace.

Remains to do:

- Add a unified regression script for the arithmetic, NTT, and poly-level
  unit tests.
- Consider polyvec pointwise accumulation after the poly basemul datapath
  remains stable.
- Continue connecting the RTL checks to trusted KAT/golden-reference flow
  before full ML-KEM correctness claims.

## Next Session Start Here

1. Read `TODO.md`.
2. Run the focused checks:
   `./sim/scripts/run_basemul_unit.sh`,
   `./sim/scripts/run_poly_basemul_addr_gen.sh`, and
   `./sim/scripts/run_poly_basemul_montgomery.sh`.
3. Add a unified regression script or begin polyvec pointwise accumulation
   planning on top of the verified poly basemul block.

### 2026-07-07 Ignore Local Agent Workflows

Requested:

- Add `.agents/workflows` to `.gitignore`.
- Commit and push the ignore/untrack change after GitHub still showed the
  previously tracked `.agents/workflows` directory.

Files changed:

- `.gitignore`
- `TODO.md`
- `.agents/workflows/AGENT.md` will be removed from Git tracking while kept
  locally, because ignored tracked files are still tracked by Git.

Commands run:

- `pwd && git rev-parse --show-toplevel && git status --short --branch`
- `sed -n '1,180p' TODO.md`
- `sed -n '1,240p' .gitignore`
- `git ls-files .agents/workflows .agents/workflows/AGENT.md`
- `find .agents -maxdepth 3 -type f -print`
- `tail -n 100 TODO.md`
- `apply_patch`
- `git rm --cached .agents/workflows/AGENT.md`
- `git status --short --branch`
- `git check-ignore -v .agents/workflows/AGENT.md`
- `git diff --check`
- `ls -la CHANGELOG.md .agents/workflows/AGENT.md`
- `git diff --name-status`
- `git diff --cached --name-status`
- `git status --ignored --short .agents/workflows/AGENT.md CHANGELOG.md .gitignore TODO.md`
- `git add .gitignore TODO.md`
- `git commit -m "chore: ignore local agent workflows"`
- `git push origin main`
- `git status --short --branch`
- `git log -1 --oneline`
- `git check-ignore -v .agents/workflows/AGENT.md`
- `git diff --check`

Verified:

- `.gitignore` contains `.agents/workflows/`.
- `.agents/workflows/AGENT.md` is removed from Git tracking but remains present
  locally.
- `git check-ignore -v .agents/workflows/AGENT.md` reports the
  `.agents/workflows/` rule from `.gitignore`.
- `git diff --check`: clean.
- Pushed commit `9d0358c chore: ignore local agent workflows` to `origin/main`.
- Final branch check reports `main...origin/main`; the only remaining worktree
  change is the unrelated local deletion of `CHANGELOG.md`.

Remains to do:

- None for `.agents/workflows`.

## Next Session Start Here

1. Read `TODO.md`.
2. Continue from the ML-KEM/Kyber algorithm and verification work.
3. Keep local agent workflow files under `.agents/workflows/` out of Git.

### 2026-07-07 Remove CHANGELOG

Requested:

- Confirmed that `CHANGELOG.md` was intentionally deleted because it is no
  longer needed.
- Commit and push the deletion so GitHub matches the local repository state.

Files changed:

- `CHANGELOG.md`
- `TODO.md`

Commands run:

- `git status --short --branch`
- `sed -n '1,120p' TODO.md`
- `tail -n 80 TODO.md`
- `apply_patch`
- `git add CHANGELOG.md TODO.md`
- `git status --short --branch`
- `git diff --cached --name-status`
- `git diff --cached --check`
- `git commit -m "chore: remove obsolete changelog"`
- `git push origin main`

Verified:

- Staged changes were exactly `CHANGELOG.md` deletion and `TODO.md` update.
- `git diff --cached --check`: clean.
- Pushed commit `72b22e1 chore: remove obsolete changelog` to `origin/main`.

Remains to do:

- None after final status verification.

## Next Session Start Here

1. Read `TODO.md`.
2. Continue from the ML-KEM/Kyber algorithm and verification work.
3. `CHANGELOG.md` has been removed intentionally; use `TODO.md`, reports, and
   commit history for handoff/status tracking.

### 2026-07-12 poly_add Testbench Bring-up

Requested:

- User wrote `rtl/poly/poly_add.v`.
- Add a testbench and test it.
- Do not modify the user's RTL; report RTL issues for the user to fix.

Files changed:

- Added `tb/unit/tb_poly_add.v`.
- Added `sim/scripts/run_poly_add.sh`.
- Added `reports/simulation/poly_add_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,220p' TODO.md`
- `sed -n '1,260p' rtl/poly/poly_add.v`
- `sed -n '1,220p' tb/unit/tb_poly_basemul_montgomery.v`
- `sed -n '1,140p' sim/scripts/run_poly_basemul_montgomery.sh`
- `git status --short --untracked-files=all`
- `sed -n '1,220p' rtl/memory/poly_buffer.v`
- `sed -n '1,120p' rtl/arithmetic/mod_add.v`
- `sed -n '1,220p' sim/scripts/run_poly_basemul_addr_gen.sh`
- `sed -n '1,140p' reports/simulation/poly_basemul_addr_gen_report.md`
- `ls tb/unit sim/scripts reports/simulation | rg 'poly_add|poly'`
- `apply_patch`
- `chmod +x sim/scripts/run_poly_add.sh`
- `./sim/scripts/run_poly_add.sh`
- `nl -ba rtl/poly/poly_add.v | sed -n '68,82p'`
- `tail -n 30 sim/logs/poly_add.log`

Verified:

- Added a self-checking full-polynomial testbench for `poly_add`.
- The testbench loads full A and B polynomials, pulses `start`, waits for
  `done`, reads all 256 R coefficients, and compares each result against
  `(a[i] + b[i]) mod KYBER_Q`.
- Test patterns cover all-zero operands, complementary operands, max canonical
  operands, and nontrivial arithmetic sequences.
- `./sim/scripts/run_poly_add.sh`: PASS, `pass_count=1024 fail_count=0`.
- `rtl/poly/poly_add.v` was not modified.

RTL warning for user to fix:

- `rtl/poly/poly_add.v` line 75 declares `start_acccepted`, but line 76 assigns
  `start_accepted`. Icarus Verilog creates `start_accepted` as an implicit wire,
  so the simulation still passes, but the typo should be fixed in RTL.

Remains to do:

- User should fix the `start_acccepted` / `start_accepted` spelling mismatch in
  `rtl/poly/poly_add.v`.
- Add `poly_add` to any future unified regression script.
- Consider adding `poly_sub` after the polynomial-add path is clean.

## Next Session Start Here

1. Read `TODO.md`.
2. Fix the `start_acccepted` typo in `rtl/poly/poly_add.v`.
3. Rerun `./sim/scripts/run_poly_add.sh`.
4. If clean, add `poly_add` to the future unified regression script.

### 2026-07-12 poly_add Retest After RTL Typo Fix

Requested:

- User fixed the `start_acccepted` / `start_accepted` typo in
  `rtl/poly/poly_add.v`.
- Rerun the focused `poly_add` test.

Files changed:

- Updated `reports/simulation/poly_add_report.md`.
- Updated `TODO.md` with this retest entry.

Commands run:

- `./sim/scripts/run_poly_add.sh`
- `nl -ba rtl/poly/poly_add.v | sed -n '70,78p'`

Verified:

- `rtl/poly/poly_add.v` now declares and assigns `start_accepted` consistently.
- `./sim/scripts/run_poly_add.sh`: PASS, `pass_count=1024 fail_count=0`.
- The prior implicit-wire warning is gone.

Remains to do:

- Add `poly_add` to any future unified regression script.
- Consider adding `poly_sub` after the polynomial-add path is clean.

## Next Session Start Here

1. Read `TODO.md`.
2. Run `./sim/scripts/run_poly_add.sh` if continuing polynomial-add work.
3. Add `poly_add` to the future unified regression script or start `poly_sub`
   planning.

### 2026-07-12 poly_sub Testbench Bring-up

Requested:

- Verify `rtl/poly/poly_sub.v`.
- Add a testbench and test it.
- Do not modify the user's RTL; report RTL issues for the user to fix.

Files changed:

- Added `tb/unit/tb_poly_sub.v`.
- Added `sim/scripts/run_poly_sub.sh`.
- Added `reports/simulation/poly_sub_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `tail -n 140 TODO.md`
- `ls rtl/poly tb/unit sim/scripts reports/simulation | rg 'poly_sub|poly_add' || true`
- `test -f rtl/poly/poly_sub.v && sed -n '1,260p' rtl/poly/poly_sub.v || true`
- `sed -n '1,260p' tb/unit/tb_poly_add.v`
- `sed -n '1,120p' sim/scripts/run_poly_add.sh`
- `sed -n '1,120p' rtl/arithmetic/mod_sub.v`
- `apply_patch`
- `chmod +x sim/scripts/run_poly_sub.sh`
- `./sim/scripts/run_poly_sub.sh`
- `nl -ba rtl/poly/poly_sub.v | sed -n '140,164p'`
- `grep -n "warning\\|FIRST_FAIL\\|pass_count\\|FAIL\\|PASS" sim/logs/poly_sub.log | sed -n '1,80p'`

Verified:

- Added a self-checking full-polynomial testbench for `poly_sub`.
- The testbench loads full A and B polynomials, pulses `start`, waits for
  `done`, reads all 256 R coefficients, and compares each result against
  `(a[i] - b[i]) mod KYBER_Q`.
- Test patterns cover all-zero operands, equal operands, full wraparound
  `0 - (KYBER_Q - 1)`, and nontrivial arithmetic sequences.
- `./sim/scripts/run_poly_sub.sh`: FAIL, `pass_count=0 fail_count=1024`.
- `rtl/poly/poly_sub.v` was not modified.

RTL issue for user to fix:

- `rtl/poly/poly_sub.v` lines 147-148 declare `sub_result0` and `sub_result1`.
- Lines 153 and 159 connect the `mod_sub` outputs to undeclared
  `add_result0` and `add_result1`.
- Icarus Verilog creates `add_result0/add_result1` as implicit 1-bit wires,
  while `sub_result0/sub_result1` remain undriven.
- The result buffer writes `sub_result0/sub_result1`, so every checked output is
  high-Z.

Remains to do:

- User should connect the two `mod_sub` output ports to `sub_result0` and
  `sub_result1`.
- Rerun `./sim/scripts/run_poly_sub.sh`.
- If the focused test passes, add `poly_sub` to any future unified regression
  script.

## Next Session Start Here

1. Read `TODO.md`.
2. Fix the `mod_sub` output wiring in `rtl/poly/poly_sub.v`.
3. Rerun `./sim/scripts/run_poly_sub.sh`.
4. If clean, add `poly_sub` to the future unified regression script.

### 2026-07-12 reduction.v Rewrite Verification

Requested:

- User rewrote `rtl/arithmetic/reduction.v`.
- Verify the rewritten reduction RTL.
- Do not modify the user's RTL.

Files changed:

- Updated `tb/unit/tb_reduction.v` to match the rewritten unsigned/canonical
  reducer contract.
- Updated `reports/simulation/reduction_mod_mul_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `tail -n 120 TODO.md`
- `ls rtl/arithmetic`
- `sed -n '1,260p' rtl/arithmetic/reduction.v`
- `sed -n '1,240p' tb/unit/tb_reduction.v`
- `sed -n '1,120p' sim/scripts/run_reduction.sh`
- `git status --short --untracked-files=all`
- `./sim/scripts/run_reduction.sh`
- `./sim/scripts/run_mod_mul.sh`
- `sed -n '1,140p' rtl/arithmetic/mod_mul.v`
- `sed -n '1,160p' reports/simulation/reduction_mod_mul_report.md`
- `tail -n 80 sim/logs/reduction.log`
- `tail -n 60 sim/logs/mod_mul.log`
- `apply_patch`
- `nl -ba tb/unit/tb_reduction.v | sed -n '118,150p'`
- `./sim/scripts/run_reduction.sh`

Verified:

- `rtl/arithmetic/reduction.v` was not modified by the verifier.
- `tb_reduction.v` was updated because the rewritten RTL now documents an
  unsigned/canonical output contract instead of the old signed C-style
  representative contract.
- `./sim/scripts/run_reduction.sh`: PASS, `pass_count=618 fail_count=0`.
- The final focused reduction run is warning-clean.

Dependent check:

- `./sim/scripts/run_mod_mul.sh` is blocked at elaboration:
  `rtl/arithmetic/mod_mul.v:44: error: Cannot override localparam Q in
  tb_mod_mul.dut.u_montgomery_reduce`.
- Root cause: `mod_mul.v` still instantiates `montgomery_reduce #(.Q(Q))`, but
  the rewritten `montgomery_reduce` now defines `Q` as a `localparam`, not an
  overrideable parameter.

Remains to do:

- User should update `rtl/arithmetic/mod_mul.v` for the new `montgomery_reduce`
  interface and unsigned/canonical output behavior.
- After that, rerun `./sim/scripts/run_mod_mul.sh`.
- Because `mod_mul` feeds higher-level NTT and basemul blocks, rerun dependent
  tests after the mod-mul wrapper is fixed.

## Next Session Start Here

1. Read `TODO.md`.
2. Fix `rtl/arithmetic/mod_mul.v` line 44 to match the new
   `montgomery_reduce` interface.
3. Rerun `./sim/scripts/run_mod_mul.sh`.
4. If `mod_mul` passes, rerun dependent arithmetic/NTT/basemul regressions.

### 2026-07-12 Unsigned mod_mul Repair And Verification

Requested:

- Fix `rtl/arithmetic/mod_mul.v` for the rewritten unsigned/canonical
  Montgomery reducer.
- Do not use signed arithmetic for `mod_mul`.
- Verify the repaired module and its direct dependents.

Files changed:

- Updated `rtl/arithmetic/mod_mul.v`.
- Updated `tb/unit/tb_mod_mul.v` to use an unsigned REDC oracle.
- Updated `reports/simulation/reduction_mod_mul_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `rg -n "signed|\$signed|>>>" rtl/arithmetic/mod_mul.v tb/unit/tb_mod_mul.v || true`
- `./sim/scripts/run_mod_mul.sh`
- `./sim/scripts/run_reduction.sh`
- `./sim/scripts/run_basemul_unit.sh`
- `./sim/scripts/run_poly_basemul_montgomery.sh`
- `./sim/scripts/run_ntt_core.sh`
- `./sim/scripts/run_intt_core.sh`
- `./sim/scripts/run_ntt_intt_roundtrip.sh`
- `git diff --check`

Verified:

- `mod_mul.v` uses only unsigned declarations and operations.
- `tb_mod_mul.v` uses only unsigned declarations and operations for its REDC
  oracle.
- `run_mod_mul.sh`: PASS, `pass_count=1010 fail_count=0`.
- `run_reduction.sh`: PASS, `pass_count=618 fail_count=0`.
- `run_basemul_unit.sh`: PASS, `pass_count=514 fail_count=0`.
- `run_poly_basemul_montgomery.sh`: PASS,
  `pass_count=768 fail_count=0`.
- `run_ntt_core.sh`: PASS, `pass_count=512 fail_count=0`.
- `run_intt_core.sh`: PASS, `pass_count=768 fail_count=0`.
- `run_ntt_intt_roundtrip.sh`: PASS, `pass_count=1024 fail_count=0`.

Remains to do:

- `rtl/arithmetic/reduction.v` still has two internal `wire signed`
  declarations despite its unsigned-only module contract. This file was not
  changed during the focused `mod_mul.v` repair.
- Rerun the polynomial-subtraction test after the user fixes its output wiring.
- Consider pipelining `mod_mul` only after synthesis identifies this
  combinational implementation as a timing limiter.

## Next Session Start Here

1. Read `TODO.md`.
2. If enforcing unsigned-only arithmetic across the whole reducer chain,
   replace the two remaining signed declarations in `reduction.v` and rerun
   the complete arithmetic/NTT/basemul regression set.
3. Otherwise continue with the pending `poly_sub` RTL wiring fix and rerun
   `./sim/scripts/run_poly_sub.sh`.
