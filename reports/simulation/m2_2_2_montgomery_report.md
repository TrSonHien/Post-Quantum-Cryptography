# M2.2.2 Simulation Report: Pipelined Montgomery Reduction

## Implementation Details

The module `montgomery_reduce_pipe` was implemented as a 3-cycle pipelined Montgomery reduction block:
*   **Target Modulus**: $q = 3329$
*   **Scaling Constant**: $R = 2^{16}$
*   **Negative Modulo Inverse**: $q_{dash} = -q^{-1} \pmod R = 3327$
*   **Latency**: Fixed 3-cycle edge-to-edge latency ($L=3$).
*   **Initiation Interval**: $II=1$ (fully pipelined).
*   **Reset behavior**: Synchronous active-low reset `rst_n` clears valid pipeline shift registers only. Payload datapath registers are not reset to minimize gate area.

### Pipeline Stages
*   **Stage 1**: Computes $m = \text{low16}(a \cdot 3327)$ and registers it. Input $a$ is delayed by 1 stage.
*   **Stage 2**: Computes product $m \cdot q$ and registers it. Input $a$ is delayed by another stage.
*   **Stage 3**: Computes $sum = a + m \cdot q$, extracts $t = sum \gg 16$, performs a single conditional subtraction $t - q$, and registers output $r$.

## Verification Summary

A self-checking testbench was created under `tb/unit/tb_montgomery_reduce_pipe.v`.

The verification tests cover:
1.  **Directed Cases**: Edge values ($0$, $1$, $q-1$, $q$, $q+1$, $(q-1)^2$, and $q \cdot R - 1$).
2.  **Deterministic Random Cases**: 1,000 randomized valid inputs.
3.  **Pipeline Control**: Continuous execution ($II=1$), valid-bubbles, reset during active data propagation.
4.  **Alignment Checks**: Verification that `out_valid` is asserted exactly 3 cycles after `in_valid` and payload values align perfectly.
5.  **Golden Comparison**: Output checks against the mathematical equivalence relation $(r \cdot 2^{16}) \pmod q == a \pmod q$ and $r < q$.

### Verification Results

All tests completed successfully:

```text
PASS tb_montgomery_reduce_pipe  pass_count=1010  fail_count=0
```

### Regressions
Adjacent M2.1 primitives, M2.2.1 arithmetic, and legacy regressions were run to ensure zero functional impact:
```text
PASS tb_sync_1r1w_ram           pass_count=515  fail_count=0
PASS tb_sync_1r1w_ram_collision expected assertion observed
PASS tb_ntt_pingpong_banks      pass_count=4866 fail_count=0
PASS tb_pipeline_control        pass_count=35   fail_count=0
PASS tb_mod_add_pipe            pass_count=149236 fail_count=0
PASS tb_mod_sub_pipe            pass_count=149236 fail_count=0
PASS tb_reduction               pass_count=618  fail_count=0
PASS tb_mod_mul                 pass_count=1010 fail_count=0
```

No timing success, area, or Fmax claims are made. Synthesis is deferred to M2.3.
