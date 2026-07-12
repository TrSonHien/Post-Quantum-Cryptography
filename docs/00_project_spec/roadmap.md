# Current Project Roadmap

This file tracks the active ML-KEM-768 project milestones.

M0 officially replaces the older `M1: Algorithm and Verification Foundation`
wording as the first project milestone.

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
standards and provenance -> FIPS algorithm tracking -> KAT provenance ->
independent golden models -> comparison tools -> architecture freeze -> RTL
```

## Active Milestones

- M0: Standards, algorithm tracking, KAT, and independent golden models
- M1: Interface, representation, timing, and memory architecture freeze v0.1
- M2: Memory primitives and pipelined arithmetic variants
- M3: Fmax-oriented NTT/INTT with banked synchronous memory
- M4: Polynomial and Polyvec engines
- M5: Keccak-f1600, SHA3, and SHAKE engines
- M6: Codec and Sampler engines
- M7: K-PKE KeyGen, Encrypt, and Decrypt
- M8: ML-KEM KeyGen, Encaps, Decaps, and top-level wrapper
- M9: End-to-end KAT and independent differential verification

## Current M0 Tasks

- M0.1: Source, standards, and provenance audit.
- M0.2: FIPS 203 algorithm tracking.
- M0.3: C/KAT harness planning and implementation.
- M0.4: Independent Python ML-KEM-768 golden model.
- M0.5: Comparison tools and final M0 report.

Do not start M1 architecture freeze or new RTL architecture until M0 gates are
complete or the user explicitly changes scope.

## Explicitly Excluded For Now

- Genus
- Innovus
- PnR
- STA
- GDSII
- Physical Design
