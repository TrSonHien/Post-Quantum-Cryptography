# ML-KEM-768 RTL-to-GDSII Project Roadmap

**Project title:** Full RTL-to-GDSII Hardware Implementation of ML-KEM-768  
**Target algorithm:** ML-KEM-768, formerly CRYSTALS-Kyber-768  
**Implementation language:** Verilog RTL  
**ASIC flow:** RTL → Genus synthesis → Innovus PnR → STA → GDSII  
**Preferred technology:** gsclib045 first; Sky130 optional comparison later  
**Project duration:** 24 months  
**Final target:** IEEE-style report, verified RTL, clean synthesis/PnR/STA, GDSII, GitHub repository

---

## 1. Project Objective

The goal of this project is to design, verify, synthesize, and physically implement a full ML-KEM-768 hardware accelerator from RTL to GDSII.

This is not a minimal demo project. The final design should support the full KEM flow:

1. Key generation
2. Encapsulation
3. Decapsulation

The project should produce:

- Correct RTL verified against a golden reference model
- Unit/block/system-level simulation reports
- Waveforms and regression logs
- Synthesis reports
- Area, power, timing reports
- Innovus floorplan, placement, CTS, routing results
- Clean setup/hold timing
- GDSII layout
- Comparison with papers or reference implementations
- Vietnamese LaTeX/IEEE-style report
- Clean GitHub repository

---

## 2. Scope Definition

### 2.1 Algorithm

Target algorithm:

```text
ML-KEM-768
n = 256
q = 3329
k = 3
```

The design should follow the standardized ML-KEM direction, not only an old Kyber draft implementation.

### 2.2 Hardware Scope

The design should include the following major components:

```text
ML-KEM-768 Top
│
├── Control FSM / Scheduler
├── Polynomial Arithmetic Core
│   ├── Modular Addition
│   ├── Modular Subtraction
│   ├── Modular Multiplication
│   ├── Montgomery Reduction
│   ├── Barrett Reduction
│   ├── Butterfly Unit
│   ├── NTT
│   ├── INTT
│   └── Pointwise Multiplication
│
├── Keccak / SHAKE Core
│   ├── SHAKE128
│   ├── SHAKE256
│   ├── SHA3-related functions if required
│   └── PRF / XOF interface
│
├── Sampler
│   ├── CBD eta1
│   ├── CBD eta2
│   └── Rejection Sampling
│
├── Codec
│   ├── Encode
│   ├── Decode
│   ├── Compress
│   ├── Decompress
│   ├── Pack Public Key
│   ├── Unpack Public Key
│   ├── Pack Secret Key
│   ├── Unpack Secret Key
│   ├── Pack Ciphertext
│   └── Unpack Ciphertext
│
├── Memory Subsystem
│   ├── Polynomial RAM
│   ├── Vector Buffer
│   ├── Matrix Buffer
│   ├── Key Buffer
│   ├── Ciphertext Buffer
│   └── Shared Secret Buffer
│
├── KeyGen Datapath
├── Encaps Datapath
└── Decaps Datapath
```

---

## 3. Key Design Philosophy

The design should be developed in this order:

```text
Correctness → Clean RTL → Verification → Synthesis → PPA Exploration → Physical Design → Final Report
```

Do not rush into GDSII before the RTL and verification environment are stable.

### Important warning

The weakest current skill area is verification. For crypto hardware, verification is not optional. A waveform that “looks correct” is not enough. The design must pass bit-exact comparison against known answer tests or a golden model.

---

## 4. Recommended Repository Structure

```text
mlkem768-rtl-gds/
├── README.md
├── LICENSE
├── Makefile
│
├── docs/
│   ├── project_spec.md
│   ├── architecture.md
│   ├── verification_plan.md
│   ├── ppa_analysis.md
│   ├── paper_survey_table.md
│   └── ieee_report/
│
├── ref/
│   ├── c_ref/
│   ├── python_model/
│   ├── kat/
│   └── compare/
│
├── rtl/
│   ├── top/
│   ├── arithmetic/
│   ├── ntt/
│   ├── keccak/
│   ├── sampler/
│   ├── codec/
│   ├── memory/
│   └── control/
│
├── tb/
│   ├── unit/
│   ├── block/
│   └── system/
│
├── sim/
│   ├── scripts/
│   ├── logs/
│   └── waves/
│
├── synth/
│   ├── genus/
│   ├── constraints/
│   ├── scripts/
│   └── reports/
│
├── pnr/
│   ├── innovus/
│   ├── floorplan/
│   ├── scripts/
│   └── reports/
│
├── gds/
├── figures/
└── archive/
```

---

## 5. Phase-by-Phase Roadmap

## Phase 0 — Project Setup and Document Control

**Estimated time:** 2–3 weeks

### Goal

Create a clean project foundation before writing RTL.

### Tasks

- Create GitHub repository
- Create standard folder structure
- Collect reference documents
- Study ML-KEM-768 parameters
- Write project specification
- Write first architecture document
- Write first verification plan
- Create paper survey table

### Files to create

```text
docs/project_spec.md
docs/architecture.md
docs/verification_plan.md
docs/paper_survey_table.md
docs/mlkem768_function_list.md
```

### Deliverables

- Project spec v0.1
- Architecture spec v0.1
- Verification plan v0.1
- Function list table
- Paper survey table

### Exit criteria

- Repository is initialized
- Documentation skeleton is complete
- Full ML-KEM-768 function list is known
- First architecture direction is selected

---

## Phase 1 — Golden Model and Test Vector Infrastructure

**Estimated time:** 1–2 months

### Goal

Build the reference model and test infrastructure before writing large RTL blocks.

### Tasks

- Prepare C reference model
- Optionally write Python model/wrapper
- Prepare Known Answer Test vectors
- Build comparison script
- Define input/output file formats for RTL simulation
- Create automatic pass/fail regression flow

### Suggested structure

```text
ref/
├── c_ref/
├── python_model/
├── kat/
│   ├── keygen_vectors.txt
│   ├── encaps_vectors.txt
│   └── decaps_vectors.txt
└── compare/
    └── compare_outputs.py
```

### Verification direction

```text
C/Python Reference
        ↓
Known Answer Test
        ↓
RTL Simulation Output
        ↓
Bit-exact Compare
        ↓
Pass/Fail Report
```

### Deliverables

- Golden model can generate expected outputs
- RTL testbench output format is defined
- Python/C comparison script works
- First regression flow exists

### Exit criteria

- At least one simple reference test can be generated and checked automatically
- Project has a repeatable verification method

---

## Phase 2 — Modular Arithmetic RTL

**Estimated time:** 2–3 months

### Goal

Implement and verify arithmetic primitives.

### RTL modules

```text
mod_add.v
mod_sub.v
mod_mul.v
montgomery_reduce.v
barrett_reduce.v
butterfly_unit.v
```

### Tasks

- Implement modular addition
- Implement modular subtraction
- Implement modular multiplication
- Implement Montgomery reduction
- Implement Barrett reduction
- Implement butterfly unit
- Write unit testbench for each module
- Compare RTL output with reference model

### Deliverables

- Arithmetic RTL modules
- Unit testbenches
- Simulation logs
- Waveforms
- Initial synthesis check

### Exit criteria

- Every arithmetic module passes unit test
- No unknown X/Z propagation in normal operation
- Modules are synthesizable

---

## Phase 3 — NTT, INTT, and Polynomial Multiplication

**Estimated time:** 2–3 months

### Goal

Implement the core polynomial arithmetic engine.

### RTL modules

```text
ntt_core.v
intt_core.v
pointwise_mul.v
poly_add.v
poly_sub.v
poly_mul_top.v
twiddle_rom.v
```

### Tasks

- Implement NTT core
- Implement INTT core
- Implement pointwise multiplication
- Define twiddle factor ROM
- Define coefficient memory access pattern
- Verify NTT/INTT using golden model
- Measure cycle count
- Synthesize NTT core separately

### Deliverables

- NTT RTL
- INTT RTL
- Pointwise multiplier RTL
- Polynomial multiplication RTL
- Testbench and regression script
- Latency report
- Area/timing estimate

### Exit criteria

- NTT output matches golden model
- INTT output matches golden model
- Polynomial multiplication passes test vectors
- Critical path is understood

---

## Phase 4 — Memory Architecture

**Estimated time:** 1–2 months

### Goal

Design memory subsystem early to avoid later PPA problems.

### Questions to answer

- How many coefficients are stored per polynomial?
- What is the coefficient bit width?
- Is RAM single-port or dual-port?
- Is ping-pong buffering needed?
- How are matrix/vector polynomials stored?
- How does NTT read/write coefficients?
- Where are twiddle factors stored?
- Is memory banking needed?

### RTL modules

```text
poly_ram.v
dual_port_ram.v
vector_buffer.v
matrix_buffer.v
key_buffer.v
ciphertext_buffer.v
shared_secret_buffer.v
```

### Deliverables

- Memory map
- Memory access schedule
- RAM/register usage estimate
- Memory RTL
- Memory testbench

### Exit criteria

- Memory subsystem supports NTT/INTT access pattern
- No obvious bandwidth bottleneck remains
- Memory architecture is documented

---

## Phase 5 — Keccak / SHAKE Core

**Status (2026-07-13): complete through M5.6.** The iterative permutation,
byte-stream sponge, SHA3-256/512, SHAKE128/256, ML-KEM H/G/J/PRF/XOF,
independent differential tests, unified regression, and M6 handoff are frozen.
No synthesis/area/Fmax claim is included.

**Estimated time:** 2–3 months

### Goal

Implement or integrate Keccak/SHAKE support required by ML-KEM.

### Recommended direction

Use an iterative Keccak-f[1600] core first. Avoid deep pipelining at the beginning.

### RTL modules

```text
keccak_f1600.v
shake128_core.v
shake256_core.v
keccak_absorb.v
keccak_squeeze.v
keccak_ctrl.v
```

### Tasks

- Implement Keccak-f[1600] round function
- Implement absorb/squeeze interface
- Build SHAKE128
- Build SHAKE256
- Verify against known hash/XOF outputs
- Integrate with sampler interface

### Deliverables

- Keccak/SHAKE RTL
- Testbench
- Known vector comparison
- Latency and area report

### Exit criteria

- SHAKE128 passes test vectors
- SHAKE256 passes test vectors
- Interface is ready for sampler and KEM datapaths

---

## Phase 6 — Sampling, Compression, and Codec

**Status (2026-07-13): complete through M6.6.** FIPS Algorithms 3--8,
message/poly/polyvec and K-PKE format adapters, eta2/eta3 CBD, integrated PRF
noise, continuing-XOF SampleNTT, deterministic vectors, unified regression, and
the M7 handoff are frozen. M7 is complete and the M8 handoff is frozen. No synthesis/area/Fmax claim is
included.

**Estimated time:** 2–3 months

### Goal

Implement all bit-level transform blocks.

### RTL modules

```text
cbd_eta1.v
cbd_eta2.v
rej_uniform.v
compress_core.v
decompress_core.v
encode_core.v
decode_core.v
pack_public_key.v
unpack_public_key.v
pack_secret_key.v
unpack_secret_key.v
pack_ciphertext.v
unpack_ciphertext.v
```

### Tasks

- Implement CBD sampler
- Implement rejection sampling
- Implement compression/decompression
- Implement encode/decode
- Implement key and ciphertext packing
- Verify bit-exact behavior

### Deliverables

- Sampler RTL
- Codec RTL
- Unit testbenches
- Regression tests
- Bit-level verification report

### Exit criteria

- All sampler outputs match golden model
- All pack/unpack operations match golden model
- No endian/bit-order bug remains

---

## Phase 7 — KeyGen RTL Integration

**Status (2026-07-13): complete as M7 deterministic K-PKE Algorithms 13--15.**
The implemented boundary uses `rtl/kpke/kpke_keygen.v`, `kpke_encrypt.v`, and
`kpke_decrypt.v` plus shared serialized helpers; the older illustrative module
names below are not the source of record. Independent Python differential,
roundtrip, reset/protocol, and unified preservation regression pass. Resource
usage and synthesis remain unclaimed; M2.3b is pending.

**Estimated time:** 2 months

### Goal

Build full KeyGen datapath.

### High-level flow

```text
seed
 ↓
expand matrix A
 ↓
sample secret vector s
 ↓
sample error vector e
 ↓
NTT(s)
 ↓
A * s + e
 ↓
pack public key
 ↓
pack secret key
```

### RTL modules

```text
keygen_ctrl.v
keygen_datapath.v
keygen_top.v
```

### Tasks

- Integrate Keccak, sampler, NTT, memory, codec
- Build KeyGen FSM
- Verify KeyGen output against golden model
- Measure latency and resource usage

### Deliverables

- KeyGen RTL
- KeyGen testbench
- Waveform
- Simulation report
- Synthesis report

### Exit criteria

- Public key matches golden model
- Secret key matches golden model
- KeyGen has stable latency
- KeyGen synthesizes cleanly

---

## Phase 8 — Encaps RTL Integration

**Status: academic functional baseline complete.** M8 covers final ML-KEM
KeyGen, Encaps, Decaps, input checking, implicit rejection, and top-level
control. Basic differential and end-to-end verification are complete; exhaustive
security hardening, authoritative CAVP/ACVP validation, and synthesis remain
future work.

**M9 update (2026-07-17):** the academic RTL release now has a dedicated
`mlkem768_top` synthesis file list and clean full-hierarchy elaboration.  No
local Yosys, Genus, or standard-cell library is available, so M2.3b and full
top technology-mapped synthesis remain environment-blocked.  No area, Fmax,
post-layout timing, or power result is claimed.

**Estimated time:** 2 months

### Goal

Build full Encapsulation datapath.

### High-level flow

```text
public key + message/randomness
 ↓
hash / derive coins
 ↓
sample r, e1, e2
 ↓
matrix-vector multiplication
 ↓
compress ciphertext
 ↓
derive shared secret
```

### RTL modules

```text
encaps_ctrl.v
encaps_datapath.v
encaps_top.v
```

### Tasks

- Integrate public key unpacking
- Implement encapsulation controller
- Reuse NTT/poly/Keccak/sampler blocks
- Generate ciphertext
- Generate shared secret
- Verify against golden model

### Deliverables

- Encaps RTL
- Encaps testbench
- Ciphertext comparison
- Shared secret comparison
- Simulation and synthesis report

### Exit criteria

- Ciphertext matches golden model
- Shared secret matches golden model
- Encaps synthesizes cleanly

---

## Phase 9 — Decaps RTL Integration

**Estimated time:** 2–3 months

### Goal

Build full Decapsulation datapath.

### High-level flow

```text
secret key + ciphertext
 ↓
decrypt message
 ↓
re-encrypt / verify ciphertext
 ↓
conditional select
 ↓
derive shared secret
```

### RTL modules

```text
decaps_ctrl.v
decaps_datapath.v
decaps_top.v
```

### Tasks

- Implement ciphertext unpacking
- Implement decryption datapath
- Implement re-encryption check
- Implement compare logic
- Implement conditional shared-secret selection
- Test valid ciphertext case
- Test modified ciphertext fail case
- Keep constant-cycle behavior

### Deliverables

- Decaps RTL
- Decaps testbench
- Valid-case simulation
- Invalid-case simulation
- Constant-cycle behavior report

### Exit criteria

- Decaps produces correct shared secret for valid ciphertext
- Decaps handles invalid ciphertext correctly
- Valid and invalid cases use the same visible cycle count
- Decaps synthesizes cleanly

---

## Phase 10 — Full ML-KEM-768 Top Integration

**Estimated time:** 1–2 months

### Goal

Integrate KeyGen, Encaps, and Decaps into one top-level accelerator.

### Recommended top-level interface

```verilog
module mlkem768_top (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        start,
    input  wire [1:0]  mode,
    // 00: KeyGen
    // 01: Encaps
    // 10: Decaps

    input  wire        din_valid,
    input  wire [31:0] din_data,
    output wire        din_ready,

    output wire        dout_valid,
    output wire [31:0] dout_data,
    input  wire        dout_ready,

    output wire        busy,
    output wire        done,
    output wire        error
);
```

### Tasks

- Create top-level controller
- Define streaming input/output protocol
- Integrate all datapaths
- Build system testbench
- Run full KEM regression

### Deliverables

- Full top RTL
- System testbench
- Full KEM simulation
- Regression script
- Waveform and logs

### Exit criteria

- KeyGen mode works
- Encaps mode works
- Decaps mode works
- Full KeyGen → Encaps → Decaps flow passes
- RTL is ready for serious synthesis exploration

---

## Phase 11 — Architecture and PPA Exploration

**Estimated time:** 1–2 months

### Goal

Create multiple architecture variants and compare PPA.

### Architecture A — Area-Optimized

```text
1 butterfly unit
shared modular multiplier
small memory
low area
high latency
```

### Architecture B — Balanced

```text
2–4 butterfly units
dual-port memory
shared Keccak
moderate area
good latency
```

### Architecture C — High-Performance

```text
8+ butterfly units
parallel memory banks
pipelined datapath
larger area
lower latency
higher routing pressure
```

### Metrics

```text
Area
Fmax
Power
Energy per operation
KeyGen cycles
Encaps cycles
Decaps cycles
Memory usage
Critical path
Routing congestion
```

### Deliverables

- At least 2 architecture variants
- Ideally 3 variants
- PPA comparison table
- Critical path analysis
- Selected final architecture

### Exit criteria

- Final architecture is selected based on evidence
- PPA optimization claim is supported by data

---

## Phase 12 — Genus Synthesis

**Estimated time:** 1–2 months

### Goal

Perform synthesis exploration using Cadence Genus.

### Tasks

- Prepare SDC constraints
- Prepare technology library setup
- Run area-optimized synthesis
- Run timing-optimized synthesis
- Run balanced synthesis
- Analyze critical paths
- Fix RTL if needed
- Export netlist and constraints for Innovus

### Reports to generate

```text
report_area
report_power
report_timing
report_qor
report_cells
report_hierarchy
report_clock_gating
```

### Deliverables

- Synthesized netlist
- SDC file
- Area report
- Power report
- Timing report
- QoR report
- Critical path screenshots or text excerpts

### Exit criteria

- No unconstrained critical path
- Setup timing is reasonable before PnR
- Netlist is ready for Innovus

---

## Phase 13 — Innovus Floorplan and Power Plan

**Estimated time:** 1–2 months

### Goal

Create a physically reasonable floorplan.

### Floorplan concept

```text
+------------------------------------------------+
|                 IO / Control                   |
|                                                |
|  +-------------+      +---------------------+   |
|  | Keccak Core |      |  Memory Subsystem   |   |
|  +-------------+      +---------------------+   |
|                                                |
|  +------------------------------------------+   |
|  |        NTT / Polynomial Arithmetic        |   |
|  +------------------------------------------+   |
|                                                |
|  +-------------+      +---------------------+   |
|  | Pack/Unpack |      |  FSM / Scheduler    |   |
|  +-------------+      +---------------------+   |
+------------------------------------------------+
```

### Tasks

- Import synthesized netlist
- Import constraints
- Define floorplan
- Define utilization target
- Create power rings/stripes
- Place major logic regions
- Check congestion early
- Iterate if necessary

### Deliverables

- Floorplan screenshot
- Power plan screenshot
- Utilization report
- Early congestion report
- Floorplan rationale

### Exit criteria

- Floorplan is routable
- Power network is valid
- Congestion is not severe before placement

---

## Phase 14 — Placement, CTS, Routing, and STA

**Estimated time:** 2–3 months

### Goal

Complete physical implementation.

### Tasks

- Standard-cell placement
- Pre-CTS optimization
- Clock tree synthesis
- Post-CTS optimization
- Routing
- Post-route optimization
- Setup timing closure
- Hold timing closure
- DRC check
- Export GDSII

### Reports to generate

```text
pre_cts_timing.rpt
post_cts_timing.rpt
post_route_setup.rpt
post_route_hold.rpt
clock_tree.rpt
power.rpt
area.rpt
congestion.rpt
drc.rpt
```

### Deliverables

- Placed design
- CTS report
- Routed design
- Setup/hold timing report
- DRC report
- Final GDSII
- Final layout screenshot

### Exit criteria

- Setup timing is clean
- Hold timing is clean
- Routing is complete
- DRC is clean or known/fixable
- GDSII is exported

---

## Phase 15 — Final Analysis, Paper Comparison, and Report

**Estimated time:** 2 months

### Goal

Prepare final IEEE-style report and GitHub release.

### Tasks

- Compare design with related works
- Summarize architecture
- Summarize verification methodology
- Summarize ASIC flow
- Prepare all figures
- Write final report
- Clean GitHub repository
- Prepare presentation slides if needed

### Final report structure

```text
Abstract

I. Introduction
   - PQC motivation
   - ML-KEM/Kyber background
   - hardware acceleration motivation
   - contribution

II. Background
   - ML-KEM-768 overview
   - polynomial ring
   - NTT
   - Keccak/SHAKE
   - KEM flow

III. Proposed Architecture
   - top-level architecture
   - arithmetic core
   - NTT/INTT
   - memory subsystem
   - Keccak core
   - controller/FSM

IV. Verification Methodology
   - golden model
   - KAT
   - unit/block/system regression
   - full KEM validation

V. ASIC Implementation Flow
   - synthesis setup
   - constraints
   - floorplan
   - power planning
   - placement/CTS/routing
   - STA

VI. Results and Discussion
   - area
   - timing
   - power
   - latency
   - energy per operation
   - comparison with related works

VII. Conclusion and Future Work
   - achieved results
   - limitations
   - side-channel protection
   - masking
   - AXI/APB integration
   - tapeout readiness

References
Appendix
```

### Deliverables

- Final report
- Final figures
- Final result tables
- Final GitHub repository
- Final GDSII
- Optional slide deck

### Exit criteria

- Project can be explained from algorithm to GDSII
- All results are reproducible
- Report has enough depth for serious academic evaluation

---

## 6. Verification Plan

## 6.1 Verification Levels

### Level 1 — Unit Test

```text
mod_add
mod_sub
mod_mul
montgomery_reduce
barrett_reduce
butterfly
ntt
intt
keccak
shake128
shake256
cbd
rej_uniform
compress
decompress
pack
unpack
```

### Level 2 — Block Test

```text
poly_mul
matrix_vector_mul
pack/unpack pipeline
hash/sampling pipeline
memory access pattern
```

### Level 3 — Function Test

```text
KeyGen
Encaps
Decaps
```

### Level 4 — Full KEM Test

```text
KeyGen → Encaps → Decaps → shared_secret_compare
```

### Level 5 — Negative Test

```text
modified ciphertext → Decaps should reject/fallback correctly
```

---

## 6.2 Regression Commands

Suggested command structure:

```bash
make test_unit
make test_arith
make test_ntt
make test_keccak
make test_sampler
make test_codec
make test_keygen
make test_encaps
make test_decaps
make test_full
make test_all
```

---

## 6.3 Verification Rules

- Every RTL module must have a testbench.
- Every testbench should produce a pass/fail result.
- Every major block should compare against the golden model.
- Waveform-only checking is not acceptable.
- Test outputs should be saved in logs.
- Regression should be repeatable by Makefile or scripts.
- Final report should include verification coverage by function, even if not formal coverage.

---

## 7. PPA Optimization Plan

## 7.1 Metrics

For each architecture, record:

```text
Area
Fmax
Cycle count
Latency
Throughput
Power
Energy per operation
Memory usage
Critical path
Routing congestion
```

## 7.2 Result Table Template

| Architecture | Area | Fmax | KeyGen Cycles | Encaps Cycles | Decaps Cycles | Power | Energy/op | Remark |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| A | TBD | TBD | TBD | TBD | TBD | TBD | TBD | Area-saving |
| B | TBD | TBD | TBD | TBD | TBD | TBD | TBD | Balanced |
| C | TBD | TBD | TBD | TBD | TBD | TBD | TBD | High-performance |

---

## 8. Two-Year Timeline

## Year 1 — Algorithm, Verification, and RTL Correctness

| Month | Main Goal |
|---:|---|
| 1 | Study standard, create repo, write project spec |
| 2 | Build golden model and KAT flow |
| 3 | Modular arithmetic RTL |
| 4 | Reduction and butterfly RTL |
| 5 | NTT core |
| 6 | INTT and polynomial multiplication |
| 7 | Memory subsystem |
| 8 | Keccak/SHAKE core |
| 9 | Keccak/SHAKE verification |
| 10 | Sampler, compression, codec |
| 11 | KeyGen RTL |
| 12 | Encaps RTL |

## Year 2 — Full KEM, ASIC Flow, and Final Report

| Month | Main Goal |
|---:|---|
| 13 | Decaps RTL |
| 14 | Decaps verification |
| 15 | Full ML-KEM top integration |
| 16 | Full regression and bug fixing |
| 17 | Architecture A/B/C exploration |
| 18 | Genus synthesis exploration |
| 19 | Innovus floorplan and power plan |
| 20 | Placement, CTS, routing |
| 21 | STA and timing closure |
| 22 | Final PPA comparison |
| 23 | IEEE-style report writing |
| 24 | GitHub cleanup, final figures, final defense preparation |

---

## 9. Immediate Next Actions

Do these before writing RTL:

```text
[ ] Create repository: mlkem768-rtl-gds
[ ] Create folder structure
[ ] Add this roadmap file to docs/
[ ] Create docs/project_spec.md
[ ] Create docs/architecture.md
[ ] Create docs/verification_plan.md
[ ] Create docs/mlkem768_function_list.md
[ ] Create docs/paper_survey_table.md
[ ] Add C reference code to ref/c_ref/
[ ] Decide exact KAT format
[ ] Create first Makefile skeleton
```

---

## 10. First Milestone Checklist

Milestone name:

```text
M1: Project Foundation
```

Target deliverables:

```text
[ ] GitHub repo created
[ ] README.md written
[ ] Roadmap added
[ ] Architecture v0.1 written
[ ] Verification plan v0.1 written
[ ] Function list completed
[ ] Reference C code added
[ ] First KAT file prepared
[ ] First compare script drafted
```

Exit criteria:

```text
The project is organized enough that RTL development can begin without losing context.
```

---

## 11. Risk Register

| Risk | Severity | Mitigation |
|---|---|---|
| Verification too weak | High | Build golden model and regression before full RTL |
| C reference does not match FIPS 203 | High | Compare reference with standard and KAT |
| Memory architecture inefficient | High | Design memory subsystem before full integration |
| Keccak consumes too much time | Medium | Start with iterative Keccak core |
| PPA goal too vague | High | Compare at least 2–3 architecture variants |
| Full KEM integration too complex | High | Integrate KeyGen, then Encaps, then Decaps |
| GDSII blocked by memory implementation | High | Decide SRAM/register memory strategy early |
| Timing closure difficult | Medium | Run early synthesis for critical modules |
| Report lacks academic depth | Medium | Maintain paper survey and comparison table from the start |
| GitHub becomes messy | Medium | Keep docs, rtl, tb, synth, pnr separated from day one |

---

## 12. Project Rules

1. Do not write large RTL without a test plan.
2. Do not trust waveform-only verification.
3. Every module must have a testbench.
4. Every major result must be reproducible.
5. Every PPA claim must have report evidence.
6. Keep documentation updated every milestone.
7. Commit frequently with clear messages.
8. Do not optimize before correctness.
9. Do not start Innovus before synthesis and constraints are clean.
10. Treat verification as a core contribution, not as an afterthought.

---

## 13. Recommended Commit Style

```bash
git commit -m "docs: add ML-KEM-768 project specification"
git commit -m "rtl: add modular addition and subtraction"
git commit -m "tb: add unit test for Montgomery reduction"
git commit -m "sim: add regression script for arithmetic blocks"
git commit -m "synth: add Genus script for NTT core"
git commit -m "pnr: add initial Innovus floorplan script"
```

---

## 14. Suggested README Summary

```text
This repository contains a full RTL-to-GDSII implementation of an ML-KEM-768 hardware accelerator. The design is written in Verilog RTL and verified against a golden reference model. The ASIC implementation flow targets Cadence Genus and Innovus using gsclib045 technology. The project includes RTL, testbenches, simulation scripts, synthesis scripts, physical design scripts, PPA reports, and final documentation.
```

---

## 15. Final Success Definition

The project is successful only if all major items below are achieved:

```text
[ ] Full ML-KEM-768 RTL exists
[ ] KeyGen passes test vectors
[ ] Encaps passes test vectors
[ ] Decaps passes test vectors
[ ] Full KEM flow passes
[ ] Simulation logs are reproducible
[ ] Synthesis completes cleanly
[ ] Area/power/timing reports are generated
[ ] Innovus PnR completes
[ ] Setup timing is clean
[ ] Hold timing is clean
[ ] GDSII is exported
[ ] PPA is compared across architecture variants
[ ] Results are compared with related works
[ ] Vietnamese IEEE-style report is completed
[ ] GitHub repository is clean and documented
```

---

## 16. Note for Future Continuation

When continuing this project in future conversations, provide this file or paste the current milestone status. The next assistant should first check:

```text
1. Current milestone
2. Completed modules
3. Failing tests
4. Current architecture version
5. Current synthesis/PnR status
6. Latest TODO list
```

Recommended status update format:

```text
Current milestone:
Completed:
In progress:
Blocked by:
Latest failing test:
Next target:
```
