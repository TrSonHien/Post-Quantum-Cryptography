# M9.4 Baseline Bottleneck Analysis

## Evidence boundary

M9 elaboration proves the full hierarchy; Yosys, Genus, and a technology
library are unavailable locally.  Consequently no numerical area, register,
memory-bit, mux, or critical-depth contribution is available.  The ranking
below is a structural provisional ranking from the elaborated hierarchy and
the documented controller/workspace ownership, not an ASIC area ranking.

| Rank | Block | Structural evidence | Instance/resource observation | Risk / recommendation |
|---:|---|---|---|---|
| 1 | M8 public wrappers plus K-PKE KeyGen/Encrypt/Decrypt | `mlkem768_top` structurally owns all three public operation paths; each reaches a K-PKE controller and byte storage. | Controllers are present concurrently in hierarchy rather than time-shared. | Medium-risk sharing could help area but changes control ownership; defer. |
| 2 | Keccak H/G/J and sponge/permutation state | KeyGen/Encaps/Decaps each require hash services and stateful byte-stream wrappers. | Stateful 1600-bit permutation and wrapper buffers occur under several paths. | Medium-risk service sharing; defer because it changes operation scheduling. |
| 3 | NTT/INTT cores and banked polynomial workspaces | K-PKE paths reach M3/M4 NTT/INTT adapters, bank maps, and coefficient workspaces. | Large indexed coefficient arrays and arithmetic pipes dominate likely sequential/storage resources. | High-risk architectural redesign; await mapped reports. |
| 4 | Polyvec and codec pack/unpack buffers | Public records translate between 1184/2400/1088-byte streams and polynomial data. | Wide byte buffers, counters, compare logic, and generated codec alternatives are present. | Low-risk future cleanup: explicit parameter widths after differential proof. |
| 5 | SampleNTT and CBD/noise sampling | KeyGen and Encrypt instantiate matrix/noise orchestration with SHAKE and coefficient storage. | Variable-rate sampling and rejection/control counters add mux/control depth. | Medium-risk resource sharing; retain validated behavior. |

## Required observations once synthesis is available

For each rank, capture hierarchical area, sequential cells, inferred memory
bits, arithmetic/mux counts, and the endpoint of the critical path.  Determine
whether arrays infer RAM or flip-flops in the actual library before selecting
an optimization.

## Optimization disposition

- A. Low-risk structural cleanup: explicit constant/boolean widths in selected
  codec/workspace control logic, only after a focused differential check.
- B. Medium-risk resource sharing: Keccak or K-PKE controller sharing across
  operations.  Do not implement during M9.
- C. High-risk architectural redesign: NTT/workspace banking or controller
  duplication changes.  Do not implement during M9.

No optimization was implemented because no mapped evidence demonstrates a
clear benefit, and the release priority is preserved functional correctness.
