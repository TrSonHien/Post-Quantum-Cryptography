# M9 Academic RTL Release Handoff

## Release state

The ML-KEM-768 academic RTL release is functionally verified and
elaboration-ready.  The complete `mlkem768_top` hierarchy elaborates with
Verilator and Icarus.  Technology-mapped synthesis remains
environment-blocked because this workspace has no Yosys, Genus, or configured
standard-cell library.

## Release artifacts

- Interface: `docs/04_design/mlkem768_release_interface.md`
- Audit/lint: `reports/m9_0_release_audit.md`,
  `reports/m9_1_lint_elaboration_report.md`
- Synthesis handoff: `synth/m9/`,
  `reports/m9_2_m2_3b_completion_report.md`, and
  `reports/m9_3_mlkem_top_synthesis_report.md`
- Bottleneck/release evidence: `reports/m9_4_bottleneck_analysis.md` and
  `reports/m9_5_release_verification_report.md`

## Next synthesis-server steps

1. Install or load Yosys for the generic baseline, then run
   `synth/m9/run_yosys.sh`.
2. Provide the intended standard-cell Liberty and run
   `LIB_FILE=/absolute/path/to/stdcell.lib synth/m9/run_genus.sh`.
3. Run `LIB_FILE=/absolute/path/to/stdcell.lib synth/m2_3/run_synth_sweep.sh`.
4. Promote actual cell, memory, area, WNS/TNS, endpoint, and PVT evidence into
   the M2.3b and top synthesis reports before making any PPA claim.

## Limitations retained by design

Production-grade physical zeroization, comprehensive side-channel hardening,
exhaustive long-run regression, authoritative CAVP/ACVP validation, and
synthesis closure remain future work.  This release does not claim post-layout
timing, power, area, Fmax, or production certification.
