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

## 3. Simulation Logs
```text
INFO tb_ntt_scheduler_pipe: starting exhaustive execution check
INFO tb_ntt_scheduler_pipe: testing start-while-busy error
INFO tb_ntt_scheduler_pipe: testing illegal stage-advance error
INFO tb_ntt_scheduler_pipe: testing reset from active issue
PASS tb_ntt_scheduler_pipe
```
