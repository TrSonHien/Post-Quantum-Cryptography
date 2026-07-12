# M2.2.6 Simulation Report: Pipelined Inverse NTT Butterfly

## Implementation Details

The module `intt_butterfly_pipe` was implemented as a 5-cycle pipelined Gentleman-Sande (GS) inverse NTT butterfly block:
*   **Target Modulus**: $q = 3329$
*   **Domain Representation**: Inputs $u$ and $v$ are in the NTT domain. The coefficient $zeta\_mont$ is in the Montgomery domain, scaled by $R \pmod q$ ($zeta\_mont = \zeta \cdot R \pmod q$, where $R = 2^{16}$). Outputs $out0, out1$ are in the NTT domain.
*   **Inverse Butterfly Operation**:
    *   $sum = (u + v) \pmod q$ (using `mod_add_pipe` in Stage 1)
    *   $diff = (v - u) \pmod q$ (using `mod_sub_pipe` in Stage 1)
    *   $prod = MontgomeryReduce(zeta\_mont \cdot diff)$ (using `mod_mul_pipe` in Stages 2-5)
    *   $out0 = sum_{delayed}$
    *   $out1 = prod$
*   **Latency**: Fixed 5-cycle edge-to-edge latency ($L=5$).
*   **Initiation Interval**: $II=1$ (fully pipelined).
*   **Reset behavior**: Synchronous active-low reset `rst_n` clears valid/control registers only. Payload registers (including the addition/subtraction outputs and multiplier outputs) are not reset to optimize area.

### Pipeline Stages
*   **Stage 1**: Computes modular addition ($sum$) and modular subtraction ($diff$) in parallel. The twiddle factor $zeta\_mont$ is registered and delayed by 1 cycle.
*   **Stages 2-5**: Passes $diff$ and $zeta\_mont_{delayed}$ through `mod_mul_pipe` (4-cycle latency) to compute the product $prod$. Simultaneously, $sum$ is delayed by 4 cycles using the verified `fixed_latency_delay` primitive to align with $prod$ at Stage 5.

## Verification Summary

A self-checking testbench was created under `tb/unit/tb_intt_butterfly_pipe.v`.

The verification tests cover:
1.  **Directed Cases**: Edge values ($0$, $1$, $q-1$), using representative inverse zetas from the inverse NTT ROM (1701, 1807, 1460).
2.  **Deterministic Random Cases**: 2,000 randomized canonical inputs for $u$, $v$, and $zeta\_mont$.
3.  **Pipeline Control**: Continuous execution ($II=1$), valid-bubbles, reset during active data propagation.
4.  **Alignment Checks**: Verification that `out_valid` is asserted exactly 5 cycles after `in_valid` and payload values align perfectly.
5.  **Golden Comparison**: Output checks against expected values:
    *   $sum_{expected} = (u + v) \pmod q$
    *   $diff_{expected} = (v + q - u) \pmod q$
    *   $prod_{expected} = (zeta\_mont \cdot diff_{expected} \cdot 169) \pmod q$

### Verification Results

All tests completed successfully:

```text
PASS tb_intt_butterfly_pipe  pass_count=2007  fail_count=0
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
PASS tb_butterfly_pipe          pass_count=2006 fail_count=0
PASS tb_butterfly_unit          pass_count=206  fail_count=0
PASS tb_ntt_core                pass_count=512  fail_count=0
PASS tb_intt_core               pass_count=768  fail_count=0
PASS tb_ntt_intt_roundtrip      pass_count=1024 fail_count=0
PASS tb_zetas_rom               pass_count=16   fail_count=0
```

No timing success, area, or Fmax claims are made. Synthesis is deferred to M2.3.
