# M8.1 Zeroization Development Report

The corrected focused test set passes M8-owned scrub checks across fixed
buffers, layout storage, check storage, compare/select storage, wrappers, and
distributed completion control.  M5 H/G/J explicit zeroize clears both
1600-bit sponge/permutation states and staging payload; the M5 focused
regression passes 16/16 with unchanged ordinary digests.  M7 controller-owned
arrays pass 21,408 location checks and ordinary M7 Algorithms 13--15 remain
passing.

Bottom-up hierarchical destruction is closed. M6 codec/sampler services and
M7 K-PKE controllers propagate explicit requests and wait for child
acknowledgements. M8 internal controllers scan 11,970 local retained locations;
public wrappers scan 4,768 entropy/input locations; all H/G/J and K-PKE child
completion events are joined before normal or zeroize completion.

The unified top no longer pulses a private reset. It issues one-cycle scrub
requests to all three public wrappers, latches acknowledgements, and performs a
mandatory boot scrub after reset. `cmd_ready` remains low during boot scrub.
Reset interruption retains a not-yet-scanned final DK byte, proving reset is
not payload erase; the restarted boot scrub subsequently clears that byte.

`tb/system/tb_mlkem768_top.v` passes 33,511 automatic, explicit, abort, reset,
and boot-scrub observations, including full M8 local arrays and representative
M7 workspace, NTT bank, sampler, codec, and M5 sponge state. The focused M8
regression passes 21/21 with 64,505 zeroize checks. The machine-readable
manifest maps 4,190 elaborated state objects and reports zero uncovered entries.
