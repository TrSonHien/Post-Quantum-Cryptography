# M9.0 Repository and Release Audit

Date: 2026-07-17.  Audited checkout: `test` at
`5617e42e221fd21f28219423fbbeb187bfbdcd76` before M9 changes.

## Result

The intended release top is `mlkem768_top` in `rtl/mlkem/mlkem768_top.v`.
The checkout was clean, the branch was correct, and no `vvp`, `iverilog`,
`yosys`, `genus`, or release-run process was active.  The separate frozen
comparison worktree `/home/hien/Projects/PQC_main` was listed but not touched.

## Hierarchy and sources

- Dedicated M9 source list: `synth/m9/rtl.f`.
- 114 synthesizable Verilog source files and 116 declared modules are listed.
- The sole project include dependency used by the file list is
  `rtl/common/kyber_params.vh`, supplied through `-Irtl/common`.
- The list contains no `tb/`, generated-vector, report, reference-model, or
  waveform path; the runner validates existence and duplicate entries.
- Complete hierarchy elaboration resolves `mlkem768_top`; no black box,
  unresolved module, duplicate definition, or missing include was reported.

The hierarchy has a single `clk` port and no generated-clock interface.
`rst_n` is synchronous active-low reset at the top and throughout the released
control style.  Parameterization is Verilog parameter/generate based; the
ML-KEM-768 constants are supplied by `kyber_params.vh`.  No synthesis blocker
from simulation-only behavior was observed by the available elaborators.

## Stateful structures and release assumptions

The hierarchy contains register-array/workspace structures in K-PKE
KeyGen/Encrypt/Decrypt, NTT/INTT banked workspaces, polynomial/polyvec
workspaces, codecs, samplers, and Keccak state/stream wrappers.  Their exact
RAM-versus-flip-flop implementation is technology/tool dependent and is not
claimed until a synthesis tool reports it.  M8-local explicit-zeroize and
child requests already present in the RTL are retained; M9 does not extend
physical scrubbing through every lower-level payload array.

## Available tools and blockers

| Tool | Availability | Use in this audit |
|---|---|---|
| Verilator 5.048 | available | lint-only hierarchy elaboration |
| Icarus Verilog 13.0 | available | independent elaboration |
| Yosys | absent | generic synthesis blocked |
| Cadence Genus | absent | mapped synthesis blocked |
| Liberty/technology library | none locally configured | mapped synthesis blocked |

There is no local `.lib`, `.db`, or technology setup usable by M2.3b or the
full top.  The exact later-server entry points are
`LIB_FILE=/path/to/stdcell.lib synth/m2_3/run_synth_sweep.sh` and
`LIB_FILE=/path/to/stdcell.lib synth/m9/run_genus.sh` from the repository root.
The M9 Yosys runner is `synth/m9/run_yosys.sh` when Yosys becomes available.
