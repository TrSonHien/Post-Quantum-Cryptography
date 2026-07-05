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

## Blocked By

- None

## Next Target

Collect mandatory documents, start reading FIPS 203, and define the first reference-model-to-RTL comparison path.

## Current Focus

```text
standard reading -> reference model -> test vectors -> arithmetic RTL -> unit verification
```

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

## Next Session Start Here

1. Read `TODO.md`.
2. Read `docs/00_project_spec/milestone_status.md`.
3. Read `README.md`.
4. Read `docs/04_verification/verification_plan.md`.
5. Start by filling `docs/01_standard/fips203_notes.md` and selecting the first KAT comparison target.
