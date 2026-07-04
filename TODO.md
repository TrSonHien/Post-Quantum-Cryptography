# TODO

## Current Milestone

M1: Project Foundation

## Completed

- [x] Initial repository exists
- [x] Roadmap file exists
- [x] Repository structure reorganized for ML-KEM-768 RTL-to-GDSII work

## In Progress

- [ ] Collect mandatory ML-KEM documents
- [ ] Create reading notes for FIPS 203
- [ ] Prepare reference model workspace
- [ ] Prepare verification workspace

## Blocked By

- None

## Next Target

Collect mandatory documents and start reading FIPS 203.

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

## Next Session Start Here

1. Read `Roadmap.md`.
2. Read `TODO.md`.
3. Read `docs/00_project_spec/milestone_status.md`.
4. Read `README.md`.
5. Start Phase 0 document control by filling `docs/01_standard/fips203_notes.md`.
