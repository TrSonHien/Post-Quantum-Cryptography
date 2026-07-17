# M9.1 Lint and Elaboration Report

Date: 2026-07-17.  Top: `mlkem768_top`.  Source list: 114 RTL files.

## Commands and outcome

`sim/scripts/run_m9_elaboration.sh` ran with hard 600-second limits per tool:

```text
verilator --lint-only --timing -Wall -Wno-fatal -DSYNTHESIS -Irtl/common \
  --top-module mlkem768_top -f synth/m9/rtl.f
iverilog -g2012 -DSYNTHESIS -I rtl/common -s mlkem768_top -tnull \
  -f synth/m9/rtl.f
```

Both tools passed.  The file-list validation also passed: all 114 files exist,
none is duplicated, and no testbench path is listed.  This establishes complete
synthesizable hierarchy elaboration, not technology-mapped timing closure.

## Warning classification

| Class | Count | Disposition |
|---|---:|---|
| A functional/synthesis blocker | 0 | None found. |
| B likely bug | 0 | None found after hierarchy and existing M8 differential evidence. |
| C portability/width debt | 113 Verilator width notices; 91 Icarus port-width notices | Documented; no broad behavior-changing cleanup in M9. |
| D intentional/acceptable | 481 Verilator unused/empty-pin/parameter/file-name notices | Generated inactive codec branches, intentionally unconnected optional outputs, and shared source-file modules. |
| E tool limitation/style | 37 Verilator procedural-style/name notices | `BLKSEQ`, unnamed generate blocks, and one lexical name-hiding notice. |

Verilator emitted 631 nonfatal warnings: 386 `UNUSEDSIGNAL`, 80
`PINCONNECTEMPTY`, 73 `WIDTHTRUNC`, 40 `WIDTHEXPAND`, 30 `BLKSEQ`, 11
`UNDRIVEN`, 6 `GENUNNAMED`, 3 `UNUSEDPARAM`, and one each of `VARHIDDEN` and
`DECLFILENAME`.  The 11 `UNDRIVEN` wires occur in inactive parameter-generate
branches of `polyvec_codec_pipe`; active alternative branches drive the live
interface.  Icarus emitted 91 width-pruning notices caused chiefly by legacy
unsized constants on workspace-control ports.

No RTL was changed: the warnings are known portability/style debt, and fixing
them comprehensively would touch verified M2--M7 datapaths without synthesis
evidence of a functional or resource benefit.  The range-guarded wide scrub
indices are also intentional selected-clear controls, not out-of-range accesses.

## Remaining warnings

The release accepts these warnings only as documented academic RTL debt.
Future work should make widths and boolean parameters explicit, split inactive
generate interfaces where useful, and rerun differential tests before claiming
strict lint cleanliness.  No latch, multiple-driver, combinational-loop,
missing-include, duplicate-module, or unresolved-module warning was reported.
