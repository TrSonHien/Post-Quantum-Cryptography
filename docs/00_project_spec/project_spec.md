# Project Specification

## Project

ML-KEM-768 high-frequency ASIC-oriented RTL and Verification Workspace.

## Scope

The active repository scope starts at M0: standards, algorithm tracking, KAT
provenance, and independent golden models for ML-KEM-768.

M0 scope includes:

- Standard reading and project notes
- C/Python reference model setup
- Known Answer Test vector organization
- Source provenance and SHA-256 manifests
- FIPS 203 algorithm tracking
- Independent model and comparison-flow planning

Existing RTL, unit tests, simulation scripts, and reports remain present for
inventory, but new RTL architecture work is not part of M0.

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

The repository is in M0: Standards, algorithm tracking, KAT, and independent
golden models. M0 officially replaces the older `M1: Algorithm and Verification
Foundation` wording as the first milestone.

Existing RTL has local simulation evidence, but a passing unit or block
simulation does not imply FIPS 203 ML-KEM correctness until M0 produces trusted
KAT/golden-model comparison evidence.

## Non-Claims

- No cryptographic correctness is claimed until test-vector comparison exists.
- No synthesizability is claimed until RTL review exists.
- No ASIC or physical-design readiness is claimed in the current phase.
- Local Kyber 2020 KATs are legacy Kyber regression vectors, not final FIPS 203
  ML-KEM validation vectors.
