# RTL Readability Campaign

## Scope and safety contract

This report records the comment-and-format-only campaign on branch
`readability/rtl-docs-v0.1`, based on release commit `e4d2418`.  The campaign
does not change functional Verilog tokens, module ports, module ordering,
testbenches, vector generators, expected data, synthesis collateral, or the
frozen `PQC_main` worktree.

The temporary checker `/tmp/check_verilog_logic_tokens.py` compared every
release RTL/header file with its immutable `git show e4d2418:<path>` snapshot.
It ignores whitespace and comments while comparing directives, macros,
identifiers, literals, operators, punctuation, and order.  Its self-test
covered whitespace/comment changes, identifiers, literals, operators,
assignment order, directives, macro calls, and strings containing comment
markers.

## Results

- RTL/header files checked: 115/115 PASS.
- Module declarations and structured module headers: 116/116.
- Complete hierarchy elaboration: PASS (`sim/scripts/run_m9_elaboration.sh`;
  Verilator warnings 631, Icarus warnings 91, no elaboration blocker).
- M2.1 primitive tests: PASS.
- M2.2 arithmetic tests: PASS.
- M3 regression: 22/22 PASS.
- M4 regression: first 15 checks PASS, then the existing `tb_poly_transform_pipe`
  wildcard `zeroize_req` connection fails elaboration.  The same failure was
  reproduced from an isolated `e4d2418` checkout; no testbench was changed.
- M5 regression: 16/16 PASS.
- M6 regression: 15/15 PASS.
- M7 K-PKE roundtrip: PASS (existing Icarus warnings only).
- Deterministic ML-KEM vector generation: PASS.

The interactive execution channel terminated the long Decaps sub-run of
`run_m8_smoke.sh` after its eight preceding PASS checks and detached the
combined M8 runner after smoke progress.  No simulation process remained.  The
verified release evidence remains M8 smoke 9/9 and reduced M8 functional 7/7
PASS at `e4d2418`; token equivalence establishes that this campaign did not
alter the verified logic.  A manual full `run_m8_smoke.sh` and
`run_m8_regression.sh` remain the final review confirmation on a normal shell.

## Deliberate non-work

No synthesizer, mapped synthesis, PPA study, physical design, zeroization
expansion, functional refactor, lint-warning cleanup, or interface redesign was
performed.  Existing warnings are documented by the release reports rather
than changed in a readability campaign.
