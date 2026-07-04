---

title: Start PQC Project Context
description: Load project context for the Post-Quantum Cryptography RTL/ASIC project before making changes.
-----------------------------------------------------------------------------------------------------------

# Start PQC Project Context

Use this workflow at the beginning of a new Antigravity session for this repository.

## Goal

Understand the current project state before editing files, running simulations, changing RTL, updating documentation, or preparing ASIC/PD flow work.

This workflow is read-only by default.

## Steps

1. Read the project context files:

   * `AGENTS.md`
   * `README.md`
   * `thoughts.txt` if it exists

2. Inspect the repository structure without modifying files:

   * Run `find . -maxdepth 3 -type f | sort`
   * Run `find . -maxdepth 3 -type d | sort`

3. Inspect Git state:

   * Run `git status`
   * Run `git branch --show-current`
   * Run `git log --oneline -n 5`

4. Inspect RTL files:

   * Read `rtl/module_top.v`
   * Read `rtl/tb.v`
   * Inspect `rtl/sim/` if it exists
   * Identify top module name
   * Identify testbench module name
   * Identify clock/reset naming
   * Identify whether the RTL is simulation-only or synthesizable

5. Inspect documentation:

   * Summarize what is currently in `documents/`
   * Note that Kyber specification documents exist
   * Do not extract or copy large copyrighted text from PDFs
   * Use the documents only to understand project direction and referenced algorithms

6. Inspect ASIC/PD readiness:

   * Check whether `pd/` contains scripts, constraints, reports, or flow files
   * If `pd/` is empty, state that ASIC/PD flow is not yet implemented
   * Do not create Genus/Innovus scripts unless explicitly asked

7. Produce a concise project summary with:

   * Current project purpose
   * Current folder structure
   * Current RTL status
   * Current documentation status
   * Current PD status
   * Missing files or unclear assumptions
   * Recommended next steps

8. Do not modify files during this workflow unless the user explicitly asks.

## Expected Output

Respond with:

1. Project Snapshot
2. RTL Snapshot
3. Documentation Snapshot
4. PD/ASIC Flow Snapshot
5. Git Snapshot
6. Missing Information
7. Suggested Next Actions
8. When recommending skills, always name the exact skill, such as `rtl-reviewer`, `technical-doc-reviewer`, `readme-maintainer`, `pd-flow-reviewer`, `sdc-reviewer`, or `tcl-script-reviewer`. Do not refer to skills generically as `SKILL.md`.

## Relevant Skills

Use these skills when appropriate:

* `rtl-reviewer` for RTL review
* `technical-doc-reviewer` for documents and README review
* `readme-maintainer` for README improvement
* `github-pr-reviewer` for Git diff or staged change review
* `commit-message-writer` for commit messages
* `pd-flow-reviewer` for ASIC/PD flow planning
* `sdc-reviewer` for SDC constraints
* `tcl-script-reviewer` for Genus/Innovus Tcl scripts
* `eda-log-analyzer` for EDA logs and reports

