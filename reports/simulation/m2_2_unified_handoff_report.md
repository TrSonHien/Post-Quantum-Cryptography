# M2.2 Unified Arithmetic Pipeline Handoff Report

## Executive Summary

Milestone M2.2 implements, verifies, and freezes the pipelined arithmetic blocks required for the banked NTT/INTT engines (M3) and polynomial multipliers (M4). All modules use a valid-only timing-aligned pipeline interface supporting an initiation interval of $II=1$ with no internal backpressure. Valid flags are delayed internally by the exact module latency. Associated metadata is external to these arithmetic modules and must be delayed by the caller using fixed_latency_delay or similar primitives. Reset clears valid status registers only, while data payloads are unreset to optimize ASIC gate area and routing congestion.

All new modules were verified via self-checking testbenches comparing outputs against golden mathematical equivalents in Verilog. An all-pass regression run was completed, showing zero functional regression on any previously verified primitives (M2.1) or legacy models.

---

## Arithmetic Candidate Summary

| Top Name | Mathematical Operation | Input/Output Range | Domain Semantics | Latency ($L$) | II | Instantiated Dependencies | Expected ASIC Critical Path |
| :--- | :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `mod_add_pipe` | $r = (a + b) \pmod q$ | In: $[0, q-1]$<br>Out: $[0, q-1]$ | Normal or NTT | 1 | 1 | None | 13-bit adder $\rightarrow$ 13-bit subtractor $\rightarrow$ 2:1 mux |
| `mod_sub_pipe` | $r = (a - b) \pmod q$ | In: $[0, q-1]$<br>Out: $[0, q-1]$ | Normal or NTT | 1 | 1 | None | 13-bit subtractor $\rightarrow$ 13-bit adder $\rightarrow$ 2:1 mux |
| `montgomery_reduce_pipe` | $r = a \cdot R^{-1} \pmod q$ | In: $[0, q \cdot R - 1]$<br>Out: $[0, q-1]$ | In: Montgomery intermediate<br>Out: Canonical normal or NTT | 3 | 1 | None | Stage 2: $16 \times 12$ constant multiplier and 32-bit adder |
| `mod_mul_pipe` | $r = a \cdot b \cdot R^{-1} \pmod q$ | In: $[0, q-1]$<br>Out: $[0, q-1]$ | In: Normal or Montgomery domain<br>Out: Montgomery-scaled (Normal if one input scaled) | 4 | 1 | `montgomery_reduce_pipe` | Stage 1: $12 \times 12$ multiplier |
| `barrett_reduce_pipe` | $r = a \pmod q$ | In: $[0, 2^{32}-1]$<br>Out: $[0, q-1]$ | In: Wide Normal<br>Out: Canonical Normal | 3 | 1 | None | Stage 1: $32 \times 37$ constant multiplier |
| `butterfly_pipe` | $t = \zeta_{mont} \cdot v \cdot R^{-1} \pmod q$<br>$out0 = u + t \pmod q$<br>$out1 = u - t \pmod q$ | In: $[0, q-1]$<br>Out: $[0, q-1]$ | In/Out: NTT domain<br>$\zeta_{mont}$: Montgomery-scaled | 5 | 1 | `mod_mul_pipe`<br>`fixed_latency_delay`<br>`mod_add_pipe`<br>`mod_sub_pipe` | `mod_mul_pipe` multipliers (Stages 1-4) $\rightarrow$ adder/subtractor (Stage 5) |
| `intt_butterfly_pipe` | $sum = u + v \pmod q$<br>$diff = v - u \pmod q$<br>$out0 = sum$<br>$out1 = \zeta_{mont} \cdot diff \cdot R^{-1} \pmod q$ | In: $[0, q-1]$<br>Out: $[0, q-1]$ | In/Out: NTT domain<br>$\zeta_{mont}$: Montgomery-scaled | 5 | 1 | `mod_add_pipe`<br>`mod_sub_pipe`<br>`mod_mul_pipe`<br>`fixed_latency_delay` | Stage 1 adder/subtractor $\rightarrow$ `mod_mul_pipe` multipliers (Stages 2-5) |

*Note: For all blocks, $q = 3329$, $R = 2^{16}$, and $R^{-1} \pmod q = 169$.*

---

## Verification and Contract Compliance

### 1. Latency & II Alignment
*   Every pipeline stage is validated to compile, run, and present outputs on the exact clock edge defined in the respective contract.
*   Initiation Interval ($II=1$) was verified under continuous input transactions for all units.
*   Valid-only pipeline interface propagation has been verified to be empty after deasserting reset.

### 2. Reset Behavior
*   Active-low synchronous reset `rst_n` clears only control registers (`val_d1`, `val_d2`, and `out_valid`).
*   Intermediate payload registers are left unreset. Testbenches confirm that invalid datapath bubbles do not pollute active transactions or trigger simulation checks.

### 3. Domain & Montgomery Semantics Consistency
*   All Montgomery multiplication/reduction comments and interface specifications are aligned.
*   `zeta_mont` is explicitly documented as a Montgomery-scaled coefficient ($\zeta \cdot R \pmod q$) in both forward and inverse butterfly modules.
*   The forward NTT butterfly computes $t = \zeta \cdot v \pmod q$, then $out0 = u+t \pmod q$ and $out1 = u-t \pmod q$.
*   The inverse NTT butterfly computes $sum = u+v \pmod q$, $diff = v-u \pmod q$, then $out0 = sum$ and $out1 = \zeta \cdot (v-u) \pmod q$. No unauthorized subtraction order changes were made.
*   Both forward and inverse butterfly units exhibit a valid latency of exactly 5 clock cycles, verified using aligned testbench pipeline delay registers. Callers must delay associated metadata externally by exactly 5 cycles to maintain alignment.

---

## Unified Test Log

The unified regression script `sim/scripts/run_m2_2_regression.sh` successfully executed the following test suite:

```text
PASS run_m2_1_primitives:
  - tb_sync_1r1w_ram           pass_count=515  fail_count=0
  - tb_sync_1r1w_ram_collision expected assertion observed
  - tb_ntt_pingpong_banks      pass_count=4866 fail_count=0
  - tb_pipeline_control        pass_count=35   fail_count=0
PASS tb_mod_add_pipe           pass_count=149236 fail_count=0
PASS tb_mod_sub_pipe           pass_count=149236 fail_count=0
PASS tb_montgomery_reduce_pipe pass_count=1010 fail_count=0
PASS tb_mod_mul_pipe           pass_count=2009 fail_count=0
PASS tb_barrett_reduce_pipe    pass_count=2014 fail_count=0
PASS tb_butterfly_pipe         pass_count=2006 fail_count=0
PASS tb_intt_butterfly_pipe    pass_count=2007 fail_count=0
```

And adjacent legacy regressions:
```text
PASS tb_ntt_core               pass_count=512  fail_count=0
PASS tb_intt_core              pass_count=768  fail_count=0
PASS tb_ntt_intt_roundtrip     pass_count=1024 fail_count=0
PASS tb_poly_add               pass_count=1024 fail_count=0
PASS tb_poly_sub               pass_count=1024 fail_count=0
PASS tb_poly_basemul_montgomery pass_count=768 fail_count=0
PASS tb_basemul_unit           pass_count=514  fail_count=0
```
