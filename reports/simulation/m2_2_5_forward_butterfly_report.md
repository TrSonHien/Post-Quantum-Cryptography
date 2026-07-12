# M2.2.5 Simulation Report: Pipelined Forward NTT Butterfly

## Implementation Details

The module `butterfly_pipe` was implemented as a 5-cycle pipelined forward NTT butterfly block:
*   **Target Modulus**: $q = 3329$
*   **Domain Representation**: Inputs $u$ and $v$ are in the NTT domain. The coefficient $zeta\_mont$ is in the Montgomery domain, scaled by $R \pmod q$ ($zeta\_mont = \zeta \cdot R \pmod q$). The intermediate $t$ is computed via Montgomery reduction to resolve this scaling. Outputs $out0, out1$ are in the NTT domain.
*   **Latency**: Fixed 5-cycle edge-to-edge latency ($L=5$).
*   **Initiation Interval**: $II=1$ (fully pipelined).
*   **Reset behavior**: Synchronous active-low reset `rst_n` clears valid/control registers only. Datapath payload registers are not reset to optimize routing and cell area.

### Pipeline Stages
*   **Stages 1-4**: Multiplies inputs $zeta\_mont$ and $v$ and reduces the result using the verified 4-cycle `mod_mul_pipe` block. Simultaneously, input $u$ is delayed by 4 stages using the verified `fixed_latency_delay` primitive.
*   **Stage 5**: Computes output $out0 = (u_{delayed} + t) \pmod q$ and $out1 = (u_{delayed} - t) \pmod q$ in parallel using the verified 1-cycle `mod_add_pipe` and `mod_sub_pipe` blocks.

## Verification Summary

A self-checking testbench was created under `tb/unit/tb_butterfly_pipe.v`.

The verification tests cover:
1.  **Directed Cases**: Edge values ($0$, $1$, $q-1$), using representative Montgomery zetas from the forward NTT ROM (2285, 2571, 2970).
2.  **Deterministic Random Cases**: 2,000 randomized canonical inputs for $u$, $v$, and $zeta\_mont$.
3.  **Pipeline Control**: Continuous execution ($II=1$), valid-bubbles, reset during active data propagation.
4.  **Alignment Checks**: Verification that `out_valid` is asserted exactly 5 cycles after `in_valid` and payload values align perfectly.
5.  **Golden Comparison**: Output checks against expected values:
    *   $t_{expected} = (zeta\_mont \cdot v \cdot 169) \pmod q$
    *   $out0_{expected} = (u + t_{expected}) \pmod q$
    *   $out1_{expected} = (u + q - t_{expected}) \pmod q$

### Verification Results

All tests completed successfully:

```text
PASS tb_butterfly_pipe  pass_count=2006  fail_count=0
```

### Regressions
Adjacent M2.1 primitives, M2.2 arithmetic, legacy, and roundtrip regressions were run to ensure zero functional impact:
```text
PASS tb_sync_1r1w_ram           pass_count=515  fail_count=0
PASS tb_sync_1r1w_ram_collision expected assertion observed
PASS tb_ntt_pingpong_banks      pass_count=4866 fail_count=0
PASS tb_pipeline_control        pass_count=35   fail_count=0
PASS tb_mod_add_pipe            pass_count=149236 fail_count=0
PASS tb_mod_sub_pipe            pass_count=149236 fail_count=0
PASS tb_montgomery_reduce_pipe  pass_count=1010 fail_count=0
PASS tb_mod_mul_pipe            pass_count=2009 fail_count=0
PASS tb_barrett_reduce_pipe     pass_count=2014 fail_count=0
PASS tb_butterfly_unit          pass_count=206  fail_count=0
PASS tb_ntt_core                pass_count=512  fail_count=0
PASS tb_intt_core               pass_count=768  fail_count=0
PASS tb_ntt_intt_roundtrip      pass_count=1024 fail_count=0
PASS tb_zetas_rom               pass_count=16   fail_count=0
```

No timing success, area, or Fmax claims are made. Synthesis is deferred to M2.3.
