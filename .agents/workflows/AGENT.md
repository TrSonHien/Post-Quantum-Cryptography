# AGENTS.md

## Project

This repository implements a full RTL-to-GDSII oriented hardware design for **ML-KEM-768 / CRYSTALS-Kyber768**.

Current project focus:

```text
Algorithm reference
→ arithmetic RTL
→ NTT/INTT RTL
→ polynomial / polyvec blocks
→ sampler / codec / Keccak
→ INDCPA
→ KEM top
→ verification
→ later synthesis / PnR
```

The current active development phase is **RTL + simulation verification**.
Physical design is intentionally not the active scope yet.

---

## Architecture Priority

The project architecture priority is:

```text
1. Correctness
2. Timing closure / high operating frequency / Fmax
3. Throughput
4. Area
```

Correctness comes first. After correctness, the main implementation goal is a
high-frequency ASIC-oriented datapath that can close timing and reach strong
Fmax. Throughput comes after Fmax. Area is tracked, but it is not the leading
optimization objective.

Main datapaths should prefer pipelined high-frequency architecture. Area-saving
sequential variants may exist only as comparison/reference variants and should
not be treated as the default implementation style.

Future agents should not assume area optimization is the default. When reviewing
or extending RTL, prefer timing-friendly pipelining, explicit latency tracking,
and clean valid/data alignment over resource sharing unless the user explicitly
asks for an area comparison.

---

## Repository Structure

```text
docs/                 Project notes, standard notes, math notes, architecture notes, verification plan
references/           Original standards, papers, PDFs, and external source references
ref_model/            C reference, KATs, Python models, comparison scripts
rtl/                  Synthesizable Verilog RTL
tb/                   Verilog testbenches
sim/                  Simulation scripts, logs, outputs, and waves
reports/              Simulation reports and future synthesis / implementation reports
figures/              Architecture diagrams, charts, layout screenshots, waveforms
pd/                   Physical design area, currently out of scope unless explicitly requested
archive/              Old or inactive scaffolds
scripts/              General helper scripts
TODO.md               Current work queue and progress tracking
CHANGELOG.md          Project change history
```

---

## Important Scope Rules

### Active Scope

Agents may work on:

```text
rtl/
tb/
sim/scripts/
reports/simulation/
docs/
TODO.md
CHANGELOG.md
ref_model/
```

only when the requested task clearly requires it.

### Out of Scope Unless Explicitly Requested

Do not modify these areas unless the user explicitly asks:

```text
pd/
archive/
references/standards/
references/papers/
```

Do not reorganize the repository unless explicitly requested.

---

## Development Ownership

The user is the primary RTL author.

Default role of an agent:

```text
- explain architecture
- review RTL
- write or improve testbenches
- write simulation scripts
- update reports
- update TODO.md
- identify bugs and verification gaps
```

Do not rewrite working RTL unless the user explicitly asks for RTL changes.

When reviewing RTL, prefer:

```text
1. explain the issue
2. identify the exact file/module/signal
3. suggest the minimal fix
4. avoid broad refactors
```

---

## Current RTL Convention

### Coefficient Representation

At arithmetic module boundaries, Kyber coefficients use:

```text
unsigned 12-bit
range: 0 <= x < KYBER_Q
KYBER_Q = 3329
```

This applies to:

```text
mod_add.v
mod_sub.v
mod_mul.v
butterfly_unit.v
intt_butterfly_unit.v
ntt_core.v
poly_buffer.v
```

### Internal Signed Arithmetic

Some internal reduction logic may use signed arithmetic to match the C reference:

```text
montgomery_reduce()
barrett_reduce()
```

However, external arithmetic block outputs should return canonical unsigned coefficients in:

```text
[0, q-1]
```

---

## RTL Style Rules

Use synthesizable Verilog.

Avoid:

```text
- non-synthesizable RTL constructs
- hidden behavioral shortcuts in RTL
- modulo operator % for Kyber modular reduction datapaths
- division operator / in arithmetic datapaths
- unnecessary signed/unsigned mixing
- architecture-specific constants inside algorithm parameter files
```

Prefer:

```text
- clear module boundaries
- explicit bit widths
- localparam for local constants
- shared constants from rtl/common/kyber_params.vh
- small modules with dedicated testbenches
- pipeline registers on critical arithmetic paths when they improve Fmax
- explicit valid/latency alignment for pipelined datapaths
```

---

## Parameter Source of Truth

Algorithm parameters should come from:

```text
rtl/common/kyber_params.vh
```

Do not hardcode Kyber constants repeatedly across RTL files unless there is a strong reason.

Primary reference files:

```text
ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/Reference_Implementation/crypto_kem/kyber768/params.h
ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/Reference_Implementation/crypto_kem/kyber768/api.h
```

---

## Important Reference Files

For arithmetic and reduction:

```text
kyber768/reduce.c
kyber768/reduce.h
```

For NTT / INTT / basemul:

```text
kyber768/ntt.c
kyber768/ntt.h
```

For polynomial operations:

```text
kyber768/poly.c
kyber768/poly.h
```

For polynomial-vector operations:

```text
kyber768/polyvec.c
kyber768/polyvec.h
```

For INDCPA:

```text
kyber768/indcpa.c
kyber768/indcpa.h
```

For KEM top-level behavior:

```text
kyber768/kem.c
kyber768/kem.h
```

For Keccak/SHAKE:

```text
kyber768/fips202.c
kyber768/fips202.h
```

---

## Documentation Reading Map

When blocked, read the matching document area:

```text
Algorithm unclear:
  docs/01_standard/
  references/standards/NIST.FIPS.203.pdf
  references/standards/kyber-specification-round3-20210804.pdf

Keccak / SHAKE unclear:
  docs/01_standard/fips202_keccak_notes.md
  references/standards/nist.fips.202.pdf

Math unclear:
  docs/02_math/

Architecture unclear:
  docs/03_architecture/

Verification unclear:
  docs/04_verification/

C behavior unclear:
  ref_model/c_ref/
```

---

## Current Implemented RTL Blocks

Current active RTL includes:

```text
rtl/common/kyber_params.vh

rtl/arithmetic/mod_add.v
rtl/arithmetic/mod_sub.v
rtl/arithmetic/reduction.v
rtl/arithmetic/mod_mul.v

rtl/memory/poly_buffer.v

rtl/ntt/zetas_rom.v
rtl/ntt/butterfly_unit.v
rtl/ntt/intt_butterfly_unit.v
rtl/ntt/ntt_addr_gen.v
rtl/ntt/ntt_core.v
```

The current verified forward NTT flow is:

```text
ntt_addr_gen
+ zetas_rom
+ poly_buffer
+ butterfly_unit
= ntt_core
```

---

## Known Verification Status

Current passing simulations include:

```text
run_mod_add.sh
run_mod_sub.sh
run_reduction.sh
run_mod_mul.sh
run_zetas_rom.sh
run_butterfly_unit.sh
run_ntt_addr_gen.sh
run_ntt_core.sh
```

Known remaining verification gap:

```text
rtl/ntt/intt_butterfly_unit.v currently needs a dedicated self-checking testbench.
```

Before implementing or debugging `intt_core.v`, add and run:

```text
tb/unit/tb_intt_butterfly_unit.v
sim/scripts/run_intt_butterfly_unit.sh
reports/simulation/intt_butterfly_unit_report.md
```

---

## Simulation Rules

Each RTL module should have:

```text
tb/unit/ or tb/block/ testbench
sim/scripts/run_<module>.sh
reports/simulation/<module>_report.md
```

Simulation scripts should:

```text
- create required sim directories if missing
- compile with iverilog -g2012
- include rtl/common
- write compiled output into sim/outputs/
- write logs into sim/logs/
- write waves into sim/waves/ when useful
- return nonzero exit code on failure
```

Use self-checking testbenches.

A testbench should:

```text
- print clear PASS/FAIL
- count pass/fail cases
- show exact mismatch values
- include directed tests
- include randomized tests when useful
- compare against a behavioral reference model
```

Do not only check that a module compiles.

---

## NTT / INTT Notes

Forward NTT reference:

```c
k = 1;
for (len = 128; len >= 2; len >>= 1) {
    for (start = 0; start < 256; start = j + len) {
        zeta = zetas[k++];
        for (j = start; j < start + len; j++) {
            t = fqmul(zeta, r[j + len]);
            r[j + len] = r[j] - t;
            r[j]       = r[j] + t;
        }
    }
}
```

Forward RTL butterfly convention:

```text
t     = mod_mul(zeta, b)
out_a = mod_add(a, t)
out_b = mod_sub(a, t)
```

Inverse NTT reference:

```c
k = 0;
for (len = 2; len <= 128; len <<= 1) {
    for (start = 0; start < 256; start = j + len) {
        zeta = zetas_inv[k++];
        for (j = start; j < start + len; j++) {
            t = r[j];
            r[j] = barrett_reduce(t + r[j + len]);
            r[j + len] = t - r[j + len];
            r[j + len] = fqmul(zeta, r[j + len]);
        }
    }
}

for (j = 0; j < 256; j++)
    r[j] = fqmul(r[j], zetas_inv[127]);
```

Inverse RTL butterfly convention:

```text
sum   = mod_add(a, b)
diff  = mod_sub(a, b)
out_a = sum
out_b = mod_mul(zeta, diff)
```

The final INTT scaling by `zetas_inv[127]` belongs in `intt_core.v`, not in `intt_butterfly_unit.v`.

---

## Current Near-Term Roadmap

Recommended next steps:

```text
1. Add self-checking TB for intt_butterfly_unit.v
2. Harden ntt_core load_allowed gating if needed
3. Implement intt_core.v
4. Add tb/block/tb_intt_core.v
5. Test NTT → INTT round trip
6. Implement basemul_unit.v
7. Implement poly-level wrappers
```

Do not jump to INDCPA or KEM before NTT, INTT, basemul, poly, and polyvec are verified.

---

## Physical Design Policy

The `pd/` directory is reserved for physical design work.

Do not modify it unless explicitly requested.

Current project phase is RTL and simulation verification. Synthesis, Innovus, floorplan, CTS, routing, STA, and GDSII work are later milestones.

---

## Reports Policy

When adding or changing a module test, update the matching report in:

```text
reports/simulation/
```

A report should include:

```text
- module name
- purpose
- files tested
- reference behavior
- test strategy
- commands used
- PASS/FAIL result
- known limitations
```

---

## TODO Policy

For meaningful changes, update `TODO.md`.

Use it to track:

```text
- completed blocks
- current active block
- verification gaps
- next recommended step
- known issues
```

Do not leave TODO.md stale after adding new RTL or tests.

---

## Git / Change Policy

Before finishing a task, run:

```bash
git diff --check
```

When relevant, also run the module simulation script.

Good commit style:

```text
rtl: add <module>
tb: add <module> self-checking testbench
sim: add run script for <module>
docs: update <topic> notes
reports: add <module> simulation report
```

Avoid giant mixed commits.

---

## Agent Behavior Rules

Before making changes:

```text
1. inspect the relevant files
2. identify the minimal affected scope
3. avoid unrelated cleanup
4. preserve working tests
```

After making changes:

```text
1. show files changed
2. show command run
3. show PASS/FAIL result
4. mention remaining gaps honestly
```

If a failure occurs:

```text
- do not guess
- show the first mismatch
- classify whether it is likely RTL, testbench, script, or reference-model issue
- propose the smallest next debug step
```

---

## Final Goal

The long-term goal is a complete ML-KEM-768 RTL implementation that can be verified, synthesized, and eventually taken through ASIC physical design.

Final deliverables should include:

```text
- clean RTL
- self-checking simulation
- reference-model comparison
- simulation reports
- synthesis reports
- PPA analysis
- layout screenshots
- final Vietnamese IEEE-style report
```
