# M2.2.1 Simulation Report: Pipelined Modular Addition and Subtraction

## Implementation Details

The modules `mod_add_pipe` and `mod_sub_pipe` were implemented as pipelined modular arithmetic operations:
*   **Target Modulus**: $q = 3329$ (canonical unsigned values in $[0, 3328]$).
*   **Latency**: Fixed 1-cycle latency ($L=1$).
*   **Initiation Interval**: $II=1$ (fully pipelined).
*   **Reset behavior**: Synchronous active-low reset `rst_n` clears `out_valid` only. Payload data registers are not reset to optimize routing and cell area.
*   **Interface**: Valid-only interface (`in_valid`, `out_valid`) without ready/backpressure signals inside the pipeline.

## Verification Summary

Two self-checking testbenches were created under `tb/unit/`:
*   `tb_mod_add_pipe.v`
*   `tb_mod_sub_pipe.v`

The verification tests cover:
1.  **Directed Cases**: Edge values ($0$, $q-1$), equal operands, addition crossing modulus ($q$), subtraction underflow.
2.  **Exhaustive Stepped Cases**: Nested loop combinations of $a \in [0, 3328]$ (step 7) and $b \in [0, 3328]$ (step 11) to check mathematical coverage.
3.  **Random Cases**: 5,000 randomized canonical input pairs.
4.  **Pipeline Control**: Continuous execution ($II=1$), valid-bubbles (alternating valid/invalid states), reset during active data propagation.
5.  **Alignment Checks**: Verification that `out_valid` is asserted exactly 1 cycle after `in_valid` and payload values align perfectly.
6.  **Independent Oracle Comparison**: Output checks against an independent Verilog golden mathematical function.

### Verification Results

All tests completed successfully:

```text
PASS tb_mod_add_pipe  pass_count=149236  fail_count=0
PASS tb_mod_sub_pipe  pass_count=149236  fail_count=0
```

### Regressions
Adjacent M2.1 primitives and legacy module regressions were run to ensure zero functional impact:
```text
PASS tb_sync_1r1w_ram           pass_count=515  fail_count=0
PASS tb_sync_1r1w_ram_collision expected assertion observed
PASS tb_ntt_pingpong_banks      pass_count=4866 fail_count=0
PASS tb_pipeline_control        pass_count=35   fail_count=0
PASS tb_mod_add                 pass_count=1009 fail_count=0
PASS tb_mod_sub                 pass_count=1012 fail_count=0
PASS tb_reduction               pass_count=618  fail_count=0
PASS tb_mod_mul                 pass_count=1010 fail_count=0
```

No timing success, area, or Fmax claims are made. Synthesis is deferred to M2.3.
