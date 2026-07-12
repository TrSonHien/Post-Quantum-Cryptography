# M2.2.3 Simulation Report: Pipelined Montgomery Multiplication

## Implementation Details

The module `mod_mul_pipe` was implemented as a 4-cycle pipelined Montgomery multiplication block:
*   **Mathematical Operation**: $r = a \cdot b \cdot R^{-1} \pmod q$, where $q = 3329$, $R = 2^{16}$, and $R^{-1} \pmod q = 169$.
*   **Semantic Warning**: This module does NOT compute ordinary canonical modular multiplication ($a \cdot b \pmod q$). It computes Montgomery-scaled multiplication.
*   **Latency**: Fixed 4-cycle edge-to-edge latency ($L=4$).
*   **Initiation Interval**: $II=1$ (fully pipelined).
*   **Reset behavior**: Synchronous active-low reset `rst_n` clears valid pipeline registers only. Payload registers (such as the multiplier output) are not reset to optimize area.

### Pipeline Stages
*   **Stage 1**: Multiplies 12-bit canonical inputs $a$ and $b$ to produce a 24-bit product `prod_s1`, and registers it alongside the input valid state.
*   **Stages 2-4**: Feeds `prod_s1` (zero-extended to 32 bits) into the verified `montgomery_reduce_pipe` sub-module, which completes reduction over 3 stages.

## Verification Summary

A self-checking testbench was created under `tb/unit/tb_mod_mul_pipe.v`.

The verification tests cover:
1.  **Directed Cases**: Edge values ($0 \times 0$, $0 \times (q-1)$, $1 \times 1$, $1 \times (q-1)$, $(q-1) \times (q-1)$), and representative values near $q/2$.
2.  **Deterministic Random Cases**: 2,000 randomized canonical inputs.
3.  **Pipeline Control**: Continuous execution ($II=1$), valid-bubbles, reset during active data propagation.
4.  **Alignment Checks**: Verification that `out_valid` is asserted exactly 4 cycles after `in_valid` and payload values align perfectly.
5.  **Golden Comparison**: Output checks against expected value $(a \cdot b \cdot 169) \pmod q$ and $r < q$.

### Verification Results

All tests completed successfully:

```text
PASS tb_mod_mul_pipe  pass_count=2009  fail_count=0
```

### Regressions
Adjacent M2.1 primitives, M2.2 arithmetic, and legacy regressions were run to ensure zero functional impact:
```text
PASS tb_sync_1r1w_ram           pass_count=515  fail_count=0
PASS tb_sync_1r1w_ram_collision expected assertion observed
PASS tb_ntt_pingpong_banks      pass_count=4866 fail_count=0
PASS tb_pipeline_control        pass_count=35   fail_count=0
PASS tb_mod_add_pipe            pass_count=149236 fail_count=0
PASS tb_mod_sub_pipe            pass_count=149236 fail_count=0
PASS tb_montgomery_reduce_pipe  pass_count=1010 fail_count=0
PASS tb_reduction               pass_count=618  fail_count=0
PASS tb_mod_mul                 pass_count=1010 fail_count=0
PASS tb_ntt_addr_gen            pass_count=1792 fail_count=0
PASS tb_zetas_rom               pass_count=16   fail_count=0
```

No timing success, area, or Fmax claims are made. Synthesis is deferred to M2.3.
