# M2 Plan: Contract-Compliant RTL Foundations

## M2.1 synchronous memory and pipeline-control primitives

Implemented scope:

- generic synchronous one-read/one-write RAM;
- conflict-free NTT bank mapper;
- two-source/two-destination ping-pong memory wrapper;
- fixed-latency valid/payload/metadata delay;
- one-entry valid/ready register slice.

M2.1 preserves all legacy RTL. It adds no arithmetic, butterfly, NTT/INTT
controller, codec, sampler, Keccak, or ML-KEM engine implementation.

Gate evidence is recorded in `reports/simulation/m2_1_primitives_report.md`.

## Later M2 work

M2.2 and subsequent work are not started. They require explicit approval and a
separate implementation plan. No synthesis or Fmax result is claimed in M2.1.
