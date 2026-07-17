# M9.3 ML-KEM-768 Top Synthesis Report

## Outcome: elaboration PASS; synthesis ENVIRONMENT-BLOCKED

The M9 top is `mlkem768_top` from 114 RTL source files.  Both independent
elaborators pass the complete hierarchy.  `synth/m9/run_yosys.sh` validates the
source list and reports `ENVIRONMENT_BLOCKED tool=yosys`; `synth/m9/run_genus.sh`
reports `ENVIRONMENT_BLOCKED tool=genus`.  No local Liberty, `.db`, or usable
technology setup is configured.

The M9 constraints file contains an explicitly exploratory 20.0 ns clock with
0.2 ns uncertainty.  It is not a project frequency target and was not used to
claim timing closure.

| Metric | Result |
|---|---|
| Elaborated top | `mlkem768_top` PASS |
| Source files / declared modules | 114 / 116 |
| Yosys generic cells / hierarchy statistics | unavailable: Yosys absent |
| Mapped cells, area, sequential/combinational split | unavailable: mapper/library absent |
| Inferred memories / memory bits | unavailable: synthesis memory report absent |
| Mux/arithmetic resource counts | unavailable: Yosys absent |
| WNS/TNS, critical endpoints, Fmax | unavailable: no mapped timing run |
| Runtime/peak memory | no synthesis job launched |

The static hierarchy contains K-PKE controller workspaces, NTT/INTT banked
arrays, polynomial/polyvec buffers, codec/sampler storage, and Keccak state.
Their technology mapping is intentionally not inferred from source appearance.
The prepared generic flow performs hierarchy checking, `proc`, FSM processing,
memory processing, optimization, `techmap`, and hierarchical `stat` once
Yosys is installed.  The Genus flow requires `LIB_FILE` and reports area,
gates, timing, and mapped HDL on a suitable server.

This report makes no ASIC-area, achieved-Fmax, post-layout timing, or power
claim.
