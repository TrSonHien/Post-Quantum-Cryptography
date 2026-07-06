# Current Phase Roadmap

This file tracks the active algorithm and verification foundation phase.

Long-term physical implementation work is intentionally excluded from the current active workspace.

## Optimization Direction

The project is now high-frequency-first after correctness:

```text
1. Correctness
2. Timing closure / high operating frequency / Fmax
3. Throughput
4. Area
```

PPA is still tracked, but the active RTL direction is high-frequency-first PPA,
not area-first PPA. Area is a secondary metric and should not drive the main
datapath architecture unless the user explicitly asks for an area comparison.

Prefer pipelined datapaths for `mod_mul`, Montgomery reduction, `basemul`,
NTT/INTT, Keccak/SHAKE, sampler, codec, and other critical paths. Every
pipelined block should document latency, valid/data alignment, and downstream
interface assumptions.

## Current Flow

```text
standard reading -> reference model -> test vectors -> arithmetic RTL -> unit verification
```

## Active Milestones

- M1: Algorithm and Verification Foundation
- M2: Modular Arithmetic RTL and Unit Tests
- M3: High-frequency NTT / INTT RTL and Block Tests
- M4: Keccak / SHAKE RTL and Block Tests
- M5: Sampler, Codec, and Packing Verification
- M6: KeyGen / Encaps / Decaps Integration Simulation

## Next Architecture Tasks

- Validate pipelined `basemul_unit` as the main basemul architecture.
- Update poly-level planning so pointwise multiplication can feed pipelined
  basemul every cycle where possible.
- Pipeline `mod_mul` / Montgomery reduction later if synthesis or timing review
  shows it is the critical path.

## Explicitly Excluded For Now

- Genus
- Innovus
- PnR
- STA
- GDSII
- Physical Design
