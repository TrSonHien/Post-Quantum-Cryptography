# M3.2 Banked Pipelined Forward NTT Core Report

## 1. Architecture summary

M3.2 adds `ntt_core_pipe`, a banked out-of-place forward NTT core candidate.
It integrates the M3.1 scheduler, M2.1 ping-pong synchronous memory banks,
M2.2 `butterfly_pipe`, `fixed_latency_delay`, and the existing forward
`zetas_rom`. The core issues one butterfly read request per cycle while the
scheduler is active and drains each stage before swapping source/destination
roles.

No synthesis, post-route timing, or Fmax claim is made.

## 2. External interface

Control:

```text
clk
rst_n                  synchronous active-low reset
start
busy
done                   one-cycle pulse after final stage swap
error                  sticky until reset
```

Preload:

```text
preload_en
preload_idx[7:0]
preload_coeff[11:0]
preload_ready
```

Preload is legal only while idle. Coefficients are loaded as lower/upper pairs:
index `0..127` must be loaded before its matching index `128..255`.
The preload path writes the initial boundary layout `b=i7, a=rm7` into the
inactive destination role; the core performs one idle pre-start role swap before
scheduling.

Result read:

```text
result_rd_req
result_rd_idx[7:0]
result_rd_valid
result_rd_data[11:0]
```

Result reads are legal only while idle after a completed transform. Start,
preload, or result-read requests while busy set `error`. Result reads before a
completed transform set `error`.

## 3. Measured timing

The actual RTL latency table from nonblocking assignment semantics is:

| Event | Edge relative to accepted scheduler request |
|---|---:|
| Source RAM read request sampled | M |
| Source RAM data and valid visible | M+1 |
| Butterfly input sampled | M+1 |
| Butterfly output and write metadata visible | M+6 |
| Destination RAM write committed | M+7 |
| Stage drain detected | M+7 |
| Safe role-swap / scheduler stage-advance edge | M+9 |

Named localparams in the core:

```text
RAM_READ_LATENCY      = 1
BUTTERFLY_LATENCY     = 5
ISSUE_TO_WRITE_SETUP  = 6
ISSUE_TO_WRITE_COMMIT = 7
```

## 4. Stage and transform timeline

Each stage issues 128 butterfly transactions. The verified start-to-done
cycle count is 955 cycles for every tested polynomial. Per transform:

```text
accepted pair-read requests: 896
RAM responses:              896
butterfly inputs:           896
butterfly outputs:          896
committed pair writes:      896
stage drains:               7
stage role swaps:           7
scheduler stage advances:   7
total role swaps:           8 including the idle pre-start preload-role swap
```

## 5. Layout and zeta alignment

The core uses the corrected forward transition table from
`docs/03_architecture/ntt_architecture.md`:

```text
Stage 0: b=i7    a=rm7 -> b=i7^i6 a=rm6
Stage 1: b=i7^i6 a=rm6 -> b=i6^i5 a=rm5
Stage 2: b=i6^i5 a=rm5 -> b=i5^i4 a=rm4
Stage 3: b=i5^i4 a=rm4 -> b=i4^i3 a=rm3
Stage 4: b=i4^i3 a=rm3 -> b=i3^i2 a=rm2
Stage 5: b=i3^i2 a=rm2 -> b=i2^i1 a=rm1
Stage 6: b=i2^i1 a=rm1 -> b=i1    a=rm1
```

The final result layout is `b=i1, a=rm1`. The result-read path reconstructs
logical coefficient order from that layout.

Zeta data is sampled from the combinational ROM at issue and delayed by the
one-cycle RAM read latency. The zeta associated with request N is therefore
sampled by the butterfly with request N's source coefficients.

## 6. Metadata and pending accounting

Destination index, layout, scheduler physical bank/address metadata, stage,
butterfly index, group index, zeta index, and last markers are delayed by
`ISSUE_TO_WRITE_SETUP=6` cycles. Simulation assertions check that delayed
metadata valid matches butterfly output valid and that delayed physical
destination metadata matches the active layout map.

Pending traffic counters increment/decrement on:

```text
pending_reads:       read request accepted / RAM response valid
pending_butterflies: butterfly input valid / butterfly output valid
pending_writes:      write setup valid / write commit valid
```

Stage advance is allowed only when the committed write corresponding to
`last_issue_in_stage` is observed and all pending counters drain to zero.

## 7. Previous deadlock/root cause

The recovered Antigravity stash contained only three untracked files:

```text
rtl/ntt/ntt_core_pipe.v
tb/block/tb_ntt_core_pipe.v
sim/scripts/run_ntt_core_pipe.sh
```

It timed out under:

```text
timeout 30s ./sim/scripts/run_ntt_core_pipe.sh
exit_status=124
```

The attempt had no useful watchdog dump. Root cause from reconstruction:

- it used a guessed metadata delay and swapped roles on the same cycle as a
  write-valid event;
- it did not track pending read/butterfly/write traffic;
- it recomputed stale layout parameters with constant `r=7`;
- the M3.1 scheduler metadata also used the same stale destination layout, and
  its unit test checked source-bank collisions but not destination-bank
  collisions.

The first concrete divergence after adding M3.2 checking was:

```text
stage=1 group=0 bfly=0 idx0=0 idx1=64 layout p=5 r=7 xor=1 -> both bank 0
```

This contradicted the approved architecture proof. The scheduler and core now
use `current_pair_bit/next_pair_bit` transition layouts, and the scheduler test
checks destination-bank collisions.

## 8. Vector source and coverage

Vectors are generated by `tb/tools/gen_ntt_core_pipe_vectors.py`, which imports
the existing independent Python model `ref_model.python_model.ntt.ntt` and does
not alter golden-model semantics. The generated readmemh file is written under
`sim/outputs/` at test time.

Coverage:

```text
zero polynomial
impulse at index 0
impulse at index 1
impulse at index 127
impulse at index 128
impulse at index 255
all coefficients q-1
deterministic incrementing/repeating pattern
20 deterministic random polynomials
```

Total tested polynomials: 28.
Total coefficient comparisons: 7168.

## 9. Control/error verification

The bounded testbench verifies:

```text
start while busy
preload while busy
result read while busy
reset during issue
reset during pipeline drain
reset immediately before role swap
reset during final stage
successful restart after reset cases
bounded watchdog with state dump
```

All control/error tests passed.

## 10. Regression results

```text
timeout 30s ./sim/scripts/run_ntt_scheduler_pipe.sh
PASS tb_ntt_scheduler_pipe

timeout 30s ./sim/scripts/run_ntt_core_pipe.sh
PASS tb_ntt_core_pipe
tested_polynomials=28 coefficient_checks=7168 transform_cycles=955

timeout 60s ./sim/scripts/run_m2_2_regression.sh
PASS M2.1 primitives and all M2.2 pipelined arithmetic blocks

timeout 60s legacy adjacency command set
PASS tb_ntt_core
PASS tb_intt_core
PASS tb_ntt_intt_roundtrip
PASS tb_poly_add
PASS tb_poly_sub
PASS tb_basemul_unit
PASS tb_poly_basemul_addr_gen
PASS tb_poly_basemul_montgomery

timeout 30s python3 -m ref_model.python_model.selftest
PASS

timeout 30s python3 -m ref_model.python_model.test_foundations
PASS 13 tests

timeout 30s python3 -m ref_model.compare.test_compare_tools
PASS 5 tests

timeout 30s python3 -m ref_model.compare.generate_vectors --output /tmp/mlkem768_smoke_check.json
PASS

timeout 30s python3 -m ref_model.compare.compare_vectors ref_model/compare/vectors/mlkem768_smoke.json /tmp/mlkem768_smoke_check.json
PASS: vector documents match exactly
```

`python3 -m pytest ...` was attempted but `pytest` is not installed in this
environment; the same tests were run directly through `unittest`.

## 11. Known limitations

- M2.3b server synthesis remains pending.
- The preload interface is pair-ordered and intended for M3.2 block testing.
- The core is forward NTT only; inverse NTT, final INTT scaling, and M3.3 are
  not implemented here.
- No synthesis, timing, area, power, post-route, or Fmax claim is made.
