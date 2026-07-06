# Project Specification

## Project

ML-KEM-768 / Kyber-768 high-frequency ASIC-oriented RTL and Verification Workspace.

## Scope

The active repository scope is the algorithm and verification foundation for ML-KEM-768:

- Standard reading and project notes
- C/Python reference model setup
- Known Answer Test vector organization
- Arithmetic RTL workspace
- Unit, block, and system testbench workspace
- Simulation scripts, logs, waveforms, outputs, and comparison flow
- Architecture and verification documentation

## Architecture Priority

The project optimization priority is:

```text
1. Correctness
2. Timing closure / high operating frequency / Fmax
3. Throughput
4. Area
```

The leading implementation objective after correctness is timing closure and
high operating frequency. Area is tracked as part of PPA, but it is not the
primary optimization target. The main datapath should prefer pipelined
high-frequency architecture over resource-shared area-saving architecture.

Area-saving sequential versions may be kept only as comparison/reference
variants. They should not define the main implementation direction.

Critical datapaths such as `mod_mul`, Montgomery reduction, `basemul`, NTT/INTT,
Keccak/SHAKE, sampler, codec, and top-level schedulers should be planned with
pipeline stages, explicit valid/data alignment, and timing closure in mind.

## Out Of Current Scope

- Genus
- Innovus
- PnR
- STA
- GDSII
- Physical Design

## Current Status

The repository is in M1: Algorithm and Verification Foundation. RTL is being
reviewed and verified incrementally; a passing unit or block simulation does not
yet imply full ML-KEM correctness.

## Non-Claims

- No cryptographic correctness is claimed until test-vector comparison exists.
- No synthesizability is claimed until RTL review exists.
- No ASIC or physical-design readiness is claimed in the current phase.
