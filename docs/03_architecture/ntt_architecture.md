# NTT Architecture

Use this file for NTT, INTT, butterfly, twiddle ROM, and memory scheduling architecture notes.

## Architecture Priority

NTT/INTT and base multiplication follow the project-wide priority:

```text
1. Correctness
2. Timing closure / high operating frequency / Fmax
3. Throughput
4. Area
```

The preferred basemul architecture is a high-throughput pipelined datapath.
Sequential/resource-shared basemul is allowed only as a comparison or reference
implementation; it is not the main direction.

## Pipelined Basemul Direction

The main `basemul_unit` should accept a new valid transaction every cycle when
upstream data is available and downstream logic can accept the result. Later
poly-level pointwise multiplication blocks should be designed to feed pipelined
basemul every cycle when possible.

The current main basemul direction assumes:

- fixed coefficient interface: unsigned canonical `KYBER_Q_WIDTH` values
- valid-only pipeline interface
- no backpressure in the first implementation
- latency documented at the module boundary
- write address and output index alignment delayed by the basemul pipeline
  latency

When a poly-level block writes basemul results back to a polynomial buffer, its
write address, coefficient-pair index, zeta index, and output valid strobes must
be delayed by the same latency as the basemul data path. If future `mod_mul` or
Montgomery reduction becomes pipelined, those extra cycles must be reflected in
the basemul and poly-level alignment logic.
