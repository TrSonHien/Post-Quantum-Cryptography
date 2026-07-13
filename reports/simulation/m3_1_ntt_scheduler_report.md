# M3.1 Forward NTT Address Scheduler Simulation Report

## 1. Overview
The Fmax-oriented forward NTT address scheduler `ntt_scheduler_pipe` implements the 7-stage radix-2 Cooley-Tukey NTT address generator with an initiation interval ($II$) of 1. It schedules the read and write bank/address mappings dynamically using the `ntt_bank_map` primitive.

## 2. Verification Results
Exhaustive verification of `ntt_scheduler_pipe` was performed using the self-checking testbench `tb_ntt_scheduler_pipe`.

- **Exhaustive Address Generation**: Verified 896 butterfly requests (7 stages $\times$ 128 butterflies/stage).
- **Zeta/Twiddle Factors**: Verified that twiddle ROM addresses sweep the correct stages ($1$ to $127$) and remain constant inside each butterfly group.
- **Stage Advances**: Verified FSM wait states and correct stage transitions via external `stage_advance` pulses.
- **Bank Mapping**: Verified that all source memory reads are conflict-free.
- **Robust Error Handling**: Verified that illegal events (`start` while busy, `stage_advance` outside wait state) set the `error` output.
- **Reset Controls**: Verified that synchronous active-low `rst_n` clears state machines and control outputs from any active state.

All **896 checks passed successfully**.

## 2.1 M3.2 addendum

During M3.2 integration, the core-level destination write checks exposed a
stale transition-layout bug in the scheduler metadata. The original M3.1
implementation used constant `r=7` destination layouts and the M3.1 unit test
checked source-bank collisions but not destination-bank collisions. The first
failing transaction was stage 1, group 0, butterfly 0:

```text
idx0=0 idx1=64 layout p=5 r=7 xor=1 -> both destination bank 0
```

The scheduler now follows the approved transition table from
`docs/03_architecture/ntt_architecture.md`:

```text
Stage 0: b=i7        a=rm7 -> b=i7^i6 a=rm6
Stage 1: b=i7^i6     a=rm6 -> b=i6^i5 a=rm5
Stage 2: b=i6^i5     a=rm5 -> b=i5^i4 a=rm4
Stage 3: b=i5^i4     a=rm4 -> b=i4^i3 a=rm3
Stage 4: b=i4^i3     a=rm3 -> b=i3^i2 a=rm2
Stage 5: b=i3^i2     a=rm2 -> b=i2^i1 a=rm1
Stage 6: b=i2^i1     a=rm1 -> b=i1    a=rm1
```

`tb_ntt_scheduler_pipe` now checks destination-bank collisions in addition to
source-bank collisions. The updated regression passes under:

```text
timeout 30s ./sim/scripts/run_ntt_scheduler_pipe.sh
PASS tb_ntt_scheduler_pipe
```

## 3. Simulation Logs
```text
INFO tb_ntt_scheduler_pipe: starting exhaustive execution check
INFO tb_ntt_scheduler_pipe: testing start-while-busy error
INFO tb_ntt_scheduler_pipe: testing illegal stage-advance error
INFO tb_ntt_scheduler_pipe: testing reset from active issue
PASS tb_ntt_scheduler_pipe
```
