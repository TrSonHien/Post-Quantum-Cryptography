# M2.2.4 Simulation Report: Pipelined Barrett Reduction

## Implementation Details

The module `barrett_reduce_pipe` was implemented as a 3-cycle pipelined Barrett reduction block:
*   **Target Modulus**: $q = 3329$
*   **Reciprocal constant**: $\mu = \lfloor 2^{48} / q \rfloor = 84552411147$
*   **Latency**: Fixed 3-cycle edge-to-edge latency ($L=3$).
*   **Initiation Interval**: $II=1$ (fully pipelined).
*   **Reset behavior**: Synchronous active-low reset `rst_n` clears valid pipeline registers only. Payload registers (e.g. products) are not reset to optimize area.

### Pipeline Stages and Widths
*   **Stage 1**: Computes full product $a \cdot \mu$ and registers it.
    *   *Inputs*: $a$ is 32-bit, $\mu$ is 37-bit.
    *   *Product width*: 69 bits, preserving full precision.
    *   Input $a$ is delayed by 1 stage.
*   **Stage 2**: Extracts quotient $quotient = \lfloor (a \cdot \mu) / 2^{48} \rfloor = \text{prod1}[68:48]$.
    *   *Quotient width*: 21 bits (minimum safe width for full 32-bit input space since max quotient is $1,290,167 < 2^{21}$).
    *   Computes and registers $prod2 = quotient \cdot q$.
    *   *prod2 width*: 33 bits, preserving full multiplication.
    *   Input $a$ is delayed by another stage.
*   **Stage 3**: Computes $remainder0 = a - prod2$.
    *   *Width*: 34-bit subtraction to safely prove non-negative remainder.
    *   Computes final output $r = (remainder0 \ge q) ? remainder0 - q : remainder0$ and registers it.

## Verification Summary

A self-checking testbench was created under `tb/unit/tb_barrett_reduce_pipe.v`.

The verification tests cover:
1.  **Directed Cases**: Edge values ($0$, $1$, $q-1$, $q$, $q+1$, $2 \cdot q - 1$, $2 \cdot q$, $16'\text{hFFFF}$, $32'\text{h7FFF\_FFFF}$, $32'\text{hFFFF\_FFFE}$, $32'\text{hFFFF\_FFFF}$).
2.  **Deterministic Random Cases**: 2,000 randomized full-range 32-bit inputs.
3.  **Pipeline Control**: Continuous execution ($II=1$), valid-bubbles, reset during active data propagation.
4.  **Alignment Checks**: Verification that `out_valid` is asserted exactly 3 cycles after `in_valid` and payload values align perfectly.
5.  **Golden Comparison**: Output checks against expected value $a \pmod q$ and $r < q$.

### Verification Results

All tests completed successfully:

```text
PASS tb_barrett_reduce_pipe  pass_count=2014  fail_count=0
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
PASS tb_mod_mul_pipe            pass_count=2009 fail_count=0
PASS tb_reduction               pass_count=618  fail_count=0
PASS tb_ntt_addr_gen            pass_count=1792 fail_count=0
PASS tb_zetas_rom               pass_count=16   fail_count=0
```

No timing success, area, or Fmax claims are made. Synthesis is deferred to M2.3.
