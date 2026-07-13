# TODO

## Current Milestone

M4 complete; M5 Keccak-f1600, SHA3, and SHAKE architecture is next

## Completed

- [x] Initial repository exists
- [x] Roadmap file exists
- [x] Repository structure reorganized for ML-KEM-768 RTL and verification work
- [x] Current active phase excludes Genus, Innovus, PnR, STA, GDSII, and Physical Design
- [x] Root `AGENTS.md` symlink exists for project instructions
- [x] M0.1 source, standards, and provenance audit
- [x] M0.2 detailed FIPS 203 algorithm tracking
- [x] M0.3 legacy Kyber768 C/KAT harness
- [x] M0.4a independent Python foundation layer
- [x] M0.4b complete deterministic internal Python ML-KEM-768 golden model
- [x] M0.5 comparison tools, vector export infrastructure, and M0 closure
- [x] M1 v0.1 documentation-only architecture freeze
- [x] M2.1 synchronous memory and pipeline-control primitives
- [x] M2.2.1 pipelined modular addition and subtraction (mod_add_pipe, mod_sub_pipe)
- [x] M2.2.2 pipelined Montgomery reduction (montgomery_reduce_pipe)
- [x] M2.2.3 pipelined modular multiplier (mod_mul_pipe)
- [x] M2.2.4 pipelined Barrett reduction (barrett_reduce_pipe)
- [x] M2.2.5 pipelined forward butterfly (butterfly_pipe)
- [x] M2.2.6 pipelined inverse butterfly (intt_butterfly_pipe)
- [x] M2.2.7 unified arithmetic-pipeline regression & M2.3 handoff
- [x] M2.3a pipelined arithmetic synthesis infrastructure preparation (reproducible scripts, wrappers, and constraints completed)
- [x] M3.0 Fmax-oriented NTT/INTT audit and implementation plan (completed)
- [x] M3.1 Fmax-oriented forward NTT scheduler (completed)
- [x] M3.2 banked pipelined forward NTT core candidate v0 (completed)
- [x] M3.3 banked pipelined inverse NTT scheduler and core (completed)
- [x] M3.4 two-lane final inverse scaling pass (completed)
- [x] M3.5 independent NTT/INTT differential and roundtrip verification (completed)
- [x] M3.6 unified regression, architecture closure, interface freeze, and M4 handoff
- [x] M4.0 polynomial/polyvec architecture audit and contract freeze
- [x] M4.1 polynomial workspace and canonical arithmetic controllers
- [x] M4.2 polynomial forward/inverse NTT adapters and roundtrip verification
- [x] M4.3 exact BaseCaseMultiply and polynomial MultiplyNTTs engine
- [x] M4.4 ML-KEM-768 polyvec workspace and serialized elementwise controllers
- [x] M4.5 polyvec MultiplyNTTs accumulation engine
- [x] M4.6 unified M4 regression, architecture freeze, and handoff
- [x] M5.0 Keccak/SHA3/SHAKE audit and architecture freeze
- [x] M5.1 Keccak round and iterative Keccak-f[1600] permutation
- [x] M5.2 byte-stream sponge absorb/pad/squeeze and one-shot controller
- [x] M5.3 SHA3-256 and SHA3-512 stream wrappers
- [x] M5.4 SHAKE128 and SHAKE256 one-shot/incremental engines

## In Progress

- [ ] M2.3b: Server ASIC synthesis comparison and candidate selection (pending server execution)
- [ ] M5: Keccak-f1600, SHA3, and SHAKE engines

## Blocked By

- None

## Next Target

M5 Keccak-f1600/SHA3/SHAKE architecture audit, with M2.3b
server ASIC synthesis still pending. Final NIST CAVP/ACVP ML-KEM vector
verification remains pending.

## Current Focus

```text
standards and provenance -> FIPS algorithm tracking -> KAT provenance ->
independent golden models -> comparison tools -> architecture freeze -> RTL
```

## Project Priority

```text
1. Correctness
2. Timing closure / high operating frequency / Fmax
3. Throughput
4. Area
```

Fmax/timing closure is the main implementation priority after correctness.
Area is tracked, but it is not the leading objective. Main datapaths should
prefer pipelined high-frequency architecture; area-saving sequential variants
are comparison/reference variants only.

## Explicitly Excluded From Current Phase

- Genus
- Innovus
- PnR
- STA
- GDSII
- Physical Design

## Archived Prior Notes

The original `thoughts.txt` was preserved as `archive/thoughts.txt`. It contains early PQC hardware notes, including broader ML-DSA ideas. Current repository scope is ML-KEM-768 unless the project direction changes explicitly.

## Session Log

### 2026-07-13 M5.2-M5.4 Sponge, SHA3, and SHAKE

Requested: implement the incremental byte-stream sponge, bounded one-shot
controller, SHA3-256/512, SHAKE128/256, repeated squeeze, and protocol/reset/
backpressure verification without duplicating Keccak logic.

Changed: added the context/controller and four thin wrappers; deterministic
hashlib/pure-Python vectors; direct and wrapper TBs; bounded temporary runners;
and M5.2-M5.4 reports. Pre-M5 RTL and reference semantics are unchanged.

Commands run: all context/hash/SHA3/SHAKE runners under hard timeouts, dual
vector regeneration/diff, compile/lint, artifact checks, and `git diff --check`.

Verified: 320 one-shot and 320 incremental vectors; 21,174 bytes each path;
80 vectors per algorithm; SHA3 byte counts 2,560/5,120 and SHAKE counts
6,747/6,747. Irregular absorbs and 3,601 squeeze requests pass. Empty/exact/
multi-rate padding, suffixes, backpressure, seven error classes, reset at all
24 permutation rounds, stalled-output reset, and restart pass.

Remains: M5.5 wrappers, M5.6 unified closure, and M2.3b synthesis.

Next Session Start Here: implement H/G/J as fixed thin wrappers, PRF as exactly
`seed||nonce` with eta controlling length only, and continuing SHAKE128 XOF.

### 2026-07-13 M5.1 Keccak Round and Permutation

Requested: implement the exact FIPS 202 round and a single-state, one-round-per-
cycle Keccak-f[1600] core with independent trace, reset, and timing proof.

Changed: added `keccak_round.v`, `keccak_f1600_core.v`, a pure-Python round/
permutation/sponge generator, mapping/round/core TBs, three bounded temporary
runners, and two reports. No pre-M5 RTL or reference semantics changed.

Commands run: deterministic two-directory generation/diff; state mapping,
round, and permutation runners under hard timeouts; `git diff --check`.

Verified: 2,072 full round states plus 24 intermediate traces pass; 132 full
permutations pass; 24-cycle start-to-done latency, one-cycle done, busy-start
error, reset at all 24 rounds, no stale output, and restart pass. Mapping proves
200 bytes, 1,600 bits, 25 lanes, and capacity exclusion. Python sponge matches
all four `hashlib` modes. No synthesis/Fmax claim exists.

Remains: M5.2-M5.6 and M2.3b server synthesis.

Next Session Start Here: implement `keccak_sponge_ctx.v` using the frozen mode,
padding, core-ownership, repeated-squeeze, reset, and backpressure contract.

### 2026-07-13 M5.0 Keccak/SHA3/SHAKE Architecture Freeze

Requested: audit existing Keccak/hash sources and freeze the FIPS 202 state,
byte-stream, padding, context, reset, and ML-KEM wrapper contracts before RTL.

Changed: added the M5.0 audit and frozen Keccak/SHA3/SHAKE contract; expanded
the FIPS 202 and Keccak architecture notes. No RTL, testbench, reference model,
standard, synthesis, PD, sampler, codec, or frozen-baseline file was changed.

Commands run: mandated repository/branch/status/log/stash/worktree/process and
artifact audits; read all startup/project/M4 sources; inspected both Keccak RTL
trees, the independent Python symmetric model, Kyber `fips202.c` and
`symmetric-shake.c`; extracted the relevant local FIPS 202, FIPS 203, and SP
800-185 PDF sections; ran `git diff --check` before the phase commit.

Verified: checkout is clean at the M4.6 starting checkpoint, no prior Keccak RTL
exists, frozen baseline is clean and unchanged, and the contract matches FIPS
lane order, little-endian bytes, rates, suffixes, and exact-boundary padding.

Remains: implement and verify M5.1-M5.6; M2.3b server synthesis remains pending.

Next Session Start Here: read `docs/04_design/keccak_sha3_shake_contract.md`
and `reports/m5_0_keccak_audit.md`, then implement the independently checked
combinational round and single-state iterative permutation.

### 2026-07-13 M4.6 Unified Closure

Added the isolated fail-fast `run_m4_regression.sh`, final regression and M4
completion reports, architecture indexes, and frozen handoff status. Command
`timeout 900s ./sim/scripts/run_m4_regression.sh` passed 33/33 programs,
996965 checks, in 103 seconds. All M4 generators regenerated byte-identically;
M3, M2, legacy adjacency, Python model/schema, reset/control, and structural
counts pass. M4 is complete. M5 RTL was not started; M2.3b remains pending.

Next Session Start Here: read `reports/m4_completion_report.md`, run the unified
M4 regression, then audit/freeze M5 Keccak/SHA3/SHAKE interfaces before RTL.

### 2026-07-13 M4.5 Polyvec MultiplyNTTs Accumulation

Added one-child K=3 dot-product controller, independent vectors, bounded
runner, K-PKE handoff, and report. Verified 32 vectors/8192 comparisons at
2757 cycles, exactly three polynomial products, 384 BaseCaseMultiply requests,
384 pair writes, and 512 canonical accumulation writes per result. Reset,
restart, domain, completeness, and overwrite controls pass. M4.6 remains.

### 2026-07-13 M4.4 K=3 Polyvec Workspace and Elementwise Engines

Added the three-polynomial synchronous workspace, one-child serialized
add/sub/reduce/NTT/INTT controller and wrappers, Python vectors, bounded
temporary runners, unit/block tests, and reports. Verified all 768 workspace
locations. Each operation passed 16 polyvecs and 12288 comparisons; cycles are
2731/2731/1963/5980/6385. The 16-vector transform roundtrip passed 12288
independent forward and 12288 final comparisons. Reset cancellation, restart,
domain, completeness, and overwrite controls pass. M4.5-M4.6 remain.

### 2026-07-13 M4.3 Exact MultiplyNTTs

Requested: audit Montgomery factors and implement exact BaseCaseMultiply and
polynomial MultiplyNTTs without changing legacy or M2/M3 semantics.

Changed: added an ordinary Barrett-based multiplier, an II=1 BaseCaseMultiply
pipeline, synchronous/domain-aware polynomial controller, deterministic vector
tooling, bounded temporary-directory runners, contracts, audit, and reports.

Verified: exact multiply 100000 checks at latency 4/II=1; BaseCaseMultiply
50000 checks at latency 9/II=1; polynomial MultiplyNTTs 32 vectors and 8192
comparisons at 142 cycles with exactly 128 requests/writes. Previous unified
M4.0-M4.2 regression remains 19/19 PASS. Montgomery-factor proof is frozen.

Remains: M4.4-M4.6, M2.3b server synthesis, and final CAVP/ACVP verification.
Next Session Start Here: implement the K=3 workspace and serialized elementwise
controllers using the frozen polynomial interfaces; do not duplicate M3 cores.

### 2026-07-13 M4.0-M4.2 Polynomial Architecture, Arithmetic, and NTT Adapters

Requested:

- Audit and freeze polynomial/polyvec domains and ownership, implement a
  synchronous polynomial workspace and canonical add/sub/reduce controllers,
  integrate frozen M3 forward/inverse engines through logical adapters, and
  stop before M4.3.

Files changed:

- Added the M4 domain contract and architecture audit; workspace, shared
  arithmetic/transform controllers and thin wrappers; unit/block TBs; bounded
  runners; deterministic vector generator; seven phase reports; and unified
  M4.0-M4.2 regression.
- Updated milestone status and the M3-to-M4 handoff. Existing legacy polynomial,
  M2 arithmetic, M3 engine, independent model, synthesis, and PD semantics were
  not changed.

Commands run:

- Startup repository/worktree/process/artifact audit and complete legacy
  polynomial/reference-model review.
- Focused workspace, add, sub, reduce, forward adapter, inverse adapter, and
  adapter roundtrip runners under 30-90 second timeouts.
- `timeout 180s ./sim/scripts/run_m3_regression.sh`
- `timeout 360s ./sim/scripts/run_m4_0_m4_2_regression.sh`
- Deterministic dual-directory generation/diff, debug-wave smoke check, final
  artifact/process/status review, and `git diff --check`.

Verified:

- Workspace 524 checks PASS; all 256 indices read back after sequential and
  arbitrary-order loads; ownership/domain/reset/reuse behavior PASS.
- Add/sub/reduce each pass 32 vectors and 8192 Python comparisons; measured
  cycles are 132/132/134.
- Forward/inverse adapters each pass 32 vectors and 8192 comparisons; measured
  cycles are 1473/1608. Roundtrip passes 30 vectors and 15360 comparisons.
- Unified regression passes 19/19 programs and 741497 checks in 45 seconds;
  M3 unified, M2, legacy adjacency, Python/schema, and vector reproducibility
  remain PASS.

Remains to do:

- M4.3 pointwise/basemul orchestration and polyvec accumulation.
- M2.3b server synthesis and final NIST CAVP/ACVP verification remain pending.
- No synthesis/Fmax claim exists.

Next Session Start Here:

1. Read `docs/04_design/poly_polyvec_engine_contract.md` and the M4.0-M4.2
   completion report.
2. Run `sim/scripts/run_m4_0_m4_2_regression.sh` before M4.3 changes.
3. Freeze POINTWISE-domain and accumulation semantics before reusing legacy
   basemul RTL.

### 2026-07-13 M3.6 Unified Regression and Architecture Closure

Requested:

- Close M3 with one bounded, fail-fast regression; audit interfaces and
  deterministic vectors; freeze the NTT/INTT contract; and prepare an M4
  handoff without implementing M4 functional RTL.

Files changed:

- Added `sim/scripts/run_m3_regression.sh`, the M3.6 unified report, M3
  completion report, frozen engine contract, and M4 handoff contract.
- Extended forward/inverse core TBs with cycle-window, unique logical-write,
  pending-at-done, and write-valid/metadata invariants.
- Added conditional `DEBUG_WAVES=1` dumps to the six M3 tests and propagated
  the flag through their bounded runners; default regression remains wave-free.
- Added deterministic vector metadata/range validation to both M3 generators.
- Corrected the forward scheduler to the frozen synchronous reset contract and
  corrected stale inverse-layout/scaler-bandwidth architecture documentation.
- Updated `TODO.md`, milestone status, M3 plan, and architecture index.

Commands run:

- Repository/branch/status/log/stash/worktree/process/artifact audits.
- Focused forward scheduler, forward core, and inverse core regressions.
- `bash -n sim/scripts/run_m3_regression.sh`
- `timeout 180s ./sim/scripts/run_m3_regression.sh`
- Final status, artifact, process, diff review, and `git diff --check` gates.

Verified:

- Unified regression PASS: 22/22 programs, 361656 internal checks, 21 seconds
  on the final clean-tree run.
- Forward differential PASS: 28 polynomials, 7168 comparisons, 955 cycles.
- Inverse differential PASS: 31 polynomials, 7936 comparisons; inverse stages
  954 cycles and full scaled inverse 1090 cycles.
- Roundtrip PASS: 30 polynomials, 7680 independent forward and 7680 final
  comparisons. Deterministic M3 vectors regenerate byte-identically.
- Structural, reset/control, M2 arithmetic/memory, legacy adjacency, Python
  model/schema, and cleanliness gates pass.

Remains to do:

- Run M2.3b server ASIC synthesis comparison; no synthesis/Fmax claim exists.
- Begin M4 polynomial/polyvec RTL only as a separate explicitly scoped task.
- Final NIST CAVP/ACVP ML-KEM verification remains pending.

Next Session Start Here:

1. Read `docs/04_design/ntt_intt_engine_contract.md` and the M3 completion report.
2. Use `sim/scripts/run_m3_regression.sh` as the M3 preservation gate.
3. Plan one coherent M4 controller/adapter milestone without bypassing logical
   preload/readback or canonical domain metadata.

### 2026-07-13 M3.3-M3.5 Pipelined Inverse NTT Closure

Requested:

- Derive inverse bank layouts from committed M3.2, implement the seven-stage inverse scheduler/core and two-lane final scaler, add independent inverse and pipelined roundtrip differential verification, preserve regressions, document, and commit only after all gates pass.

Files changed:

- Added inverse scheduler/core/scaler RTL, two unit TBs, two block TBs, four bounded runners, deterministic layout/vector tools, and M3.3/M3.4/M3.5 reports.
- Updated `docs/00_project_spec/m3_plan.md`, `docs/00_project_spec/milestone_status.md`, and `TODO.md`.

Commands run:

- `python3 tb/tools/check_ntt_layouts.py`
- `timeout 30s ./sim/scripts/run_intt_scheduler_pipe.sh`
- `timeout 30s ./sim/scripts/run_intt_scaler_pipe.sh`
- `timeout 45s ./sim/scripts/run_intt_core_pipe.sh`
- `timeout 45s ./sim/scripts/run_ntt_intt_pipe_roundtrip.sh`
- `timeout 30s ./sim/scripts/run_ntt_scheduler_pipe.sh`
- `timeout 30s ./sim/scripts/run_ntt_core_pipe.sh`
- `timeout 90s ./sim/scripts/run_m2_2_regression.sh`
- Legacy NTT, INTT, roundtrip, poly add/sub, basemul, basemul address, and poly basemul runners under 60-second timeouts.
- Python selftest, foundation unittest, comparator unittest, and duplicate deterministic vector generation/`cmp` checks.

Verified:

- Layout proof: eight bijective layouts and 896 conflict-free requests in each direction.
- Inverse scheduler/core: 896 reads/responses/inputs/outputs/writes and seven drains/swaps/advances.
- Scaler: two lanes, four-cycle multiplier latency, six-cycle issue-to-write latency, 128 requests, 256 inputs/outputs, 128 writes, operand 512.
- Measured cycles: inverse stages 954; scale first/final issue 955/1082; final write 1088; final swap 1089; public done 1090.
- Standalone inverse: 31 polynomials and 7936 coefficient comparisons PASS.
- Roundtrip: 30 polynomials, 7680 forward and 7680 final coefficient comparisons PASS.
- Reset/control, M2/M3, legacy adjacency, Python model/comparator, deterministic reproduction, and `git diff --check` PASS.

Remains to do:

- Run M2.3b server ASIC synthesis comparison.
- Plan M4 polynomial/polyvec engines.
- Final NIST CAVP/ACVP ML-KEM verification remains pending.

Next Session Start Here:

- Review the three M3.3-M3.5 reports, then choose M2.3b server synthesis or M4 planning.

### 2026-07-13 M3.2 Banked Pipelined Forward NTT Core

Requested:

- Recover the incomplete Antigravity M3.2 attempt, diagnose the timeout/deadlock, implement and verify a banked pipelined forward NTT core, preserve M0-M3.1 regressions, document the handoff, and commit only after required tests pass.

Files changed:

- Added [ntt_core_pipe.v](file:///home/hien/Projects/Post_Quantum_Cryptography/rtl/ntt/ntt_core_pipe.v).
- Added [tb_ntt_core_pipe.v](file:///home/hien/Projects/Post_Quantum_Cryptography/tb/block/tb_ntt_core_pipe.v).
- Added [run_ntt_core_pipe.sh](file:///home/hien/Projects/Post_Quantum_Cryptography/sim/scripts/run_ntt_core_pipe.sh).
- Added [gen_ntt_core_pipe_vectors.py](file:///home/hien/Projects/Post_Quantum_Cryptography/tb/tools/gen_ntt_core_pipe_vectors.py).
- Added [m3_2_ntt_core_report.md](file:///home/hien/Projects/Post_Quantum_Cryptography/reports/simulation/m3_2_ntt_core_report.md).
- Updated [ntt_scheduler_pipe.v](file:///home/hien/Projects/Post_Quantum_Cryptography/rtl/ntt/ntt_scheduler_pipe.v) to correct forward transition layout metadata.
- Updated [tb_ntt_scheduler_pipe.v](file:///home/hien/Projects/Post_Quantum_Cryptography/tb/unit/tb_ntt_scheduler_pipe.v) to check destination-bank collisions.
- Updated [m3_plan.md](file:///home/hien/Projects/Post_Quantum_Cryptography/docs/00_project_spec/m3_plan.md), [milestone_status.md](file:///home/hien/Projects/Post_Quantum_Cryptography/docs/00_project_spec/milestone_status.md), and [TODO.md](file:///home/hien/Projects/Post_Quantum_Cryptography/TODO.md).

Commands run:

- `pwd`
- `git branch --show-current`
- `git status --short`
- `git log --oneline -8`
- `git stash list`
- `git worktree list`
- `git stash show --include-untracked --stat stash@{0}`
- `git stash show --include-untracked -p stash@{0}`
- `pkill -f tb_ntt_core_pipe.vvp || true`
- `pkill -f run_ntt_core_pipe.sh || true`
- `timeout 30s ./sim/scripts/run_ntt_core_pipe.sh; echo "exit_status=$?"` on recovered WIP
- `./sim/scripts/run_ntt_core_pipe.sh`
- `./sim/scripts/run_ntt_scheduler_pipe.sh`
- `timeout 60s ./sim/scripts/run_m2_2_regression.sh`
- `timeout 60s ./sim/scripts/run_ntt_core.sh && timeout 60s ./sim/scripts/run_intt_core.sh && timeout 60s ./sim/scripts/run_ntt_intt_roundtrip.sh && timeout 60s ./sim/scripts/run_poly_add.sh && timeout 60s ./sim/scripts/run_poly_sub.sh && timeout 60s ./sim/scripts/run_basemul_unit.sh && timeout 60s ./sim/scripts/run_poly_basemul_addr_gen.sh && timeout 60s ./sim/scripts/run_poly_basemul_montgomery.sh`
- `timeout 30s ./sim/scripts/run_ntt_scheduler_pipe.sh && timeout 30s ./sim/scripts/run_ntt_core_pipe.sh`
- `timeout 30s python3 -m ref_model.python_model.selftest`
- `timeout 30s python3 -m pytest ref_model/python_model/test_foundations.py ref_model/compare/test_compare_tools.py` (blocked: pytest not installed)
- `timeout 30s python3 -m ref_model.python_model.test_foundations && timeout 30s python3 -m ref_model.compare.test_compare_tools && timeout 30s python3 -m ref_model.compare.generate_vectors --output /tmp/mlkem768_smoke_check.json && timeout 30s python3 -m ref_model.compare.compare_vectors ref_model/compare/vectors/mlkem768_smoke.json /tmp/mlkem768_smoke_check.json`

Verified:

- Recovered M3.2 stash was preserved and classified as unsafe/partially reusable; it contained only three untracked M3.2 files.
- Reproduced previous WIP timeout: `exit_status=124`.
- Root cause identified: stale constant-`r=7` transition metadata caused destination-bank collision at stage 1, group 0, butterfly 0; previous WIP also swapped roles without pending-traffic drain.
- `tb_ntt_core_pipe` passed 28 Python-model differential polynomials, 7168 coefficient comparisons, control/error checks, reset/restart checks, and exact structural counts.
- Measured start-to-done transform cycles: 955.
- Measured issue-to-write-commit latency: 7 cycles.
- Counts per transform: 896 reads, 896 RAM responses, 896 butterfly inputs, 896 butterfly outputs, 896 committed writes, 7 stage drains, 7 stage swaps, 7 stage advances.
- M2.1/M2.2 regression passed.
- M3.1 scheduler regression passed with new destination-bank collision check.
- Legacy NTT/INTT/roundtrip/poly/basemul adjacency regressions passed.
- Python selftests, unittest checks, and smoke-vector regeneration/compare passed.

Remains to do:

- Run M2.3b server ASIC synthesis comparison.
- Plan the next M3 NTT/INTT milestone.
- Final NIST CAVP/ACVP ML-KEM vector verification remains pending.

Next Session Start Here:

- Review the M3.2 report, then decide whether to proceed to the next NTT/INTT milestone or run M2.3b server synthesis.

### 2026-07-13 M2.3 ASIC Synthesis Comparison

Requested:

- Implement M2.3: focused ASIC synthesis comparison of M2.2 arithmetic candidates.

Files changed:

- Added synthesis-only wrappers for combinational legacy blocks under [synth/m2_3/wrappers/](file:///home/hien/Projects/Post_Quantum_Cryptography/synth/m2_3/wrappers/).
- Added SDC constraints file [constraints.sdc](file:///home/hien/Projects/Post_Quantum_Cryptography/synth/m2_3/constraints.sdc).
- Added Cadence Genus synthesis script [genus_synth.tcl](file:///home/hien/Projects/Post_Quantum_Cryptography/synth/m2_3/genus_synth.tcl).
- Added Yosys synthesis script [yosys_synth.tcl](file:///home/hien/Projects/Post_Quantum_Cryptography/synth/m2_3/yosys_synth.tcl).
- Added synthesis sweep runner script [run_synth_sweep.sh](file:///home/hien/Projects/Post_Quantum_Cryptography/synth/m2_3/run_synth_sweep.sh).
- Added synthesis report [m2_3_synthesis_comparison.md](file:///home/hien/Projects/Post_Quantum_Cryptography/reports/m2_3_synthesis_comparison.md).
- Updated [TODO.md](file:///home/hien/Projects/Post_Quantum_Cryptography/TODO.md) and [milestone_status.md](file:///home/hien/Projects/Post_Quantum_Cryptography/docs/00_project_spec/milestone_status.md).

Commands run:

- `./sim/scripts/run_m2_2_regression.sh` (pre-synthesis regression check)
- `chmod +x synth/m2_3/run_synth_sweep.sh && ./synth/m2_3/run_synth_sweep.sh`
- `./sim/scripts/run_m2_2_regression.sh` (post-synthesis regression verification)

Verified:

- Blocker verified: No ASIC synthesis tools (Genus, Yosys, Design Compiler) or Liberty PDK files are present in the environment PATH.
- Reproducible synthesis sweep runner and tcl scripts verified correctly falling back to printing the blocker.
- Unified regression runs and passes all 10 unit tests successfully.
- Functional RTL verification shows no changes made to any functional modules.

Remains to do:

- Run M2.3b server ASIC synthesis.
- Implement M3.2 banked NTT forward core integration.

Next Session Start Here:

- Begin M3.2 design and implementation.

### 2026-07-13 M3.1 Forward NTT Address Scheduler

Requested:

- Implement M3.1: forward NTT scheduler and address-generation candidate v0.
- Correct docs/00_project_spec/m3_plan.md cycle labels.

Files changed:

- Added [ntt_scheduler_pipe.v](file:///home/hien/Projects/Post_Quantum_Cryptography/rtl/ntt/ntt_scheduler_pipe.v)
- Added [tb_ntt_scheduler_pipe.v](file:///home/hien/Projects/Post_Quantum_Cryptography/tb/unit/tb_ntt_scheduler_pipe.v)
- Added [run_ntt_scheduler_pipe.sh](file:///home/hien/Projects/Post_Quantum_Cryptography/sim/scripts/run_ntt_scheduler_pipe.sh)
- Added [m3_1_ntt_scheduler_report.md](file:///home/hien/Projects/Post_Quantum_Cryptography/reports/simulation/m3_1_ntt_scheduler_report.md)
- Updated [m3_plan.md](file:///home/hien/Projects/Post_Quantum_Cryptography/docs/00_project_spec/m3_plan.md), [TODO.md](file:///home/hien/Projects/Post_Quantum_Cryptography/TODO.md), and [milestone_status.md](file:///home/hien/Projects/Post_Quantum_Cryptography/docs/00_project_spec/milestone_status.md).

Commands run:

- `chmod +x sim/scripts/run_ntt_scheduler_pipe.sh && ./sim/scripts/run_ntt_scheduler_pipe.sh`
- `./sim/scripts/run_m2_1_primitives.sh && ./sim/scripts/run_m2_2_regression.sh`

Verified:

- Checked all 896 Cooley-Tukey butterfly requests.
- Validated correct source read bank mapping (no collisions).
- Verified zeta ROM addresses sweep stages and remain constant per group.
- Checked pause-and-wait FSM behavior with stage_advance controls.
- Validated FSM illegal transitions error output.
- All M2 regressions passed.




### 2026-07-13 M2.2.7 Unified Handoff

Requested:

- Implement M2.2.7: Unified arithmetic-pipeline regression & M2.3 handoff.

Files changed:

- Added unified regression script [run_m2_2_regression.sh](file:///home/hien/Projects/Post_Quantum_Cryptography/sim/scripts/run_m2_2_regression.sh).
- Added [m2_2_unified_handoff_report.md](file:///home/hien/Projects/Post_Quantum_Cryptography/reports/simulation/m2_2_unified_handoff_report.md).
- Updated [TODO.md](file:///home/hien/Projects/Post_Quantum_Cryptography/TODO.md) and [milestone_status.md](file:///home/hien/Projects/Post_Quantum_Cryptography/docs/00_project_spec/milestone_status.md).

Commands run:

- `chmod +x sim/scripts/run_m2_2_regression.sh`
- `./sim/scripts/run_m2_2_regression.sh`
- Rerun of all legacy core, roundtrip, and polynomial tests.

Verified:

- Unified regression script runs and passes all 10 unit testbenches.
- Summary table maps all pipelined modules correctly.
- All pipeline contracts, delays, widths, and reset characteristics are verified compliant.

Remains to do:

- Await M2 completion approval, then plan and start M2.3 synthesis gates.

Next Session Start Here:

- Start M2.3 synthesis planning.




### 2026-07-13 M2.2.6 Inverse Butterfly Implementation

Requested:

- Implement M2.2.6: Inverse NTT butterfly pipeline (`intt_butterfly_pipe`).

Files changed:

- Added [intt_butterfly_pipe.v](file:///home/hien/Projects/Post_Quantum_Cryptography/rtl/ntt/intt_butterfly_pipe.v).
- Added [tb_intt_butterfly_pipe.v](file:///home/hien/Projects/Post_Quantum_Cryptography/tb/unit/tb_intt_butterfly_pipe.v).
- Added run script [run_intt_butterfly_pipe.sh](file:///home/hien/Projects/Post_Quantum_Cryptography/sim/scripts/run_intt_butterfly_pipe.sh).
- Added [m2_2_6_inverse_butterfly_report.md](file:///home/hien/Projects/Post_Quantum_Cryptography/reports/simulation/m2_2_6_inverse_butterfly_report.md).
- Updated [TODO.md](file:///home/hien/Projects/Post_Quantum_Cryptography/TODO.md) and [milestone_status.md](file:///home/hien/Projects/Post_Quantum_Cryptography/docs/00_project_spec/milestone_status.md).

Commands run:

- `chmod +x sim/scripts/run_intt_butterfly_pipe.sh`
- `./sim/scripts/run_intt_butterfly_pipe.sh`
- `./sim/scripts/run_m2_1_primitives.sh && ./sim/scripts/run_mod_add_pipe.sh && ./sim/scripts/run_mod_sub_pipe.sh && ./sim/scripts/run_montgomery_reduce_pipe.sh && ./sim/scripts/run_mod_mul_pipe.sh && ./sim/scripts/run_barrett_reduce_pipe.sh && ./sim/scripts/run_butterfly_pipe.sh && ./sim/scripts/run_butterfly_unit.sh && ./sim/scripts/run_ntt_core.sh && ./sim/scripts/run_intt_core.sh && ./sim/scripts/run_ntt_intt_roundtrip.sh && ./sim/scripts/run_zetas_rom.sh`

Verified:

- `tb_intt_butterfly_pipe`: `pass_count=2007 fail_count=0`
- All legacy and adjacent regressions pass successfully.

Remains to do:

- Implement M2.2.7: Unified regression & handoff.

Next Session Start Here:

- Start M2.2.7.




### 2026-07-13 M2.2.5 Forward Butterfly Implementation

Requested:

- Implement M2.2.5: Forward NTT butterfly pipeline (`butterfly_pipe`).

Files changed:

- Added [butterfly_pipe.v](file:///home/hien/Projects/Post_Quantum_Cryptography/rtl/ntt/butterfly_pipe.v).
- Added [tb_butterfly_pipe.v](file:///home/hien/Projects/Post_Quantum_Cryptography/tb/unit/tb_butterfly_pipe.v).
- Added run script [run_butterfly_pipe.sh](file:///home/hien/Projects/Post_Quantum_Cryptography/sim/scripts/run_butterfly_pipe.sh).
- Added [m2_2_5_forward_butterfly_report.md](file:///home/hien/Projects/Post_Quantum_Cryptography/reports/simulation/m2_2_5_forward_butterfly_report.md).
- Updated [TODO.md](file:///home/hien/Projects/Post_Quantum_Cryptography/TODO.md) and [milestone_status.md](file:///home/hien/Projects/Post_Quantum_Cryptography/docs/00_project_spec/milestone_status.md).

Commands run:

- `chmod +x sim/scripts/run_butterfly_pipe.sh`
- `./sim/scripts/run_butterfly_pipe.sh`
- `./sim/scripts/run_m2_1_primitives.sh && ./sim/scripts/run_mod_add_pipe.sh && ./sim/scripts/run_mod_sub_pipe.sh && ./sim/scripts/run_montgomery_reduce_pipe.sh && ./sim/scripts/run_mod_mul_pipe.sh && ./sim/scripts/run_barrett_reduce_pipe.sh && ./sim/scripts/run_butterfly_unit.sh && ./sim/scripts/run_ntt_core.sh && ./sim/scripts/run_intt_core.sh && ./sim/scripts/run_ntt_intt_roundtrip.sh && ./sim/scripts/run_zetas_rom.sh`

Verified:

- `tb_butterfly_pipe`: `pass_count=2006 fail_count=0`
- All legacy and adjacent regressions pass successfully.

Remains to do:

- Implement M2.2.6: Inverse butterfly pipeline (`intt_butterfly_unit_pipe`).

Next Session Start Here:

- Start M2.2.6 design and implementation.




### 2026-07-13 M2.2.4 Implementation

Requested:

- Implement M2.2.4: Pipelined Barrett reduction (`barrett_reduce_pipe`).

Files changed:

- Added [barrett_reduce_pipe.v](file:///home/hien/Projects/Post_Quantum_Cryptography/rtl/arithmetic/barrett_reduce_pipe.v).
- Added [tb_barrett_reduce_pipe.v](file:///home/hien/Projects/Post_Quantum_Cryptography/tb/unit/tb_barrett_reduce_pipe.v).
- Added run script [run_barrett_reduce_pipe.sh](file:///home/hien/Projects/Post_Quantum_Cryptography/sim/scripts/run_barrett_reduce_pipe.sh).
- Added [m2_2_4_barrett_report.md](file:///home/hien/Projects/Post_Quantum_Cryptography/reports/simulation/m2_2_4_barrett_report.md).
- Updated [TODO.md](file:///home/hien/Projects/Post_Quantum_Cryptography/TODO.md) and [milestone_status.md](file:///home/hien/Projects/Post_Quantum_Cryptography/docs/00_project_spec/milestone_status.md).

Commands run:

- `chmod +x sim/scripts/run_barrett_reduce_pipe.sh`
- `./sim/scripts/run_barrett_reduce_pipe.sh`
- `./sim/scripts/run_m2_1_primitives.sh && ./sim/scripts/run_mod_add_pipe.sh && ./sim/scripts/run_mod_sub_pipe.sh && ./sim/scripts/run_montgomery_reduce_pipe.sh && ./sim/scripts/run_mod_mul_pipe.sh && ./sim/scripts/run_reduction.sh && ./sim/scripts/run_ntt_addr_gen.sh && ./sim/scripts/run_zetas_rom.sh`

Verified:

- `tb_barrett_reduce_pipe`: `pass_count=2014 fail_count=0`
- All legacy and adjacent regressions pass successfully.

Remains to do:

- Implement M2.2.5: Forward butterfly pipeline (`butterfly_unit_pipe`).

Next Session Start Here:

- Start M2.2.5 design and implementation.




### 2026-07-13 M2.2.3 Implementation

Requested:

- Implement M2.2.3: Pipelined modular multiplier (`mod_mul_pipe`).

Files changed:

- Added [mod_mul_pipe.v](file:///home/hien/Projects/Post_Quantum_Cryptography/rtl/arithmetic/mod_mul_pipe.v).
- Added [tb_mod_mul_pipe.v](file:///home/hien/Projects/Post_Quantum_Cryptography/tb/unit/tb_mod_mul_pipe.v).
- Added run script [run_mod_mul_pipe.sh](file:///home/hien/Projects/Post_Quantum_Cryptography/sim/scripts/run_mod_mul_pipe.sh).
- Added [m2_2_3_mod_mul_report.md](file:///home/hien/Projects/Post_Quantum_Cryptography/reports/simulation/m2_2_3_mod_mul_report.md).
- Updated [TODO.md](file:///home/hien/Projects/Post_Quantum_Cryptography/TODO.md) and [milestone_status.md](file:///home/hien/Projects/Post_Quantum_Cryptography/docs/00_project_spec/milestone_status.md).
- Updated [tb_montgomery_reduce_pipe.v](file:///home/hien/Projects/Post_Quantum_Cryptography/tb/unit/tb_montgomery_reduce_pipe.v) to fix random sign logic.

Commands run:

- `chmod +x sim/scripts/run_mod_mul_pipe.sh`
- `./sim/scripts/run_mod_mul_pipe.sh`
- `./sim/scripts/run_m2_1_primitives.sh && ./sim/scripts/run_mod_add_pipe.sh && ./sim/scripts/run_mod_sub_pipe.sh && ./sim/scripts/run_reduction.sh && ./sim/scripts/run_mod_mul.sh && ./sim/scripts/run_ntt_addr_gen.sh && ./sim/scripts/run_zetas_rom.sh`

Verified:

- `tb_mod_mul_pipe`: `pass_count=2009 fail_count=0`
- All legacy and adjacent regressions pass successfully.

Remains to do:

- Implement M2.2.4: Pipelined Barrett reduction (`barrett_reduce_pipe`).

Next Session Start Here:

- Start M2.2.4 design and implementation.




### 2026-07-13 M2.2.2 Implementation

Requested:

- Implement M2.2.2: Pipelined Montgomery reduction (`montgomery_reduce_pipe`).

Files changed:

- Added [montgomery_reduce_pipe.v](file:///home/hien/Projects/Post_Quantum_Cryptography/rtl/arithmetic/montgomery_reduce_pipe.v).
- Added [tb_montgomery_reduce_pipe.v](file:///home/hien/Projects/Post_Quantum_Cryptography/tb/unit/tb_montgomery_reduce_pipe.v).
- Added run script [run_montgomery_reduce_pipe.sh](file:///home/hien/Projects/Post_Quantum_Cryptography/sim/scripts/run_montgomery_reduce_pipe.sh).
- Added [m2_2_2_montgomery_report.md](file:///home/hien/Projects/Post_Quantum_Cryptography/reports/simulation/m2_2_2_montgomery_report.md).
- Updated [TODO.md](file:///home/hien/Projects/Post_Quantum_Cryptography/TODO.md) and [milestone_status.md](file:///home/hien/Projects/Post_Quantum_Cryptography/docs/00_project_spec/milestone_status.md).

Commands run:

- `chmod +x sim/scripts/run_montgomery_reduce_pipe.sh`
- `./sim/scripts/run_montgomery_reduce_pipe.sh`
- `./sim/scripts/run_m2_1_primitives.sh && ./sim/scripts/run_mod_add_pipe.sh && ./sim/scripts/run_mod_sub_pipe.sh && ./sim/scripts/run_reduction.sh && ./sim/scripts/run_mod_mul.sh`

Verified:

- `tb_montgomery_reduce_pipe`: `pass_count=1010 fail_count=0`
- All legacy and adjacent regressions pass successfully.

Remains to do:

- Implement M2.2.3: Pipelined modular multiplier (`mod_mul_pipe`).

Next Session Start Here:

- Start M2.2.3 design and implementation.




### 2026-07-13 M2.2.1 Implementation

Requested:

- Implement M2.2.1: Pipelined modular add (`mod_add_pipe`) and subtract (`mod_sub_pipe`).

Files changed:

- Added [mod_add_pipe.v](file:///home/hien/Projects/Post_Quantum_Cryptography/rtl/arithmetic/mod_add_pipe.v) and [mod_sub_pipe.v](file:///home/hien/Projects/Post_Quantum_Cryptography/rtl/arithmetic/mod_sub_pipe.v).
- Added [tb_mod_add_pipe.v](file:///home/hien/Projects/Post_Quantum_Cryptography/tb/unit/tb_mod_add_pipe.v) and [tb_mod_sub_pipe.v](file:///home/hien/Projects/Post_Quantum_Cryptography/tb/unit/tb_mod_sub_pipe.v).
- Added run scripts [run_mod_add_pipe.sh](file:///home/hien/Projects/Post_Quantum_Cryptography/sim/scripts/run_mod_add_pipe.sh) and [run_mod_sub_pipe.sh](file:///home/hien/Projects/Post_Quantum_Cryptography/sim/scripts/run_mod_sub_pipe.sh).
- Added [m2_2_1_primitives_report.md](file:///home/hien/Projects/Post_Quantum_Cryptography/reports/simulation/m2_2_1_primitives_report.md).
- Updated [TODO.md](file:///home/hien/Projects/Post_Quantum_Cryptography/TODO.md) and [milestone_status.md](file:///home/hien/Projects/Post_Quantum_Cryptography/docs/00_project_spec/milestone_status.md).

Commands run:

- `chmod +x sim/scripts/run_mod_add_pipe.sh sim/scripts/run_mod_sub_pipe.sh`
- `./sim/scripts/run_mod_add_pipe.sh`
- `./sim/scripts/run_mod_sub_pipe.sh`
- `./sim/scripts/run_m2_1_primitives.sh && ./sim/scripts/run_mod_add.sh && ./sim/scripts/run_mod_sub.sh && ./sim/scripts/run_reduction.sh && ./sim/scripts/run_mod_mul.sh`

Verified:

- `tb_mod_add_pipe`: `pass_count=149236 fail_count=0`
- `tb_mod_sub_pipe`: `pass_count=149236 fail_count=0`
- Legacy and adjacent regressions pass successfully.

Remains to do:

- Implement M2.2.2: Pipelined Montgomery reduction (`montgomery_reduce_pipe`).

Next Session Start Here:

- Start M2.2.2 design and implementation.


### 2026-07-13 Context Reconstruction and M2.2 Audit/Plan

Requested:

- Context reconstruction from repository and M2.2 audit/plan proposal.

Files changed:

- Added [m2_2_audit_and_plan.md](file:///home/hien/.gemini/antigravity-cli/brain/7c5a6c69-9b6a-48af-a650-9a0ea35c75b4/m2_2_audit_and_plan.md) artifact.

Commands run:

- `pwd && git branch --show-current && git status --short && git log --oneline --decorate -5 && git worktree list`

Verified:

- Git branch is `test`, workspace clean.
- M2.1 primitives report and testbench PASS results.

Remains to do:

- Await approval of the proposed M2.2 plan.

Next Session Start Here:

- Implement the M2.2 arithmetic blocks once the plan is approved.


### 2026-07-04 Repository Reorganization

Requested:

- Reorganize the repository into a professional research, RTL, simulation, synthesis, PNR, report, and archive structure for a two-year ML-KEM-768 RTL-to-GDSII project.

Files changed:

- Moved reference PDFs, Kyber reference package, math/architecture papers, RTL, testbench, simulation files, and old notes into the new structure.
- Created documentation scaffold, folder READMEs, `CHANGELOG.md`, `TODO.md`, `references/links.md`, and project status files.
- Updated `README.md`.
- Updated simulation filelists to point at the moved RTL and testbench paths.

Commands run:

- `pwd`
- `find . -maxdepth 3 -type f | sort`
- `find . -maxdepth 3 -type d | sort`
- `git status --short`
- `sed -n ...` on project docs, workflow, RTL, testbench, and simulation files
- `git branch --show-current`
- `git log --oneline -n 5`
- `mkdir -p ...`
- `mv ...`
- `rmdir ...`
- `apply_patch` for README, TODO, CHANGELOG, filelists, and documentation scaffold
- `find . -maxdepth 3 -type d | sort`
- `git status --short`

Verified:

- Existing Verilog files were moved without logic changes.
- Legacy empty directories were removed only after their useful contents were moved.
- Final directory tree and Git status were inspected.

Remains to do:

- Review mandatory standards and populate notes.
- Decide exact golden reference model source and KAT format.
- Review RTL before claiming synthesizability or cryptographic correctness.

### 2026-07-04 PD Placeholder Adjustment

Requested:

- Keep PD as an empty placeholder because physical design will run on the server and the folder structure will be controlled later.

Files changed:

- Removed the active generated PD documentation/PNR scaffold from the project structure.
- Created `pd/` as the active server-controlled PD placeholder.
- Updated README, project spec, roadmap, docs overview, PPA plan, CHANGELOG, and TODO references.

Commands run:

- `sed -n '1,260p' TODO.md`
- `find docs/05_physical_design pnr synth -maxdepth 4 -type f | sort`
- `find docs/05_physical_design pnr synth -maxdepth 4 -type d | sort`
- `git status --short`
- `mkdir -p pd`
- `rg -n ...`
- `apply_patch`
- `find . -maxdepth 3 -type d | sort`
- `find pd -maxdepth 2 -type f -o -type d | sort`
- `rg -n 'docs/05_physical_design|pnr/innovus|Place Innovus|physical design planning' README.md docs CHANGELOG.md`
- `git status --short`

Verified:

- Active PD workspace is now the empty `pd/` directory.
- Active README/docs no longer point to `docs/05_physical_design/` or `pnr/innovus/`.

Remains to do:

- Define the `pd/` structure later when the server-side flow is ready.

### 2026-07-04 Git Ignore And GitHub Push

Requested:

- Rewrite `.gitignore` and push the repository to GitHub.

Files changed:

- Rewrote `.gitignore` for simulator, reference-model, synthesis, PD, editor, cache, and temporary artifacts.
- Added `.gitkeep` placeholders so empty project workspaces appear on GitHub, including `pd/`.
- Preserved the old tracked root `thoughts.txt` content under `archive/thoughts.txt`.
- Updated roadmap filename references to the current `Roadmap.md`.
- Restored the `synth/genus/` placeholder documentation and subfolders.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,260p' TODO.md`
- `sed -n '1,260p' .gitignore`
- `git status --short`
- `git remote -v`
- `find . -maxdepth 3 -type f | sort`
- `ls -la`
- `git ls-files`
- `rg -n ...`
- `du -sh . references docs ref_model`
- `apply_patch`
- `git check-ignore -v sim/logs/test.log pd/runs/run1/foo.rpt references/standards/NIST.FIPS.203.pdf pd/.gitkeep sim/logs/.gitkeep`
- `find . -maxdepth 3 -type d | sort`
- `git add -A`
- `git diff --cached --stat`
- `git diff --cached --name-status`
- `git commit -m "chore: reorganize mlkem project structure"`
- `git push origin main`

Verified:

- Generated simulation logs and PD run outputs are ignored.
- `pd/.gitkeep` and other workspace placeholders are trackable.
- Reference PDFs are not ignored.
- Active docs reference `Roadmap.md`.

Remains to do:

- Continue Phase 0 document control.

### 2026-07-04 Current Phase Simplification

Requested:

- Simplify the active repository focus to ML-KEM/Kyber documents and notes, reference models, KATs, Verilog RTL, testbenches, simulation, architecture, and verification.
- Move all original PDF papers and standards into `references/`.
- Keep `docs/` for notes and plans written by us.
- Leave `pd/` untouched.
- Update README, TODO, and milestone status to `M1: Algorithm and Verification Foundation`.

Files changed:

- Moved PDFs from `docs/02_math/`, `docs/03_architecture/`, and the Kyber submission supporting documentation folder into `references/papers/`.
- Moved inactive `synth/` scaffold and non-simulation report placeholders into `archive/inactive_flow_scaffold_2026-07-04/`.
- Moved `docs/03_architecture/ppa_plan.md` into `archive/inactive_flow_scaffold_2026-07-04/`.
- Updated `README.md`, `TODO.md`, `docs/00_project_spec/milestone_status.md`, `docs/00_project_spec/project_spec.md`, `docs/00_project_spec/roadmap.md`, `reports/README.md`, `references/links.md`, `docs/03_architecture/README.md`, and `CHANGELOG.md`.

Commands run:

- `sed -n '1,260p' TODO.md`
- `find . -maxdepth 3 -type d | sort`
- `find . -maxdepth 4 -type f | sort`
- `git status --short`
- `rg -n ...`
- `mv ...`
- `mkdir -p archive/inactive_flow_scaffold_2026-07-04/reports`
- `mkdir -p references/papers/kyber_submission`
- `apply_patch`

Verified:

- `pd/` was not renamed or reorganized.
- Original PDFs were moved into `references/`.
- Active documentation states the current focus and explicitly excludes Genus, Innovus, PnR, STA, GDSII, and Physical Design.

Remains to do:

- Fill FIPS 203 notes.
- Choose the exact ML-KEM/Kyber-768 KAT baseline.
- Define the first arithmetic RTL unit test and comparison format.

### 2026-07-05 Markdown Orientation

Requested:

- Read `TODO.md` to understand the project.
- Read all Markdown files in the repository.

Files changed:

- Updated `TODO.md` with this handoff entry.

Commands run:

- `ls`
- `sed -n '1,240p' TODO.md`
- `rg --files -g '*.md'`
- `find . -name '*.md' -maxdepth 5 -type f | wc -l`
- `wc -l $(rg --files -g '*.md' | sort)`
- `awk ...` over short Markdown files
- `sed -n '1,260p' Roadmap.md`
- `sed -n '261,560p' Roadmap.md`
- `sed -n '561,860p' Roadmap.md`
- `sed -n '861,1160p' Roadmap.md`
- `sed -n '1161,1500p' Roadmap.md`
- `git status --short`
- `tail -n 80 TODO.md`
- `apply_patch`

Verified:

- Found 43 Markdown files.
- Read the active project documentation, folder README files, archived Markdown scaffolds, `CHANGELOG.md`, `TODO.md`, and the full `Roadmap.md`.
- Confirmed active project status remains `M1: Algorithm and Verification Foundation`.
- Confirmed active docs still exclude Genus, Innovus, PnR, STA, GDSII, and Physical Design from the current phase.

Remains to do:

- Fill `docs/01_standard/fips203_notes.md`.
- Select the exact trusted ML-KEM/Kyber-768 KAT baseline.
- Define the first arithmetic RTL unit test and reference comparison format.

### 2026-07-05 Kyber768 Parameter Header

Requested:

- Create the shared Verilog parameter header for Kyber768.
- Use `kyber768/params.h` and `kyber768/api.h` as references.
- Do not use `kyber768-90s` as the primary source.
- Do not create any arithmetic RTL module.

Files changed:

- Added `rtl/common/kyber_params.vh`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `pwd`
- `sed -n '1,280p' TODO.md`
- `rg --files | rg '(^|/)kyber768/(params|api)\\.h$|(^|/)kyber768-90s/(params|api)\\.h$'`
- `sed -n '1,220p' ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/Reference_Implementation/crypto_kem/kyber768/params.h`
- `sed -n '1,220p' ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/Reference_Implementation/crypto_kem/kyber768/api.h`
- `find rtl -maxdepth 2 -type d | sort`
- `git status --short -- rtl TODO.md`
- `ls -la rtl/common`
- `test -e rtl/common/kyber_params.vh && sed -n '1,220p' rtl/common/kyber_params.vh || true`
- `apply_patch`
- `sed -n '1,220p' rtl/common/kyber_params.vh`
- `git diff -- rtl/common/kyber_params.vh`
- `git status --short -- rtl/common/kyber_params.vh TODO.md`
- `rg -n '^\\s*module\\b|KYBER_PARAMS_VH|KYBER_DU|KYBER_CIPHERTEXTBYTES' rtl/common/kyber_params.vh`

Verified:

- `rtl/common/kyber_params.vh` exists.
- Header uses Verilog include guards.
- Header contains macro-style constants only.
- Header does not declare a Verilog module.
- Primary reference files were the non-90s `kyber768/params.h` and `kyber768/api.h`.

Remains to do:

- Review parameter naming against FIPS 203 terminology if the project switches from Kyber Round 3 names to ML-KEM-only names.
- Use this header from future arithmetic/unit-test RTL only after a concrete module test plan exists.

### 2026-07-05 Modular Addition RTL

Requested:

- Implement the first arithmetic RTL block: modular addition modulo `KYBER_Q = 3329`.
- Create `rtl/arithmetic/mod_add.v`.
- Create `tb/unit/tb_mod_add.v`.
- Create `sim/scripts/run_mod_add.sh`.
- Create `reports/simulation/mod_add_report.md`.
- Do not implement Montgomery reduction, Barrett reduction, modular subtraction, or modular multiplication.

Files changed:

- Added `rtl/arithmetic/mod_add.v`.
- Added `tb/unit/tb_mod_add.v`.
- Added `sim/scripts/run_mod_add.sh`.
- Added `reports/simulation/mod_add_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,360p' TODO.md`
- `sed -n '1,160p' rtl/common/kyber_params.vh`
- `sed -n '1,220p' ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/Reference_Implementation/crypto_kem/kyber768/reduce.c`
- `find rtl/arithmetic tb/unit sim/scripts reports/simulation -maxdepth 2 -type f | sort`
- `sed -n '1,200p' sim/scripts/Makefile`
- `sed -n '1,160p' sim/scripts/rtl.f`
- `sed -n '1,160p' sim/scripts/tb.f`
- `sed -n '1,160p' sim/scripts/compile.f`
- `find tb -maxdepth 3 -type f | sort`
- `command -v iverilog`
- `command -v vvp`
- `git status --short -- rtl/arithmetic tb/unit sim/scripts reports/simulation sim/logs sim/outputs TODO.md`
- `apply_patch`
- `chmod +x sim/scripts/run_mod_add.sh`
- `sed -n '1,220p' rtl/arithmetic/mod_add.v`
- `sed -n '1,260p' tb/unit/tb_mod_add.v`
- `sed -n '1,180p' sim/scripts/run_mod_add.sh`
- `./sim/scripts/run_mod_add.sh`
- `git status --short -- rtl/arithmetic/mod_add.v tb/unit/tb_mod_add.v sim/scripts/run_mod_add.sh reports/simulation/mod_add_report.md TODO.md sim/logs sim/outputs`
- `sed -n '1,220p' reports/simulation/mod_add_report.md`
- `tail -n 80 sim/logs/mod_add.log`

Verified:

- `mod_add` includes `rtl/common/kyber_params.vh` and uses `KYBER_Q`, `KYBER_Q_WIDTH`, and `KYBER_SUM_WIDTH`.
- Internal sum is 13 bits, covering the maximum `3328 + 3328 = 6656`.
- RTL uses one clear conditional subtract of `KYBER_Q`; it does not copy the signed C trick from `csubq`.
- No Montgomery reduction, Barrett reduction, modular subtraction, or modular multiplication RTL was added.
- Self-checking testbench covers directed corner cases plus 1000 random in-range operand pairs.
- `./sim/scripts/run_mod_add.sh` completed with `PASS tb_mod_add`, `pass_count=1009`, and `fail_count=0`.

Remains to do:

- Decide the next arithmetic unit only after writing its unit test plan.
- Consider adding this unit to a broader regression target once more arithmetic blocks exist.

### 2026-07-05 Questa Include Directory Fix

Requested:

- Fix the `make build` failure from `sim/scripts` where Questa could not find `kyber_params.vh`.

Files changed:

- Updated `sim/scripts/compile.f`.
- Updated `reports/simulation/mod_add_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,380p' TODO.md`
- `sed -n '1,160p' sim/scripts/compile.f`
- `sed -n '1,160p' sim/scripts/rtl.f`
- `sed -n '1,160p' sim/scripts/tb.f`
- `sed -n '1,140p' tb/unit/tb_mod_add.v`
- `apply_patch`
- `make build`
- `make run TB_NAME=tb_mod_add TESTNAME=mod_add`
- `vsim -c -l mod_add.log tb_mod_add -do "run -all; quit -f"`
- `tail -n 40 sim/scripts/compile.log`
- `git diff -- sim/scripts/compile.f`
- `git status --short -- sim/scripts/compile.f TODO.md reports/simulation/mod_add_report.md`

Verified:

- `sim/scripts/compile.f` now adds `+incdir+../../rtl/common`.
- `make build` from `sim/scripts` compiles `mod_add` and `tb_mod_add`.
- Questa compile result is `Errors: 0, Warnings: 0`.
- The prior standalone simulation result remains `PASS tb_mod_add`.

Remains to do:

- `make run` still does not execute in this local environment because `vsim` exits at startup with `Error: couldn't open socket: not owner` and `Trouble making server.` This is separate from the fixed include-path compile error.

### 2026-07-05 Questa Make Run Top Fix

Requested:

- Explain and fix why plain `make run` from `sim/scripts` failed with `Could not find work.test_bench`.

Files changed:

- Updated `sim/scripts/Makefile`.
- Updated `reports/simulation/mod_add_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,80p' sim/scripts/Makefile`
- `sed -n '1,420p' TODO.md`
- `tail -n 80 sim/scripts/compile.log`
- `apply_patch`
- `make run`

Verified:

- Root cause was the Makefile default `TB_NAME ?= test_bench` while `make build` compiled top module `tb_mod_add`.
- Makefile default now uses `TESTNAME ?= mod_add` and `TB_NAME ?= tb_mod_add`.
- The generated `make run` command now targets `tb_mod_add`: `vsim ... -c tb_mod_add ...`.

Remains to do:

- In this local shell, `vsim` still exits before simulation startup with `Error: couldn't open socket: not owner` and `Trouble making server.` The user's transcript shows their `vsim` starts and reaches design optimization, so the Makefile top-name fix should address the reported `work.test_bench` error in that environment.

### 2026-07-05 Modular Subtraction Testbench

Requested:

- User wrote `rtl/arithmetic/mod_sub.v`.
- Add a testbench and test it.
- Do not edit `mod_sub.v`; report any RTL errors for the user to fix.

Files changed:

- Added `tb/unit/tb_mod_sub.v`.
- Added `sim/scripts/run_mod_sub.sh`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,460p' TODO.md`
- `sed -n '1,220p' rtl/arithmetic/mod_sub.v`
- `sed -n '1,220p' tb/unit/tb_mod_add.v`
- `sed -n '1,80p' sim/scripts/Makefile`
- `sed -n '1,80p' sim/scripts/rtl.f`
- `sed -n '1,80p' sim/scripts/tb.f`
- `sed -n '1,80p' sim/scripts/compile.f`
- `apply_patch`
- `chmod +x sim/scripts/run_mod_sub.sh`
- `sed -n '1,180p' tb/unit/tb_mod_sub.v`
- `sed -n '1,120p' sim/scripts/run_mod_sub.sh`
- `./sim/scripts/run_mod_sub.sh`
- `nl -ba rtl/arithmetic/mod_sub.v`
- `tail -n 80 sim/logs/mod_sub.log`
- `git status --short -- rtl/arithmetic/mod_sub.v tb/unit/tb_mod_sub.v sim/scripts/run_mod_sub.sh TODO.md`

Verified:

- The new `tb_mod_sub` is self-checking.
- It covers directed no-wrap and wraparound subtraction cases plus 1000 random in-range operand pairs.
- Simulation could not run because `mod_sub.v` did not compile.
- `mod_sub.v` was not edited.

Remains to do:

- User should fix `mod_sub.v` line 10 and line 11 by terminating the wire declarations.
- User should review line 7 because `c` is declared as an input while line 16 assigns to `c`.
- After those RTL fixes, rerun `./sim/scripts/run_mod_sub.sh`.

### 2026-07-05 Reduction And Modular Multiplication Tests

Requested:

- User wrote `rtl/arithmetic/reduction.v` and `rtl/arithmetic/mod_mul.v`.
- Add tests and run them.
- Report errors; do not edit the user's RTL.

Files changed:

- Added `tb/unit/tb_reduction.v`.
- Added `tb/unit/tb_mod_mul.v`.
- Added `sim/scripts/run_reduction.sh`.
- Added `sim/scripts/run_mod_mul.sh`.
- Added `reports/simulation/reduction_mod_mul_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,560p' TODO.md`
- `sed -n '1,240p' rtl/arithmetic/reduction.v`
- `sed -n '1,240p' rtl/arithmetic/mod_mul.v`
- `find rtl/arithmetic tb/unit sim/scripts reports/simulation -maxdepth 2 -type f | sort`
- `apply_patch`
- `chmod +x sim/scripts/run_reduction.sh sim/scripts/run_mod_mul.sh`
- `sed -n '1,220p' tb/unit/tb_reduction.v`
- `sed -n '1,220p' tb/unit/tb_mod_mul.v`
- `./sim/scripts/run_reduction.sh`
- `./sim/scripts/run_mod_mul.sh`
- `nl -ba rtl/arithmetic/mod_mul.v`
- `nl -ba rtl/arithmetic/reduction.v`
- `tail -n 80 sim/logs/reduction.log`
- `tail -n 80 sim/logs/mod_mul.log`

Verified:

- `tb_reduction` is self-checking and tests `montgomery_reduce`, `barrett_reduce`, and `conditional_sub_q`.
- `./sim/scripts/run_reduction.sh` completed with `PASS tb_reduction`, `pass_count=620`, and `fail_count=0`.
- `tb_mod_mul` is self-checking and compares `mod_mul` against a Montgomery-reduction reference model.
- `./sim/scripts/run_mod_mul.sh` could not simulate because `mod_mul.v` did not compile.
- `reduction.v` and `mod_mul.v` were not edited.

Remains to do:

- User should fix `rtl/arithmetic/mod_mul.v` line 9 by removing the trailing comma after output port `c`.
- After that fix, rerun `./sim/scripts/run_mod_mul.sh`.

### 2026-07-05 Arithmetic And NTT Smoke Tests

Requested:

- User modified `mod_sub.v`, `mod_mul.v`, and added code to `zetas_rom.v` and `butterfly_unit.v`.
- Test everything and report errors.

Files changed:

- Updated `tb/unit/tb_mod_mul.v` to match the current canonical unsigned `mod_mul` interface.
- Added `tb/unit/tb_zetas_rom.v`.
- Added `tb/unit/tb_butterfly_unit.v`.
- Added `sim/scripts/run_zetas_rom.sh`.
- Added `sim/scripts/run_butterfly_unit.sh`.
- Added `reports/simulation/arithmetic_ntt_smoke_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,680p' TODO.md`
- `sed -n '1,220p' rtl/arithmetic/mod_sub.v`
- `sed -n '1,220p' rtl/arithmetic/mod_mul.v`
- `sed -n '1,260p' rtl/arithmetic/reduction.v`
- `sed -n '1,260p' rtl/ntt/zetas_rom.v`
- `sed -n '261,560p' rtl/ntt/zetas_rom.v`
- `sed -n '1,280p' rtl/ntt/butterfly_unit.v`
- `sed -n '42,70p' ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/Reference_Implementation/crypto_kem/kyber768/ntt.c`
- `sed -n '90,115p' ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/Reference_Implementation/crypto_kem/kyber768/ntt.c`
- `rg -n "module zetas|module butterfly|zetas_rom|butterfly_unit" -S .`
- `rg -n "zetas|KYBER_ROOT|17|2285|2571|2970" ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/Reference_Implementation/crypto_kem/kyber768 -S`
- `apply_patch`
- `./sim/scripts/run_mod_add.sh`
- `./sim/scripts/run_mod_sub.sh`
- `./sim/scripts/run_reduction.sh`
- `./sim/scripts/run_mod_mul.sh`
- `chmod +x sim/scripts/run_zetas_rom.sh sim/scripts/run_butterfly_unit.sh`
- `./sim/scripts/run_zetas_rom.sh`
- `./sim/scripts/run_butterfly_unit.sh`
- `nl -ba rtl/ntt/butterfly_unit.v`
- `tail -n 40 sim/logs/mod_add.log`
- `tail -n 40 sim/logs/mod_sub.log`
- `tail -n 40 sim/logs/reduction.log`
- `tail -n 40 sim/logs/mod_mul.log`
- `tail -n 40 sim/logs/zetas_rom.log`
- `tail -n 80 sim/logs/butterfly_unit.log`
- `git status --short -- rtl/arithmetic/mod_sub.v rtl/arithmetic/mod_mul.v rtl/ntt/zetas_rom.v rtl/ntt/butterfly_unit.v tb/unit sim/scripts reports/simulation TODO.md`

Verified:

- `./sim/scripts/run_mod_add.sh`: `PASS tb_mod_add`, `pass_count=1009`, `fail_count=0`.
- `./sim/scripts/run_mod_sub.sh`: `PASS tb_mod_sub`, `pass_count=1012`, `fail_count=0`.
- `./sim/scripts/run_reduction.sh`: `PASS tb_reduction`, `pass_count=620`, `fail_count=0`.
- `./sim/scripts/run_mod_mul.sh`: `PASS tb_mod_mul`, `pass_count=1010`, `fail_count=0`.
- `./sim/scripts/run_zetas_rom.sh`: `PASS tb_zetas_rom`, `pass_count=16`, `fail_count=0`.
- `./sim/scripts/run_butterfly_unit.sh` could not elaborate `butterfly_unit.v`.

Remains to do:

- User should fix `rtl/ntt/butterfly_unit.v` line 40: `wire [KYBER_Q_WIDTH:0] t;` is missing the macro backtick before `KYBER_Q_WIDTH`.
- After that fix, rerun `./sim/scripts/run_butterfly_unit.sh`.
- Review width consistency after elaboration: `butterfly_unit` uses `[`KYBER_Q_WIDTH:0]`, while `mod_add` and `mod_sub` use `[`KYBER_Q_WIDTH-1:0]`; current tool warnings show pruning/padding at those ports.

### 2026-07-06 NTT Address Generator Testbench

Requested:

- Create a self-checking Verilog testbench for `rtl/ntt/ntt_addr_gen.v`.
- Create `tb/unit/tb_ntt_addr_gen.v`.
- Create `sim/scripts/run_ntt_addr_gen.sh`.
- Create `reports/simulation/ntt_addr_gen_report.md`.
- Do not modify `rtl/ntt/ntt_addr_gen.v`, any RTL source file, `kyber_params.vh`, or arithmetic modules.

Files changed:

- Added `tb/unit/tb_ntt_addr_gen.v`.
- Added `sim/scripts/run_ntt_addr_gen.sh`.
- Added `reports/simulation/ntt_addr_gen_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,760p' TODO.md`
- `sed -n '1,260p' rtl/ntt/ntt_addr_gen.v`
- `find tb/unit sim/scripts reports/simulation -maxdepth 1 -type f | sort`
- `git status --short -- rtl/ntt/ntt_addr_gen.v tb/unit/tb_ntt_addr_gen.v sim/scripts/run_ntt_addr_gen.sh reports/simulation/ntt_addr_gen_report.md TODO.md`
- `apply_patch`
- `chmod +x sim/scripts/run_ntt_addr_gen.sh`
- `sed -n '1,320p' tb/unit/tb_ntt_addr_gen.v`
- `sed -n '1,120p' sim/scripts/run_ntt_addr_gen.sh`
- `./sim/scripts/run_ntt_addr_gen.sh`
- `nl -ba rtl/ntt/ntt_addr_gen.v | sed -n '34,120p'`
- `nl -ba rtl/ntt/ntt_addr_gen.v | sed -n '120,190p'`
- `sed -n '1,120p' sim/logs/ntt_addr_gen_sim.log`
- `git status --short -- rtl/ntt/ntt_addr_gen.v tb/unit/tb_ntt_addr_gen.v sim/scripts/run_ntt_addr_gen.sh reports/simulation/ntt_addr_gen_report.md TODO.md sim/logs/ntt_addr_gen_sim.log sim/outputs/tb_ntt_addr_gen.out sim/waves/ntt_addr_gen.vcd`

Verified:

- The new testbench builds a behavioral reference model of the forward and inverse nested loops from `kyber768/ntt.c`.
- The testbench checks every valid cycle for `len_out`, `addr_a`, `addr_b`, and `zeta_addr`.
- The testbench checks total valid cycles, one-cycle `done`, `valid` low after done, and `busy` low after done.
- The run script creates `sim/outputs`, `sim/logs`, and `sim/waves`, compiles with `iverilog -g2012`, uses include path `rtl/common`, and writes logs/waves to the requested paths.
- RTL simulation could not run because `rtl/ntt/ntt_addr_gen.v` failed to compile at line 42.
- No RTL source file, `kyber_params.vh`, or arithmetic module was modified.

Remains to do:

- User should fix `rtl/ntt/ntt_addr_gen.v` line 42: `paremeter ZETA_WIDTH = 7`.
- After that, review visible RTL issues at line 73 (`next-start` vs `next_start`), line 92 (`alway`), and lines 130-131 (`start_stage`/`j_stage` vs declared `start_reg`/`j_reg`).
- Rerun `./sim/scripts/run_ntt_addr_gen.sh` after RTL fixes.

### 2026-07-06 NTT Address Generator Rerun

Requested:

- Rerun the `ntt_addr_gen` test.

Files changed:

- Updated `reports/simulation/ntt_addr_gen_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `tail -n 140 TODO.md`
- `sed -n '1,220p' rtl/ntt/ntt_addr_gen.v`
- `sed -n '1,80p' sim/scripts/run_ntt_addr_gen.sh`
- `./sim/scripts/run_ntt_addr_gen.sh`

Verified:

- Test remains blocked at RTL compile.
- Current first compiler error is still `rtl/ntt/ntt_addr_gen.v:42: syntax error`.
- `rtl/ntt/ntt_addr_gen.v` was not modified.

Remains to do:

- User should fix `rtl/ntt/ntt_addr_gen.v` line 42: `paremeter ZETA_WIDTH = 7`.
- After that, review lines 130-131 because `start_stage` and `j_stage` are assigned but the declared registers are `start_reg` and `j_reg`.
- Rerun `./sim/scripts/run_ntt_addr_gen.sh`.

### 2026-07-06 NTT Address Generator Rerun 2

Requested:

- Rerun the `ntt_addr_gen` test again.

Files changed:

- Updated `reports/simulation/ntt_addr_gen_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '34,150p' rtl/ntt/ntt_addr_gen.v`
- `./sim/scripts/run_ntt_addr_gen.sh`

Verified:

- Test remains blocked at RTL compile.
- Current first compiler error is still `rtl/ntt/ntt_addr_gen.v:42: syntax error`.
- `rtl/ntt/ntt_addr_gen.v` was not modified.

Remains to do:

- User should fix `rtl/ntt/ntt_addr_gen.v` line 42: `paremeter ZETA_WIDTH = 7`.
- Rerun `./sim/scripts/run_ntt_addr_gen.sh`.

### 2026-07-06 NTT Address Generator Failure Diagnosis

Requested:

- Inspect why the user's `ntt_addr_gen` test fails after RTL syntax fixes.

Files changed:

- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,220p' TODO.md`
- `nl -ba rtl/ntt/ntt_addr_gen.v | sed -n '1,220p'`
- `sed -n '1,220p' sim/logs/ntt_addr_gen_sim.log`
- `sed -n '1,260p' tb/unit/tb_ntt_addr_gen.v`
- `tail -n 80 sim/logs/ntt_addr_gen_sim.log`
- `grep -n "PASS\\|FAIL\\|INFO tb_ntt_addr_gen: pass_count" sim/logs/ntt_addr_gen_sim.log | tail -n 20`
- `grep -n "mode=1 cycle=0\\|mode=0 cycle=0\\|expected done" sim/logs/ntt_addr_gen_sim.log | head -n 20`

Verified:

- `ntt_addr_gen.v` now compiles far enough for the testbench to run.
- The failure pattern is a one-cycle sampling shift: testbench cycle 0 expects `addr_a=0`, but actual output is already `addr_a=1`.
- The final schedule is similarly shifted: the testbench expects the last valid entry while the DUT is already at `done`.
- Likely root cause is the testbench checking at the first posedge after `pulse_start` returns, which misses the first valid schedule produced immediately after the start-capturing posedge.

Remains to do:

- Adjust `tb/unit/tb_ntt_addr_gen.v` sampling phase, for example sample the first valid output immediately after the start-capturing posedge or sample stable outputs on the following negedge instead of waiting one extra posedge.
- Rerun `./sim/scripts/run_ntt_addr_gen.sh` after testbench timing is corrected.

### 2026-07-06 NTT Address Generator Testbench Timing Fix

Requested:

- Fix only the testbench timing alignment for `ntt_addr_gen`.
- Do not modify RTL, `kyber_params.vh`, or arithmetic modules.

Files changed:

- Updated `tb/unit/tb_ntt_addr_gen.v`.
- Updated `reports/simulation/ntt_addr_gen_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `tail -n 120 TODO.md`
- `sed -n '1,300p' tb/unit/tb_ntt_addr_gen.v`
- `sed -n '1,180p' reports/simulation/ntt_addr_gen_report.md`
- `apply_patch`
- `./sim/scripts/run_ntt_addr_gen.sh`

Verified:

- Testbench now drives `start` and `mode` on a negedge.
- DUT captures `start` on the next posedge.
- Testbench samples cycle 0 on the following negedge without waiting an extra posedge.
- Remaining valid cycles are sampled once per negedge.
- `./sim/scripts/run_ntt_addr_gen.sh` completed with `PASS tb_ntt_addr_gen`.
- Forward mode valid cycles: 896.
- Inverse mode valid cycles: 896.
- Total checked valid cycles: 1792.
- `fail_count=0`.
- No RTL source file, `kyber_params.vh`, or arithmetic module was modified.

Remains to do:

- Use `./sim/scripts/run_ntt_addr_gen.sh` as the current unit regression for `ntt_addr_gen`.

### 2026-07-06 GitHub Checkpoint Push

Requested:

- Push the current checkpoint to GitHub.

Files changed:

- Updated `.gitignore` to ignore file-form `vsim.dbg` simulator artifacts.
- Updated `TODO.md` with this handoff entry.
- Checkpoint includes current documentation cleanup, reference collateral moves, arithmetic/NTT RTL, unit testbenches, simulation scripts, and curated simulation reports.

Commands run:

- `sed -n '1,120p' TODO.md`
- `git status --short`
- `git branch --show-current`
- `git remote -v`
- `sed -n '1,260p' .gitignore`
- `git diff --stat`
- `git diff --name-status`
- `file sim/scripts/vsim.dbg || true`
- `ls -la sim/scripts/vsim.dbg 2>/dev/null || true`
- `git check-ignore -v sim/scripts/vsim.dbg sim/scripts/transcript sim/logs/ntt_addr_gen_sim.log sim/waves/ntt_addr_gen.vcd sim/outputs/tb_ntt_addr_gen.out || true`
- `apply_patch`
- `./sim/scripts/run_mod_add.sh`
- `./sim/scripts/run_mod_sub.sh`
- `./sim/scripts/run_reduction.sh`
- `./sim/scripts/run_mod_mul.sh`
- `./sim/scripts/run_zetas_rom.sh`
- `./sim/scripts/run_ntt_addr_gen.sh`
- `git check-ignore -v sim/scripts/vsim.dbg sim/logs/ntt_addr_gen_sim.log sim/waves/ntt_addr_gen.vcd sim/outputs/tb_ntt_addr_gen.out`

Verified:

- `sim/scripts/vsim.dbg`, generated logs, generated waves, and generated simulation outputs are ignored.
- `run_mod_add.sh`: PASS.
- `run_mod_sub.sh`: PASS.
- `run_reduction.sh`: PASS.
- `run_mod_mul.sh`: PASS.
- `run_zetas_rom.sh`: PASS.
- `run_ntt_addr_gen.sh`: PASS.

Remains to do:

- Stage, commit, and push this checkpoint.

### 2026-07-06 NTT Core Testbench Bring-up

Requested:

- Test `rtl/ntt/ntt_core.v` and write a careful self-checking testbench.

Files changed:

- Added `tb/unit/tb_ntt_core.v`.
- Added `sim/scripts/run_ntt_core.sh`.
- Added `reports/simulation/ntt_core_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `pwd`
- `sed -n '1,220p' TODO.md`
- `rg --files`
- `sed -n '1,260p' rtl/ntt/ntt_core.v`
- `sed -n '1,220p' rtl/ntt/butterfly_unit.v`
- `sed -n '1,220p' rtl/ntt/intt_butterfly_unit.v`
- `sed -n '1,240p' rtl/ntt/ntt_addr_gen.v`
- `sed -n '1,260p' rtl/memory/poly_buffer.v`
- `sed -n '1,220p' rtl/arithmetic/mod_mul.v`
- `sed -n '1,220p' rtl/arithmetic/reduction.v`
- `sed -n '1,180p' rtl/common/kyber_params.vh`
- `sed -n '1,220p' sim/scripts/run_ntt_addr_gen.sh`
- `sed -n '1,360p' rtl/ntt/zetas_rom.v`
- `apply_patch`
- `chmod +x sim/scripts/run_ntt_core.sh`
- `git status --short`
- `./sim/scripts/run_ntt_core.sh`
- `nl -ba rtl/ntt/ntt_core.v | sed -n '60,150p'`
- `sed -n '1,160p' sim/logs/ntt_core_sim.log`

Verified:

- The new testbench is designed to load two full 256-coefficient input patterns,
  run the forward NTT core, wait for `done`, read back all coefficients, and
  compare every output against a behavioral Kyber forward NTT model.
- The run script creates `sim/outputs`, `sim/logs`, and `sim/waves`, compiles
  all required DUT dependencies with `iverilog -g2012`, runs `vvp`, tees the log,
  and returns nonzero unless `PASS tb_ntt_core` is printed.
- Current `ntt_core.v` does not compile, so polynomial-level simulation did not
  run.
- First blocking compile error: `rtl/ntt/ntt_core.v:82` uses `.addr-b`, which is
  not a legal named port connection.
- Additional DUT issues reported by the compiler include `doen`,
  `buf_wr_data-a`, and `buf_wr_data-b`.
- No RTL file was modified during this testbench bring-up.

Remains to do:

- Fix `rtl/ntt/ntt_core.v` compile errors, then rerun
  `./sim/scripts/run_ntt_core.sh`.
- After compilation succeeds, review any polynomial mismatches from
  `tb_ntt_core` as either DUT scheduling/readback issues or reference-model
  issues.

### 2026-07-06 NTT Core Retest

Requested:

- Retest `rtl/ntt/ntt_core.v` after user-side DUT fixes.

Files changed:

- Updated `reports/simulation/ntt_core_report.md`.
- Updated `TODO.md` with this retest entry.

Commands run:

- `sed -n '1,220p' TODO.md`
- `git status --short`
- `nl -ba rtl/ntt/ntt_core.v | sed -n '70,150p'`
- `./sim/scripts/run_ntt_core.sh`
- `nl -ba rtl/ntt/ntt_core.v | sed -n '90,104p'`
- `rg -n "module zeta|module zetas|zeta_rom|zetas_rom" rtl/ntt tb/unit sim/scripts`
- `sed -n '1,120p' sim/logs/ntt_core_sim.log`
- `apply_patch`

Verified:

- The earlier syntax errors around `.addr_b`, `done`, `buf_wr_data_a`, and
  `buf_wr_data_b` are no longer the first blockers in the inspected DUT.
- `./sim/scripts/run_ntt_core.sh` still fails before simulation.
- Current first blocker is elaboration: `rtl/ntt/ntt_core.v:96` instantiates
  `zeta_rom`, but the available module is `zetas_rom` in
  `rtl/ntt/zetas_rom.v`.
- No RTL file was modified during this retest.

Remains to do:

- Fix the `ntt_core.v` ROM instance module name mismatch, then rerun
  `./sim/scripts/run_ntt_core.sh`.
- After elaboration succeeds, use `tb_ntt_core` to check the full polynomial
  output comparison.

### 2026-07-06 NTT Core Polynomial Retest

Requested:

- Retest `rtl/ntt/ntt_core.v` again after user-side ROM instance fix.

Files changed:

- Updated `reports/simulation/ntt_core_report.md`.
- Updated `TODO.md` with this retest entry.

Commands run:

- `sed -n '1,120p' TODO.md`
- `git status --short`
- `nl -ba rtl/ntt/ntt_core.v | sed -n '90,104p'`
- `./sim/scripts/run_ntt_core.sh`
- `apply_patch`

Verified:

- `ntt_core` now compiles, elaborates, and runs simulation.
- `tb_ntt_core` completed both deterministic 256-coefficient polynomial
  patterns.
- Result was `FAIL tb_ntt_core`.
- Final counts: `pass_count=0 fail_count=512`.
- First mismatch: pattern 0, index 0, expected 2429, actual 745.
- Compile warnings show likely DUT width issue: `ntt_core.v` passes an 8-bit
  `zeta` into `butterfly_unit`, while zeta/twiddle data should be coefficient
  width.
- No RTL file was modified during this retest.

Remains to do:

- Inspect and fix the `zeta` signal width in `rtl/ntt/ntt_core.v`; it is
  currently declared with `ADDR_WIDTH` instead of coefficient data width.
- After that, rerun `./sim/scripts/run_ntt_core.sh` and inspect any remaining
  mismatches.

### 2026-07-06 RTL Review And Documentation Notes

Requested:

- Carefully review the current Verilog files, point out potential errors and
  improvements, and add explanatory notes where the code is sound.

Files changed:

- Added explanatory algorithm/source notes to:
  - `rtl/arithmetic/mod_add.v`
  - `rtl/arithmetic/mod_sub.v`
  - `rtl/arithmetic/mod_mul.v`
  - `rtl/arithmetic/reduction.v`
  - `rtl/ntt/butterfly_unit.v`
  - `rtl/ntt/intt_butterfly_unit.v`
  - `rtl/ntt/ntt_addr_gen.v`
  - `rtl/ntt/ntt_core.v`
  - `rtl/ntt/zetas_rom.v`
  - `rtl/memory/poly_buffer.v`
- Cleaned testbench port-width declarations in:
  - `tb/unit/tb_mod_mul.v`
  - `tb/unit/tb_butterfly_unit.v`
  - `tb/unit/tb_zetas_rom.v`
- Updated `reports/simulation/ntt_core_report.md` to the current PASS result.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `pwd`
- `sed -n '1,220p' TODO.md`
- `rg --files -g '*.v' rtl tb`
- `rg -n "Post_Quantum_Cryptography|ML-KEM|Kyber|ntt_core|ntt_addr_gen|arithmetic RTL" /home/hien/.codex/memories/MEMORY.md`
- `git status --short`
- `nl -ba /home/hien/.codex/memories/MEMORY.md | sed -n '1,42p'`
- `sed -n ...` on RTL arithmetic, NTT, memory, testbench, and reference C files
- `./sim/scripts/run_mod_add.sh`
- `./sim/scripts/run_mod_sub.sh`
- `./sim/scripts/run_reduction.sh`
- `./sim/scripts/run_mod_mul.sh`
- `./sim/scripts/run_zetas_rom.sh`
- `./sim/scripts/run_butterfly_unit.sh`
- `./sim/scripts/run_ntt_addr_gen.sh`
- `./sim/scripts/run_ntt_core.sh`
- `iverilog -g2012 -Wall -I rtl/common -o /tmp/intt_butterfly_unit_check.out rtl/arithmetic/mod_add.v rtl/arithmetic/mod_sub.v rtl/arithmetic/reduction.v rtl/arithmetic/mod_mul.v rtl/ntt/intt_butterfly_unit.v`
- `rg -n "KYBER_Q_WIDTH:0|canoninal|Rederence|caculations" rtl tb`
- `git diff --check`
- `git diff --stat`
- `apply_patch`

Verified:

- `run_mod_add.sh`: PASS, `pass_count=1009 fail_count=0`.
- `run_mod_sub.sh`: PASS, `pass_count=1012 fail_count=0`.
- `run_reduction.sh`: PASS, `pass_count=620 fail_count=0`.
- `run_mod_mul.sh`: PASS, `pass_count=1010 fail_count=0`.
- `run_zetas_rom.sh`: PASS, `pass_count=16 fail_count=0`.
- `run_butterfly_unit.sh`: PASS, `pass_count=206 fail_count=0`.
- `run_ntt_addr_gen.sh`: PASS, `pass_count=1792 fail_count=0`.
- `run_ntt_core.sh`: PASS, `pass_count=512 fail_count=0`.
- `intt_butterfly_unit.v` compiles cleanly with its arithmetic dependencies.
- The old testbench width warnings for `mod_mul`, `butterfly_unit`, and
  `zetas_rom` were removed.
- Review notes added to the RTL explain the reference C source, datapath range,
  address schedule, memory timing, and current verification assumptions.

Review findings and improvement notes:

- `barrett_reduce` previously had a misleading 48-bit concatenate assigned into
  a 32-bit wire. It was behavior-equivalent for current callers but fragile, so
  it was replaced with a direct signed assignment and documented.
- `mod_sub` is functionally correct in the current tests, but it relies on
  fixed-width wraparound on underflow. The added comment explains that behavior;
  a future style cleanup could rewrite it with an explicit wider add/sub path.
- `ntt_core` still depends on the caller obeying the interface rule not to
  assert `load_en` in the same cycle as `start`. A future hardening change could
  gate `load_allowed` with `!start` as well.
- `intt_butterfly_unit.v` has no dedicated self-checking unit test yet. It
  compiles cleanly, but should not be treated as fully verified until a testbench
  is added.

Remains to do:

- Add a self-checking testbench and run script for `intt_butterfly_unit.v`.
- Consider converting `zetas_rom` constants from `16'sd...` literals to
  coefficient-width unsigned literals for stricter lint cleanliness.
- Consider hardening the `ntt_core` load/start interface.

### 2026-07-06 GitHub Push After RTL Review

Requested:

- Push the current RTL review/documentation checkpoint to GitHub.

Files changed:

- Updated `TODO.md` with this checkpoint entry.
- Checkpoint includes the reviewed RTL documentation notes, testbench width
  cleanup, `ntt_core` verification files, and the current `ntt_core` simulation
  report.

Commands run:

- `pwd`
- `sed -n '1,120p' TODO.md`
- `rg -n "Post_Quantum_Cryptography|M1: Algorithm|reports/simulation|pd/" /home/hien/.codex/memories/MEMORY.md`
- `git status --short`
- `./sim/scripts/run_mod_add.sh`
- `./sim/scripts/run_mod_sub.sh`
- `./sim/scripts/run_reduction.sh`
- `./sim/scripts/run_mod_mul.sh`
- `./sim/scripts/run_zetas_rom.sh`
- `./sim/scripts/run_butterfly_unit.sh`
- `./sim/scripts/run_ntt_addr_gen.sh`
- `./sim/scripts/run_ntt_core.sh`
- `git diff --check`
- `iverilog -g2012 -Wall -I rtl/common -o /tmp/intt_butterfly_unit_check.out rtl/arithmetic/mod_add.v rtl/arithmetic/mod_sub.v rtl/arithmetic/reduction.v rtl/arithmetic/mod_mul.v rtl/ntt/intt_butterfly_unit.v`
- `git remote -v`
- `apply_patch`

Verified:

- `run_mod_add.sh`: PASS, `pass_count=1009 fail_count=0`.
- `run_mod_sub.sh`: PASS, `pass_count=1012 fail_count=0`.
- `run_reduction.sh`: PASS, `pass_count=620 fail_count=0`.
- `run_mod_mul.sh`: PASS, `pass_count=1010 fail_count=0`.
- `run_zetas_rom.sh`: PASS, `pass_count=16 fail_count=0`.
- `run_butterfly_unit.sh`: PASS, `pass_count=206 fail_count=0`.
- `run_ntt_addr_gen.sh`: PASS, `pass_count=1792 fail_count=0`.
- `run_ntt_core.sh`: PASS, `pass_count=512 fail_count=0`.
- `git diff --check`: clean.
- `intt_butterfly_unit.v` compiles cleanly with its arithmetic dependencies.

Remains to do:

- Confirm the pushed commit hash and clean working tree in the final response.

### 2026-07-06 Post-Push RTL Cleanup Checkpoint

Requested:

- Save all remaining local progress to GitHub after the first checkpoint push.

Files changed:

- Updated `rtl/ntt/ntt_core.v` to block external load writes during the same
  cycle as `start`.
- Updated `rtl/ntt/zetas_rom.v` constants from 16-bit signed literals to
  12-bit unsigned coefficient-width literals.
- Updated `TODO.md` with this checkpoint entry.

Commands run:

- `git status --short`
- `git log -1 --oneline`
- `git rev-parse --short HEAD`
- `git diff -- rtl/ntt/ntt_core.v`
- `git diff -- rtl/ntt/zetas_rom.v`
- `git diff --stat`
- `git diff --check`
- `./sim/scripts/run_zetas_rom.sh`
- `./sim/scripts/run_ntt_core.sh`
- `./sim/scripts/run_butterfly_unit.sh`
- `apply_patch`

Verified:

- `git diff --check`: clean.
- `run_zetas_rom.sh`: PASS, `pass_count=16 fail_count=0`.
- `run_ntt_core.sh`: PASS, `pass_count=512 fail_count=0`.
- `run_butterfly_unit.sh`: PASS, `pass_count=206 fail_count=0`.

Remains to do:

- Confirm the final pushed commit hash and clean working tree in the final
  response.

## Next Session Start Here

1. Read `TODO.md`.
2. Read `docs/00_project_spec/milestone_status.md`.
3. Read `README.md`.
4. Read `docs/04_verification/verification_plan.md`.
5. Start by adding self-checking verification for `intt_butterfly_unit.v`, then
   decide whether to harden `ntt_core` load/start gating.

### 2026-07-06 Repository Orientation For Project Understanding

Requested:

- Understand the current repository and explain the project status.

Files changed:

- Updated `reports/simulation/arithmetic_ntt_smoke_report.md` to match the
  current passing arithmetic and NTT simulation results.
- Updated `reports/simulation/reduction_mod_mul_report.md` to remove stale
  blocked status for `mod_mul.v`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `pwd`
- `rg -n "Post_Quantum_Cryptography|ML-KEM|Kyber|TODO|M1|simulation|pd" /home/hien/.codex/memories/MEMORY.md`
- `ls`
- `sed -n ... TODO.md`
- `find . -maxdepth 3 -type f | sort`
- `find . -maxdepth 3 -type d | sort`
- `git status --short`
- `sed -n ... README.md docs/00_project_spec/project_spec.md docs/00_project_spec/milestone_status.md docs/README.md rtl/README.md sim/README.md`
- `sed -n ... docs/04_verification/verification_plan.md docs/04_verification/test_vector_plan.md docs/02_math/modular_arithmetic_notes.md docs/03_architecture/ntt_architecture.md`
- `sed -n ... reports/simulation/mod_add_report.md reports/simulation/ntt_core_report.md`
- `sed -n ... rtl/common/kyber_params.vh rtl/arithmetic/mod_add.v rtl/arithmetic/mod_sub.v rtl/arithmetic/mod_mul.v rtl/ntt/ntt_core.v`
- `rg -n '^module ' ...` over RTL and unit testbench files
- `./sim/scripts/run_mod_add.sh`
- `./sim/scripts/run_mod_sub.sh`
- `./sim/scripts/run_reduction.sh`
- `./sim/scripts/run_mod_mul.sh`
- `./sim/scripts/run_zetas_rom.sh`
- `./sim/scripts/run_butterfly_unit.sh`
- `./sim/scripts/run_ntt_addr_gen.sh`
- `./sim/scripts/run_ntt_core.sh`
- `sed -n ... Roadmap.md ref_model/README.md sim/scripts/rtl.f sim/scripts/tb.f sim/scripts/Makefile`
- `git diff --stat`
- `git diff -- rtl/ntt/ntt_core.v`
- `git diff -- .agents/workflows/startpqc.md`
- `apply_patch`

Verified:

- Current milestone is still `M1: Algorithm and Verification Foundation`.
- Active repo scope is standards/reference model/KAT/RTL/testbench/simulation/
  architecture/verification; physical design remains out of current scope.
- Existing arithmetic and NTT simulation scripts pass:
  `mod_add`, `mod_sub`, `reduction`, `mod_mul`, `zetas_rom`,
  `butterfly_unit`, `ntt_addr_gen`, and `ntt_core`.
- `sim/scripts/Makefile`, `rtl.f`, and `tb.f` still default to the original
  `mod_add` flow; broader checks are run through individual scripts.
- Pre-existing local modifications were observed in `.agents/workflows/startpqc.md`
  and `rtl/ntt/ntt_core.v`.

Remains to do:

- Add self-checking verification for `intt_butterfly_unit.v`.
- Decide whether to create a single top-level regression script for all current
  unit simulations.
- Fill FIPS 203 notes and connect future RTL checks to a trusted KAT/golden
  reference flow.

## Next Session Start Here

1. Read `TODO.md`.
2. Read `README.md` and `docs/00_project_spec/milestone_status.md`.
3. Run the current unit checks with the individual scripts under `sim/scripts/`.
4. Start the next technical task with `intt_butterfly_unit.v` verification or a
   unified regression script.

### 2026-07-06 intt_core Verification

Requested:

- Verify and test the newly written inverse NTT core, `rtl/ntt/intt_core.v`.

Files changed:

- Fixed compile/connectivity issues in `rtl/ntt/intt_core.v` while preserving
  the intended inverse NTT architecture.
- Added `tb/unit/tb_intt_core.v`.
- Added `sim/scripts/run_intt_core.sh`.
- Added `reports/simulation/intt_core_report.md`.
- Updated `reports/simulation/arithmetic_ntt_smoke_report.md` to include
  `intt_core`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,180p' TODO.md`
- `rg -n "intt|innt|ntt_core|butterfly" /home/hien/.codex/memories/MEMORY.md`
- `find rtl tb sim/scripts reports/simulation -maxdepth 3 -type f | sort | rg 'intt|innt|ntt_core|butterfly|ntt_addr'`
- `git status --short`
- `sed -n ... rtl/ntt/intt_core.v`
- `sed -n ... tb/unit/tb_ntt_core.v`
- `sed -n ... rtl/ntt/ntt_addr_gen.v`
- `sed -n ... rtl/ntt/intt_butterfly_unit.v`
- `sed -n ... sim/scripts/run_ntt_core.sh`
- `sed -n ... rtl/ntt/zetas_rom.v rtl/memory/poly_buffer.v tb/unit/tb_butterfly_unit.v`
- `sed -n ... ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/Reference_Implementation/crypto_kem/kyber768/ntt.c`
- `iverilog -g2012 -Wall -I rtl/common -o /tmp/intt_core_check.out ... rtl/ntt/intt_core.v`
- `chmod +x sim/scripts/run_intt_core.sh`
- `./sim/scripts/run_intt_core.sh`
- `./sim/scripts/run_zetas_rom.sh`
- `./sim/scripts/run_butterfly_unit.sh`
- `./sim/scripts/run_ntt_addr_gen.sh`
- `./sim/scripts/run_ntt_core.sh`
- `./sim/scripts/run_mod_add.sh`
- `./sim/scripts/run_mod_sub.sh`
- `./sim/scripts/run_reduction.sh`
- `./sim/scripts/run_mod_mul.sh`
- `apply_patch`

Verified:

- `intt_core.v` elaborates with Icarus Verilog after fixes.
- `run_intt_core.sh`: PASS, `pass_count=768 fail_count=0`.
- `run_zetas_rom.sh`: PASS, `pass_count=16 fail_count=0`.
- `run_butterfly_unit.sh`: PASS, `pass_count=206 fail_count=0`.
- `run_ntt_addr_gen.sh`: PASS, `pass_count=1792 fail_count=0`.
- `run_ntt_core.sh`: PASS, `pass_count=512 fail_count=0`.
- `run_mod_add.sh`: PASS, `pass_count=1009 fail_count=0`.
- `run_mod_sub.sh`: PASS, `pass_count=1012 fail_count=0`.
- `run_reduction.sh`: PASS, `pass_count=620 fail_count=0`.
- `run_mod_mul.sh`: PASS, `pass_count=1010 fail_count=0`.

Remains to do:

- Add a dedicated self-checking unit test for `intt_butterfly_unit.v`, or
  replace duplicated inverse butterfly logic in `intt_core.v` with the existing
  unit after that unit is verified.
- Consider adding one top-level regression script that runs all current
  arithmetic, NTT, and INTT tests.
- Connect NTT/INTT validation to trusted KAT/golden-reference vectors before
  making cryptographic correctness claims.

## Next Session Start Here

1. Read `TODO.md`.
2. Run `./sim/scripts/run_intt_core.sh`.
3. Review `reports/simulation/intt_core_report.md`.
4. Next best task: add `tb/unit/tb_intt_butterfly_unit.v` or create a unified
   regression script for all current unit tests.

### 2026-07-06 NTT-INTT Round-Trip Verification

Requested:

- Test the flow `poly -> NTT -> INTT -> poly`.
- Write a testbench.
- Do not modify RTL code.

Files changed:

- Added `tb/block/tb_ntt_intt_roundtrip.v`.
- Added `sim/scripts/run_ntt_intt_roundtrip.sh`.
- Added `reports/simulation/ntt_intt_roundtrip_report.md`.
- Updated `reports/simulation/arithmetic_ntt_smoke_report.md` to include the
  round-trip test.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,180p' TODO.md`
- `git status --short`
- `sed -n ... rtl/ntt/ntt_core.v`
- `sed -n ... rtl/ntt/intt_core.v`
- `sed -n ... tb/unit/tb_intt_core.v`
- `chmod +x sim/scripts/run_ntt_intt_roundtrip.sh`
- `./sim/scripts/run_ntt_intt_roundtrip.sh`
- `./sim/scripts/run_ntt_core.sh`
- `./sim/scripts/run_intt_core.sh`
- `apply_patch`

Verified:

- No RTL files were intentionally modified for this task.
- Initial exact raw-poly comparison exposed the expected Kyber representation:
  `NTT -> INTT` returns `input * R mod q`, not raw input, where
  `R = 2^16 mod 3329 = 2285`.
- `run_ntt_intt_roundtrip.sh`: PASS, `pass_count=1024 fail_count=0`, checking
  four 256-coefficient patterns against Montgomery-domain output.
- `run_ntt_core.sh`: PASS, `pass_count=512 fail_count=0`.
- `run_intt_core.sh`: PASS, `pass_count=768 fail_count=0`.

Remains to do:

- If a raw polynomial output is required after INTT, add a planned conversion
  step after the current Montgomery-domain result, or define a separate
  non-Montgomery inverse flow.
- Add `tb/unit/tb_intt_butterfly_unit.v`.
- Consider adding a unified regression script for all current arithmetic, NTT,
  INTT, and round-trip checks.

## Next Session Start Here

1. Read `TODO.md`.
2. Run `./sim/scripts/run_ntt_intt_roundtrip.sh`.
3. Review `reports/simulation/ntt_intt_roundtrip_report.md`.
4. Decide whether the next target is raw-domain post-INTT conversion,
   `intt_butterfly_unit` verification, or a unified regression script.

### 2026-07-06 basemul_unit Verification

Requested:

- Test `rtl/ntt/basemul_unit.v`.

Files changed:

- Fixed mechanical compile blockers in `rtl/ntt/basemul_unit.v`:
  trailing output-port comma, duplicate `a0_reg`, `status` typo, `to_reg`
  typo, missing case-label colon, and `ST_MUL_T0_ZETA` state-name mismatch.
- Added `tb/unit/tb_basemul_unit.v`.
- Added `sim/scripts/run_basemul_unit.sh`.
- Added `reports/simulation/basemul_unit_report.md`.
- Updated `reports/simulation/arithmetic_ntt_smoke_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,160p' TODO.md`
- `rg -n "basemul|ntt_core|intt_core|butterfly" /home/hien/.codex/memories/MEMORY.md`
- `find rtl tb sim/scripts reports/simulation -maxdepth 3 -type f | sort | rg 'basemul|ntt|mul|butterfly'`
- `git status --short`
- `sed -n ... rtl/ntt/basemul_unit.v`
- `sed -n ... ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/Reference_Implementation/crypto_kem/kyber768/ntt.c`
- `sed -n ... tb/unit/tb_mod_mul.v`
- `sed -n ... sim/scripts/run_mod_mul.sh`
- `iverilog -g2012 -Wall -I rtl/common -o /tmp/basemul_unit_check.out ... rtl/ntt/basemul_unit.v`
- `chmod +x sim/scripts/run_basemul_unit.sh`
- `./sim/scripts/run_basemul_unit.sh`
- `./sim/scripts/run_mod_mul.sh`
- `./sim/scripts/run_mod_add.sh`
- `apply_patch`

Verified:

- `basemul_unit.v` elaborates with Icarus Verilog after mechanical fixes.
- `run_basemul_unit.sh`: PASS, `pass_count=507 fail_count=0`.
- `run_mod_mul.sh`: PASS, `pass_count=1010 fail_count=0`.
- `run_mod_add.sh`: PASS, `pass_count=1009 fail_count=0`.
- Testbench covers seven directed cases and 500 random canonical coefficient
  tuples against the Kyber `basemul()` equation.

Remains to do:

- Decide whether to integrate `basemul_unit` into a higher-level pointwise
  polynomial/vector multiplication block.
- Add a unified regression script for arithmetic, butterfly, basemul, NTT,
  INTT, and round-trip checks.
- Continue KAT/golden-reference planning before cryptographic correctness
  claims.

## Next Session Start Here

1. Read `TODO.md`.
2. Run `./sim/scripts/run_basemul_unit.sh`.
3. Review `reports/simulation/basemul_unit_report.md`.
4. Next useful target: pointwise multiplication planning or a unified regression
   script.

### 2026-07-06 GitHub Push Checkpoint

Requested:

- Push the current code to GitHub to save progress.

Files changed:

- Included the current INTT core, NTT/INTT round-trip, basemul unit, testbench,
  run-script, report, TODO, and agent-workflow updates in one checkpoint.
- Removed trailing whitespace from `.agents/workflows/startpqc.md` and
  `rtl/ntt/ntt_core.v` so `git diff --check` is clean.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `tail -n 140 TODO.md`
- `git status --short`
- `git diff --stat`
- `git remote -v`
- `git branch --show-current`
- `./sim/scripts/run_basemul_unit.sh`
- `./sim/scripts/run_intt_core.sh`
- `./sim/scripts/run_ntt_intt_roundtrip.sh`
- `./sim/scripts/run_ntt_core.sh`
- `git diff --check`
- `apply_patch`

Verified:

- `run_basemul_unit.sh`: PASS, `pass_count=507 fail_count=0`.
- `run_intt_core.sh`: PASS, `pass_count=768 fail_count=0`.
- `run_ntt_intt_roundtrip.sh`: PASS, `pass_count=1024 fail_count=0`.
- `run_ntt_core.sh`: PASS, `pass_count=512 fail_count=0`.
- `git diff --check` was run before staging; trailing whitespace was fixed.
- Created commit `3646f2b` with the RTL and verification checkpoint.
- Pushed `3646f2b` to `origin/main`.

Remains to do:

- Continue from the pushed checkpoint on `origin/main`.

## Next Session Start Here

1. Read `TODO.md`.
2. Confirm the latest pushed commit hash.
3. Run the desired next regression script or start pointwise multiplication
   planning.

### 2026-07-06 High-Frequency Basemul Direction Update

Requested:

- Update the project direction globally from area-saving/resource-optimized
  style to correctness-first, high-frequency/Fmax-first RTL after correctness.
- Keep the repository structure unchanged.
- Convert `rtl/ntt/basemul_unit.v` into the main high-throughput pipelined
  basemul implementation.
- Update the basemul testbench, run script, reports, and project handoff.

Files changed:

- Updated `.agents/workflows/AGENT.md` with architecture priority and future
  agent behavior.
- Updated `README.md`.
- Updated `docs/00_project_spec/project_spec.md`.
- Updated `docs/00_project_spec/roadmap.md`.
- Updated `docs/03_architecture/ntt_architecture.md`.
- Updated `rtl/ntt/basemul_unit.v` from sequential `start/busy/done` style to
  a valid-only 3-stage pipelined implementation.
- Updated `tb/unit/tb_basemul_unit.v` for the pipeline interface and latency
  checks.
- Updated `sim/scripts/run_basemul_unit.sh`.
- Updated `reports/simulation/basemul_unit_report.md`.
- Updated `reports/simulation/arithmetic_ntt_smoke_report.md`.
- Updated `TODO.md` with priority and this handoff entry.

Commands run:

- `pwd`
- `sed -n '1,180p' TODO.md`
- `rg -n "basemul|high-frequency|Fmax|Architecture Priority|area|pipeline|pipelined|Post_Quantum_Cryptography" /home/hien/.codex/memories/MEMORY.md`
- `git status --short`
- `find . -name 'AGENTS.md' -o -name 'AGENT.md' -o -name 'agent.md' | sort`
- `sed -n ... .agents/workflows/AGENT.md README.md docs/00_project_spec/project_spec.md docs/00_project_spec/roadmap.md docs/03_architecture/ntt_architecture.md`
- `sed -n ... rtl/ntt/basemul_unit.v tb/unit/tb_basemul_unit.v sim/scripts/run_basemul_unit.sh reports/simulation/basemul_unit_report.md reports/simulation/arithmetic_ntt_smoke_report.md`
- `./sim/scripts/run_basemul_unit.sh`
- `./sim/scripts/run_mod_mul.sh`
- `./sim/scripts/run_mod_add.sh`
- `./sim/scripts/run_ntt_core.sh`
- `./sim/scripts/run_intt_core.sh`
- `./sim/scripts/run_ntt_intt_roundtrip.sh`
- `git diff --check`
- `git status --short`
- `git diff --stat`
- `apply_patch`

Verified:

- `run_basemul_unit.sh`: PASS, `tx_count=514`, `pass_count=514`,
  `fail_count=0`.
- `run_mod_mul.sh`: PASS, `pass_count=1010 fail_count=0`.
- `run_mod_add.sh`: PASS, `pass_count=1009 fail_count=0`.
- `run_ntt_core.sh`: PASS, `pass_count=512 fail_count=0`.
- `run_intt_core.sh`: PASS, `pass_count=768 fail_count=0`.
- `run_ntt_intt_roundtrip.sh`: PASS, `pass_count=1024 fail_count=0`.
- `git diff --check`: clean after final edits.

Remains to do:

- Integrate the pipelined `basemul_unit` into future poly-level pointwise
  multiplication.
- Delay write addresses, zeta indices, coefficient-pair indices, and valid
  strobes by the basemul pipeline latency in future poly-level users.
- Pipeline `mod_mul` / Montgomery reduction later if synthesis or timing review
  identifies it as the critical path; this will require basemul latency
  realignment.
- Connect these block tests to trusted KAT/golden-reference verification before
  full ML-KEM correctness claims.

## Next Session Start Here

1. Read `TODO.md`.
2. Run `./sim/scripts/run_basemul_unit.sh`.
3. Review `reports/simulation/basemul_unit_report.md`.
4. Start poly-level pointwise multiplication planning around the 3-cycle
   valid-only pipelined `basemul_unit` interface.

### 2026-07-06 Markdown Project Orientation Refresh

Requested:

- Read the project Markdown files to understand what the project needs to do.

Files changed:

- Updated `TODO.md` with this handoff entry.

Commands run:

- `pwd`
- `rg --files -g 'TODO.md' -g '*.md'`
- `rg -n "Post_Quantum_Cryptography|ML-KEM|Kyber|TODO|M1|Algorithm|Verification" /home/hien/.codex/memories/MEMORY.md`
- `sed -n ... TODO.md`
- `sed -n ... README.md`
- `sed -n ... Roadmap.md`
- `sed -n ... CHANGELOG.md`
- `wc -l ...` over repository Markdown files
- `awk ...` over active docs, report docs, reference docs, folder READMEs, and archived Markdown scaffolds
- `git status --short`
- `tail -n 80 TODO.md`

Verified:

- `TODO.md` exists in the project root and is the persistent handoff file.
- Repository Markdown files were reviewed, including active project docs,
  standards/math/architecture/verification notes, simulation reports, reference
  docs, folder READMEs, and archived scaffold notes.
- Current milestone remains `M1: Algorithm and Verification Foundation`.
- Active scope remains standards/reference model/KAT/RTL/testbench/simulation/
  architecture/verification.
- Current phase still excludes Genus, Innovus, PnR, STA, GDSII, and Physical
  Design.
- Existing docs point the next technical work toward pipelined basemul
  integration, pointwise multiplication planning, unified regression, and
  trusted KAT/golden-reference comparison.

Remains to do:

- Integrate the 3-cycle valid-only pipelined `basemul_unit` into future
  poly-level pointwise multiplication.
- Add or finish a unified regression script for current unit/block tests.
- Fill FIPS 203 notes and choose the exact trusted ML-KEM/Kyber-768 KAT
  baseline.
- Connect RTL simulation outputs to a trusted golden-reference/KAT comparison
  before making full cryptographic correctness claims.

## Next Session Start Here

1. Read `TODO.md`.
2. Review `README.md`, `docs/00_project_spec/roadmap.md`, and
   `docs/03_architecture/ntt_architecture.md`.
3. Run the relevant current script, especially
   `./sim/scripts/run_basemul_unit.sh`, before changing datapath logic.
4. Start from poly-level pointwise multiplication planning around the 3-cycle
   valid-only pipelined `basemul_unit`, or create the unified regression script.

### 2026-07-06 poly_basemul_addr_gen Verification

Requested:

- User wrote `rtl/poly/poly_basemul_addr_gen.v`.
- Add a self-checking testbench and test it.
- Do not modify the user's RTL.

Files changed:

- Added `tb/unit/tb_poly_basemul_addr_gen.v`.
- Added `sim/scripts/run_poly_basemul_addr_gen.sh`.
- Added `reports/simulation/poly_basemul_addr_gen_report.md`.
- Updated `reports/simulation/arithmetic_ntt_smoke_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,220p' TODO.md`
- `rg --files rtl tb sim/scripts reports/simulation | sort`
- `rg -n "poly_basemul|basemul|pointwise|poly" /home/hien/.codex/memories/MEMORY.md`
- `nl -ba rtl/poly/poly_basemul_addr_gen.v`
- `sed -n ... tb/unit/tb_ntt_addr_gen.v`
- `sed -n ... tb/unit/tb_basemul_unit.v`
- `sed -n ... sim/scripts/run_ntt_addr_gen.sh`
- `sed -n ... sim/scripts/run_basemul_unit.sh`
- `sed -n '1,180p' rtl/common/kyber_params.vh`
- `git status --short`
- `apply_patch`
- `chmod +x sim/scripts/run_poly_basemul_addr_gen.sh`
- `./sim/scripts/run_poly_basemul_addr_gen.sh`

Verified:

- The new testbench checks the documented Kyber `poly_basemul_montgomery`
  schedule for all 128 base-multiplication operations.
- Checked every generated operation for `op_index`, `a_addr0/a_addr1`,
  `b_addr0/b_addr1`, `r_addr0/r_addr1`, `zeta_addr`, and `zeta_neg`.
- Checked reset idle behavior, active `valid`/`busy`, one-cycle `done`, and
  idle state after completion.
- Ran the full 128-operation schedule twice.
- During the second run, pulsed `start` while `busy` was already high and
  verified that the active schedule continued instead of restarting.
- `./sim/scripts/run_poly_basemul_addr_gen.sh`: PASS,
  `pass_count=256 fail_count=0`.
- `rtl/poly/poly_basemul_addr_gen.v` was not modified.

Remains to do:

- Integrate this address generator with the 3-cycle pipelined `basemul_unit` in
  the future poly-level pointwise multiplication block.
- Delay output write addresses, coefficient-pair metadata, zeta-control
  metadata, and valid strobes to match basemul pipeline latency.
- Continue connecting poly-level tests to trusted KAT/golden-reference
  comparison before full cryptographic correctness claims.

## Next Session Start Here

1. Read `TODO.md`.
2. Run `./sim/scripts/run_poly_basemul_addr_gen.sh`.
3. Review `reports/simulation/poly_basemul_addr_gen_report.md`.
4. Next best technical target: integrate `poly_basemul_addr_gen` with the
   3-cycle valid-only pipelined `basemul_unit` while delaying write/control
   metadata by the same latency.

### 2026-07-06 poly_basemul_montgomery Testbench Bring-up

Requested:

- User wrote `rtl/poly/poly_basemul_montgomery.v`.
- Add a testbench and test it.
- Do not modify the user's RTL.

Files changed:

- Added `tb/unit/tb_poly_basemul_montgomery.v`.
- Added `sim/scripts/run_poly_basemul_montgomery.sh`.
- Added `reports/simulation/poly_basemul_montgomery_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,180p' TODO.md`
- `rg --files rtl tb sim/scripts reports/simulation | sort`
- `git status --short`
- `nl -ba rtl/poly/poly_basemul_montgomery.v`
- `nl -ba rtl/poly/poly_basemul_addr_gen.v`
- `nl -ba rtl/ntt/basemul_unit.v`
- `sed -n ... tb/unit/tb_poly_basemul_addr_gen.v`
- `nl -ba rtl/memory/poly_buffer.v`
- `nl -ba rtl/ntt/zetas_rom.v`
- `rg -n "poly_basemul_montgomery|poly_basemul" ref_model/c_ref docs rtl tb sim reports -S`
- `apply_patch`
- `chmod +x sim/scripts/run_poly_basemul_montgomery.sh`
- `./sim/scripts/run_poly_basemul_montgomery.sh`
- `git diff --check`
- `tail -n 120 sim/logs/poly_basemul_montgomery.log`

Verified:

- Added a self-checking full-polynomial testbench for the intended
  `poly_basemul_montgomery` interface.
- The testbench is designed to load full A and B polynomials, compute expected
  output with the Kyber `poly_basemul_montgomery` / `basemul` equations, wait
  for `done`, and compare all 256 R coefficients for three deterministic
  polynomial patterns.
- The run script compiles all current dependencies:
  `reduction`, `mod_mul`, `mod_add`, `basemul_unit`, `zetas_rom`,
  `poly_buffer`, `poly_basemul_addr_gen`, and `poly_basemul_montgomery`.
- Current DUT test is blocked at RTL compile.
- First compiler blocker:
  `rtl/poly/poly_basemul_montgomery.v:85: error: Superfluous comma in port declaration list.`
- Additional visible RTL blockers include malformed `poly_buffer` instance
  punctuation, duplicate `r_addr0_d0`, typo `always $(`, missing semicolon after
  `r_addr1_d1 <= r_addr1_d0`, implicit `r_write_valid/r_write_last`, and
  duplicated/misnamed R-buffer write ports.
- `rtl/poly/poly_basemul_montgomery.v` was not modified.
- `git diff --check`: clean.

Remains to do:

- Fix `rtl/poly/poly_basemul_montgomery.v` compile blockers, starting with the
  port list around line 85.
- Add the missing intended A-load ports (`a_load_en`, `a_load_addr`,
  `a_load_data`) to the module interface or otherwise define how polynomial A is
  loaded; the RTL already references those signals internally.
- After RTL compiles, rerun `./sim/scripts/run_poly_basemul_montgomery.sh` for
  functional full-polynomial comparison.

## Next Session Start Here

1. Read `TODO.md`.
2. Fix `rtl/poly/poly_basemul_montgomery.v` compile blockers.
3. Rerun `./sim/scripts/run_poly_basemul_montgomery.sh`.
4. If compile passes but output mismatches remain, inspect address/data latency
   alignment between `poly_basemul_addr_gen`, `poly_buffer`, and the 3-cycle
   pipelined `basemul_unit`.

### 2026-07-07 poly_basemul_montgomery Retest

Requested:

- Retest `rtl/poly/poly_basemul_montgomery.v` after user-side fixes.
- Do not modify RTL.

Files changed:

- Updated `reports/simulation/poly_basemul_montgomery_report.md`.
- Updated `TODO.md` with this retest entry.

Commands run:

- `sed -n '1,220p' TODO.md`
- `git status --short`
- `nl -ba rtl/poly/poly_basemul_montgomery.v | sed -n '1,380p'`
- `./sim/scripts/run_poly_basemul_montgomery.sh`
- `nl -ba rtl/poly/poly_basemul_montgomery.v | sed -n '168,225p'`
- `nl -ba rtl/poly/poly_basemul_montgomery.v | sed -n '288,330p'`
- `tail -n 80 sim/logs/poly_basemul_montgomery.log`

Verified:

- The previous top-level trailing comma and duplicate `r_addr0_d0` declaration
  are fixed.
- Test remains blocked at RTL compile.
- Current first compiler error:
  `rtl/poly/poly_basemul_montgomery.v:191: syntax error`.
- Remaining visible blockers include trailing commas at the final named port
  connections of the A, B, and R `poly_buffer` instances, duplicate instance
  name `u_a_buffer` for the B buffer, misspelled declarations
  `r_wrire_valid/r_wrire_last`, and missing intended A-load ports in the module
  interface.
- `rtl/poly/poly_basemul_montgomery.v` was not modified.

Remains to do:

- Remove trailing commas from final named port connections at the A/B/R
  `poly_buffer` instances.
- Rename the B buffer instance from `u_a_buffer` to a unique name such as
  `u_b_buffer`.
- Rename `r_wrire_valid/r_wrire_last` to `r_write_valid/r_write_last`.
- Add intended `a_load_en`, `a_load_addr`, and `a_load_data` ports to the
  module interface, or define another A-load interface and update the testbench
  accordingly.
- Rerun `./sim/scripts/run_poly_basemul_montgomery.sh`.

## Next Session Start Here

1. Read `TODO.md`.
2. Fix the remaining compile blockers in `rtl/poly/poly_basemul_montgomery.v`.
3. Rerun `./sim/scripts/run_poly_basemul_montgomery.sh`.
4. If it compiles, inspect any coefficient mismatches for basemul/data/address
   latency alignment.

### 2026-07-07 poly_basemul_montgomery Retest 2

Requested:

- Retest `rtl/poly/poly_basemul_montgomery.v` after another user-side fix.
- Do not modify RTL.

Files changed:

- Updated `reports/simulation/poly_basemul_montgomery_report.md`.
- Updated `TODO.md` with this retest entry.

Commands run:

- `sed -n '1,180p' TODO.md`
- `git status --short`
- `nl -ba rtl/poly/poly_basemul_montgomery.v | sed -n '66,340p'`
- `./sim/scripts/run_poly_basemul_montgomery.sh`
- `tail -n 80 sim/logs/poly_basemul_montgomery.log`
- `nl -ba rtl/poly/poly_basemul_montgomery.v | sed -n '72,86p;170,206p'`

Verified:

- The previous final-port trailing commas and `r_write_*` spelling issue are
  fixed.
- Test remains blocked at RTL compile.
- Current hard compiler error:
  `rtl/poly/poly_basemul_montgomery.v:202: error: 'u_a_buffer' has already been declared in this scope.`
- Current warnings show `a_load_addr` and `a_load_data` are still implicit
  wires because the module port list exposes only B-load ports.
- `rtl/poly/poly_basemul_montgomery.v` was not modified.

Remains to do:

- Rename the B buffer instance from `u_a_buffer` to a unique name such as
  `u_b_buffer`.
- Add intended `a_load_en`, `a_load_addr`, and `a_load_data` ports to the
  module interface, or define another A-load interface and update the testbench
  accordingly.
- Rerun `./sim/scripts/run_poly_basemul_montgomery.sh`.

## Next Session Start Here

1. Read `TODO.md`.
2. Rename the B-buffer instance and finish the A-load interface in
   `rtl/poly/poly_basemul_montgomery.v`.
3. Rerun `./sim/scripts/run_poly_basemul_montgomery.sh`.
4. If it compiles, evaluate any full-polynomial coefficient mismatches.

### 2026-07-07 poly_basemul_montgomery Retest PASS

Requested:

- Retest `rtl/poly/poly_basemul_montgomery.v` after user-side fixes.
- Do not modify RTL.

Files changed:

- Updated `reports/simulation/poly_basemul_montgomery_report.md`.
- Updated `reports/simulation/arithmetic_ntt_smoke_report.md`.
- Updated `TODO.md` with this retest entry.

Commands run:

- `sed -n '1,160p' TODO.md`
- `git status --short`
- `nl -ba rtl/poly/poly_basemul_montgomery.v | sed -n '72,220p'`
- `./sim/scripts/run_poly_basemul_montgomery.sh`

Verified:

- `poly_basemul_montgomery.v` now compiles.
- `./sim/scripts/run_poly_basemul_montgomery.sh`: PASS,
  `pass_count=768 fail_count=0`.
- The testbench checked three deterministic full-polynomial A/B patterns.
- All 256 R coefficients per pattern matched the behavioral Kyber
  `poly_basemul_montgomery` / `basemul` reference.
- `rtl/poly/poly_basemul_montgomery.v` was not modified by the reviewer.

Remains to do:

- Add `poly_basemul_montgomery` to any future unified regression script.
- Consider a higher-level polyvec accumulation test after the poly-level
  basemul datapath is stable.
- Continue connecting these RTL checks to trusted KAT/golden-reference flow
  before full ML-KEM correctness claims.

## Next Session Start Here

1. Read `TODO.md`.
2. Run `./sim/scripts/run_poly_basemul_montgomery.sh`.
3. Review `reports/simulation/poly_basemul_montgomery_report.md`.
4. Next useful target: add a unified regression script or start polyvec
   pointwise accumulation planning on top of the verified poly basemul block.

### 2026-07-07 GitHub Checkpoint Push

Requested:

- Push the repository to GitHub to save the current progress.

Files changed:

- `.agents/workflows/AGENT.md`
- `README.md`
- `TODO.md`
- `docs/00_project_spec/project_spec.md`
- `docs/00_project_spec/roadmap.md`
- `docs/03_architecture/ntt_architecture.md`
- `reports/simulation/arithmetic_ntt_smoke_report.md`
- `reports/simulation/basemul_unit_report.md`
- `reports/simulation/poly_basemul_addr_gen_report.md`
- `reports/simulation/poly_basemul_montgomery_report.md`
- `rtl/ntt/basemul_unit.v`
- `rtl/poly/poly_basemul_addr_gen.v`
- `rtl/poly/poly_basemul_montgomery.v`
- `sim/scripts/run_basemul_unit.sh`
- `sim/scripts/run_poly_basemul_addr_gen.sh`
- `sim/scripts/run_poly_basemul_montgomery.sh`
- `tb/unit/tb_basemul_unit.v`
- `tb/unit/tb_poly_basemul_addr_gen.v`
- `tb/unit/tb_poly_basemul_montgomery.v`

Commands run:

- `pwd && git rev-parse --show-toplevel && git status --short --branch`
- `sed -n '1,220p' TODO.md`
- `git diff --cached --stat`
- `git diff --cached --name-status`
- `git diff --cached -- rtl/ntt/basemul_unit.v rtl/poly/poly_basemul_addr_gen.v rtl/poly/poly_basemul_montgomery.v tb/unit/tb_basemul_unit.v tb/unit/tb_poly_basemul_addr_gen.v tb/unit/tb_poly_basemul_montgomery.v sim/scripts/run_basemul_unit.sh sim/scripts/run_poly_basemul_addr_gen.sh sim/scripts/run_poly_basemul_montgomery.sh`
- `tail -n 180 TODO.md`
- `./sim/scripts/run_basemul_unit.sh`
- `./sim/scripts/run_poly_basemul_addr_gen.sh`
- `./sim/scripts/run_poly_basemul_montgomery.sh`
- `git diff --cached --check`
- `nl -ba rtl/poly/poly_basemul_addr_gen.v | sed -n '36,46p'`
- `nl -ba rtl/poly/poly_basemul_montgomery.v | sed -n '64,92p;148,190p;204,218p;242,286p;310,320p'`
- `apply_patch`
- `git diff --check`

Verified:

- `./sim/scripts/run_basemul_unit.sh`: PASS,
  `pass_count=514 fail_count=0`.
- `./sim/scripts/run_poly_basemul_addr_gen.sh`: PASS,
  `pass_count=256 fail_count=0`.
- `./sim/scripts/run_poly_basemul_montgomery.sh`: PASS,
  `pass_count=768 fail_count=0`.
- `git diff --check`: clean after removing staged trailing whitespace.

Remains to do:

- Add a unified regression script for the arithmetic, NTT, and poly-level
  unit tests.
- Consider polyvec pointwise accumulation after the poly basemul datapath
  remains stable.
- Continue connecting the RTL checks to trusted KAT/golden-reference flow
  before full ML-KEM correctness claims.

## Next Session Start Here

1. Read `TODO.md`.
2. Run the focused checks:
   `./sim/scripts/run_basemul_unit.sh`,
   `./sim/scripts/run_poly_basemul_addr_gen.sh`, and
   `./sim/scripts/run_poly_basemul_montgomery.sh`.
3. Add a unified regression script or begin polyvec pointwise accumulation
   planning on top of the verified poly basemul block.

### 2026-07-07 Ignore Local Agent Workflows

Requested:

- Add `.agents/workflows` to `.gitignore`.
- Commit and push the ignore/untrack change after GitHub still showed the
  previously tracked `.agents/workflows` directory.

Files changed:

- `.gitignore`
- `TODO.md`
- `.agents/workflows/AGENT.md` will be removed from Git tracking while kept
  locally, because ignored tracked files are still tracked by Git.

Commands run:

- `pwd && git rev-parse --show-toplevel && git status --short --branch`
- `sed -n '1,180p' TODO.md`
- `sed -n '1,240p' .gitignore`
- `git ls-files .agents/workflows .agents/workflows/AGENT.md`
- `find .agents -maxdepth 3 -type f -print`
- `tail -n 100 TODO.md`
- `apply_patch`
- `git rm --cached .agents/workflows/AGENT.md`
- `git status --short --branch`
- `git check-ignore -v .agents/workflows/AGENT.md`
- `git diff --check`
- `ls -la CHANGELOG.md .agents/workflows/AGENT.md`
- `git diff --name-status`
- `git diff --cached --name-status`
- `git status --ignored --short .agents/workflows/AGENT.md CHANGELOG.md .gitignore TODO.md`
- `git add .gitignore TODO.md`
- `git commit -m "chore: ignore local agent workflows"`
- `git push origin main`
- `git status --short --branch`
- `git log -1 --oneline`
- `git check-ignore -v .agents/workflows/AGENT.md`
- `git diff --check`

Verified:

- `.gitignore` contains `.agents/workflows/`.
- `.agents/workflows/AGENT.md` is removed from Git tracking but remains present
  locally.
- `git check-ignore -v .agents/workflows/AGENT.md` reports the
  `.agents/workflows/` rule from `.gitignore`.
- `git diff --check`: clean.
- Pushed commit `9d0358c chore: ignore local agent workflows` to `origin/main`.
- Final branch check reports `main...origin/main`; the only remaining worktree
  change is the unrelated local deletion of `CHANGELOG.md`.

Remains to do:

- None for `.agents/workflows`.

## Next Session Start Here

1. Read `TODO.md`.
2. Continue from the ML-KEM/Kyber algorithm and verification work.
3. Keep local agent workflow files under `.agents/workflows/` out of Git.

### 2026-07-07 Remove CHANGELOG

Requested:

- Confirmed that `CHANGELOG.md` was intentionally deleted because it is no
  longer needed.
- Commit and push the deletion so GitHub matches the local repository state.

Files changed:

- `CHANGELOG.md`
- `TODO.md`

Commands run:

- `git status --short --branch`
- `sed -n '1,120p' TODO.md`
- `tail -n 80 TODO.md`
- `apply_patch`
- `git add CHANGELOG.md TODO.md`
- `git status --short --branch`
- `git diff --cached --name-status`
- `git diff --cached --check`
- `git commit -m "chore: remove obsolete changelog"`
- `git push origin main`

Verified:

- Staged changes were exactly `CHANGELOG.md` deletion and `TODO.md` update.
- `git diff --cached --check`: clean.
- Pushed commit `72b22e1 chore: remove obsolete changelog` to `origin/main`.

Remains to do:

- None after final status verification.

## Next Session Start Here

1. Read `TODO.md`.
2. Continue from the ML-KEM/Kyber algorithm and verification work.
3. `CHANGELOG.md` has been removed intentionally; use `TODO.md`, reports, and
   commit history for handoff/status tracking.

### 2026-07-12 poly_add Testbench Bring-up

Requested:

- User wrote `rtl/poly/poly_add.v`.
- Add a testbench and test it.
- Do not modify the user's RTL; report RTL issues for the user to fix.

Files changed:

- Added `tb/unit/tb_poly_add.v`.
- Added `sim/scripts/run_poly_add.sh`.
- Added `reports/simulation/poly_add_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `sed -n '1,220p' TODO.md`
- `sed -n '1,260p' rtl/poly/poly_add.v`
- `sed -n '1,220p' tb/unit/tb_poly_basemul_montgomery.v`
- `sed -n '1,140p' sim/scripts/run_poly_basemul_montgomery.sh`
- `git status --short --untracked-files=all`
- `sed -n '1,220p' rtl/memory/poly_buffer.v`
- `sed -n '1,120p' rtl/arithmetic/mod_add.v`
- `sed -n '1,220p' sim/scripts/run_poly_basemul_addr_gen.sh`
- `sed -n '1,140p' reports/simulation/poly_basemul_addr_gen_report.md`
- `ls tb/unit sim/scripts reports/simulation | rg 'poly_add|poly'`
- `apply_patch`
- `chmod +x sim/scripts/run_poly_add.sh`
- `./sim/scripts/run_poly_add.sh`
- `nl -ba rtl/poly/poly_add.v | sed -n '68,82p'`
- `tail -n 30 sim/logs/poly_add.log`

Verified:

- Added a self-checking full-polynomial testbench for `poly_add`.
- The testbench loads full A and B polynomials, pulses `start`, waits for
  `done`, reads all 256 R coefficients, and compares each result against
  `(a[i] + b[i]) mod KYBER_Q`.
- Test patterns cover all-zero operands, complementary operands, max canonical
  operands, and nontrivial arithmetic sequences.
- `./sim/scripts/run_poly_add.sh`: PASS, `pass_count=1024 fail_count=0`.
- `rtl/poly/poly_add.v` was not modified.

RTL warning for user to fix:

- `rtl/poly/poly_add.v` line 75 declares `start_acccepted`, but line 76 assigns
  `start_accepted`. Icarus Verilog creates `start_accepted` as an implicit wire,
  so the simulation still passes, but the typo should be fixed in RTL.

Remains to do:

- User should fix the `start_acccepted` / `start_accepted` spelling mismatch in
  `rtl/poly/poly_add.v`.
- Add `poly_add` to any future unified regression script.
- Consider adding `poly_sub` after the polynomial-add path is clean.

## Next Session Start Here

1. Read `TODO.md`.
2. Fix the `start_acccepted` typo in `rtl/poly/poly_add.v`.
3. Rerun `./sim/scripts/run_poly_add.sh`.
4. If clean, add `poly_add` to the future unified regression script.

### 2026-07-12 poly_add Retest After RTL Typo Fix

Requested:

- User fixed the `start_acccepted` / `start_accepted` typo in
  `rtl/poly/poly_add.v`.
- Rerun the focused `poly_add` test.

Files changed:

- Updated `reports/simulation/poly_add_report.md`.
- Updated `TODO.md` with this retest entry.

Commands run:

- `./sim/scripts/run_poly_add.sh`
- `nl -ba rtl/poly/poly_add.v | sed -n '70,78p'`

Verified:

- `rtl/poly/poly_add.v` now declares and assigns `start_accepted` consistently.
- `./sim/scripts/run_poly_add.sh`: PASS, `pass_count=1024 fail_count=0`.
- The prior implicit-wire warning is gone.

Remains to do:

- Add `poly_add` to any future unified regression script.
- Consider adding `poly_sub` after the polynomial-add path is clean.

## Next Session Start Here

1. Read `TODO.md`.
2. Run `./sim/scripts/run_poly_add.sh` if continuing polynomial-add work.
3. Add `poly_add` to the future unified regression script or start `poly_sub`
   planning.

### 2026-07-12 poly_sub Testbench Bring-up

Requested:

- Verify `rtl/poly/poly_sub.v`.
- Add a testbench and test it.
- Do not modify the user's RTL; report RTL issues for the user to fix.

Files changed:

- Added `tb/unit/tb_poly_sub.v`.
- Added `sim/scripts/run_poly_sub.sh`.
- Added `reports/simulation/poly_sub_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `tail -n 140 TODO.md`
- `ls rtl/poly tb/unit sim/scripts reports/simulation | rg 'poly_sub|poly_add' || true`
- `test -f rtl/poly/poly_sub.v && sed -n '1,260p' rtl/poly/poly_sub.v || true`
- `sed -n '1,260p' tb/unit/tb_poly_add.v`
- `sed -n '1,120p' sim/scripts/run_poly_add.sh`
- `sed -n '1,120p' rtl/arithmetic/mod_sub.v`
- `apply_patch`
- `chmod +x sim/scripts/run_poly_sub.sh`
- `./sim/scripts/run_poly_sub.sh`
- `nl -ba rtl/poly/poly_sub.v | sed -n '140,164p'`
- `grep -n "warning\\|FIRST_FAIL\\|pass_count\\|FAIL\\|PASS" sim/logs/poly_sub.log | sed -n '1,80p'`

Verified:

- Added a self-checking full-polynomial testbench for `poly_sub`.
- The testbench loads full A and B polynomials, pulses `start`, waits for
  `done`, reads all 256 R coefficients, and compares each result against
  `(a[i] - b[i]) mod KYBER_Q`.
- Test patterns cover all-zero operands, equal operands, full wraparound
  `0 - (KYBER_Q - 1)`, and nontrivial arithmetic sequences.
- `./sim/scripts/run_poly_sub.sh`: FAIL, `pass_count=0 fail_count=1024`.
- `rtl/poly/poly_sub.v` was not modified.

RTL issue for user to fix:

- `rtl/poly/poly_sub.v` lines 147-148 declare `sub_result0` and `sub_result1`.
- Lines 153 and 159 connect the `mod_sub` outputs to undeclared
  `add_result0` and `add_result1`.
- Icarus Verilog creates `add_result0/add_result1` as implicit 1-bit wires,
  while `sub_result0/sub_result1` remain undriven.
- The result buffer writes `sub_result0/sub_result1`, so every checked output is
  high-Z.

Remains to do:

- User should connect the two `mod_sub` output ports to `sub_result0` and
  `sub_result1`.
- Rerun `./sim/scripts/run_poly_sub.sh`.
- If the focused test passes, add `poly_sub` to any future unified regression
  script.

## Next Session Start Here

1. Read `TODO.md`.
2. Fix the `mod_sub` output wiring in `rtl/poly/poly_sub.v`.
3. Rerun `./sim/scripts/run_poly_sub.sh`.
4. If clean, add `poly_sub` to the future unified regression script.

### 2026-07-12 reduction.v Rewrite Verification

Requested:

- User rewrote `rtl/arithmetic/reduction.v`.
- Verify the rewritten reduction RTL.
- Do not modify the user's RTL.

Files changed:

- Updated `tb/unit/tb_reduction.v` to match the rewritten unsigned/canonical
  reducer contract.
- Updated `reports/simulation/reduction_mod_mul_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `tail -n 120 TODO.md`
- `ls rtl/arithmetic`
- `sed -n '1,260p' rtl/arithmetic/reduction.v`
- `sed -n '1,240p' tb/unit/tb_reduction.v`
- `sed -n '1,120p' sim/scripts/run_reduction.sh`
- `git status --short --untracked-files=all`
- `./sim/scripts/run_reduction.sh`
- `./sim/scripts/run_mod_mul.sh`
- `sed -n '1,140p' rtl/arithmetic/mod_mul.v`
- `sed -n '1,160p' reports/simulation/reduction_mod_mul_report.md`
- `tail -n 80 sim/logs/reduction.log`
- `tail -n 60 sim/logs/mod_mul.log`
- `apply_patch`
- `nl -ba tb/unit/tb_reduction.v | sed -n '118,150p'`
- `./sim/scripts/run_reduction.sh`

Verified:

- `rtl/arithmetic/reduction.v` was not modified by the verifier.
- `tb_reduction.v` was updated because the rewritten RTL now documents an
  unsigned/canonical output contract instead of the old signed C-style
  representative contract.
- `./sim/scripts/run_reduction.sh`: PASS, `pass_count=618 fail_count=0`.
- The final focused reduction run is warning-clean.

Dependent check:

- `./sim/scripts/run_mod_mul.sh` is blocked at elaboration:
  `rtl/arithmetic/mod_mul.v:44: error: Cannot override localparam Q in
  tb_mod_mul.dut.u_montgomery_reduce`.
- Root cause: `mod_mul.v` still instantiates `montgomery_reduce #(.Q(Q))`, but
  the rewritten `montgomery_reduce` now defines `Q` as a `localparam`, not an
  overrideable parameter.

Remains to do:

- User should update `rtl/arithmetic/mod_mul.v` for the new `montgomery_reduce`
  interface and unsigned/canonical output behavior.
- After that, rerun `./sim/scripts/run_mod_mul.sh`.
- Because `mod_mul` feeds higher-level NTT and basemul blocks, rerun dependent
  tests after the mod-mul wrapper is fixed.

## Next Session Start Here

1. Read `TODO.md`.
2. Fix `rtl/arithmetic/mod_mul.v` line 44 to match the new
   `montgomery_reduce` interface.
3. Rerun `./sim/scripts/run_mod_mul.sh`.
4. If `mod_mul` passes, rerun dependent arithmetic/NTT/basemul regressions.

### 2026-07-12 Unsigned mod_mul Repair And Verification

Requested:

- Fix `rtl/arithmetic/mod_mul.v` for the rewritten unsigned/canonical
  Montgomery reducer.
- Do not use signed arithmetic for `mod_mul`.
- Verify the repaired module and its direct dependents.

Files changed:

- Updated `rtl/arithmetic/mod_mul.v`.
- Updated `tb/unit/tb_mod_mul.v` to use an unsigned REDC oracle.
- Updated `reports/simulation/reduction_mod_mul_report.md`.
- Updated `TODO.md` with this handoff entry.

Commands run:

- `rg -n "signed|\$signed|>>>" rtl/arithmetic/mod_mul.v tb/unit/tb_mod_mul.v || true`
- `./sim/scripts/run_mod_mul.sh`
- `./sim/scripts/run_reduction.sh`
- `./sim/scripts/run_basemul_unit.sh`
- `./sim/scripts/run_poly_basemul_montgomery.sh`
- `./sim/scripts/run_ntt_core.sh`
- `./sim/scripts/run_intt_core.sh`
- `./sim/scripts/run_ntt_intt_roundtrip.sh`
- `git diff --check`

Verified:

- `mod_mul.v` uses only unsigned declarations and operations.
- `tb_mod_mul.v` uses only unsigned declarations and operations for its REDC
  oracle.
- `run_mod_mul.sh`: PASS, `pass_count=1010 fail_count=0`.
- `run_reduction.sh`: PASS, `pass_count=618 fail_count=0`.
- `run_basemul_unit.sh`: PASS, `pass_count=514 fail_count=0`.
- `run_poly_basemul_montgomery.sh`: PASS,
  `pass_count=768 fail_count=0`.
- `run_ntt_core.sh`: PASS, `pass_count=512 fail_count=0`.
- `run_intt_core.sh`: PASS, `pass_count=768 fail_count=0`.
- `run_ntt_intt_roundtrip.sh`: PASS, `pass_count=1024 fail_count=0`.

Remains to do:

- `rtl/arithmetic/reduction.v` still has two internal `wire signed`
  declarations despite its unsigned-only module contract. This file was not
  changed during the focused `mod_mul.v` repair.
- Rerun the polynomial-subtraction test after the user fixes its output wiring.
- Consider pipelining `mod_mul` only after synthesis identifies this
  combinational implementation as a timing limiter.

## Next Session Start Here

1. Read `TODO.md`.
2. If enforcing unsigned-only arithmetic across the whole reducer chain,
   replace the two remaining signed declarations in `reduction.v` and rerun
   the complete arithmetic/NTT/basemul regression set.
3. Otherwise continue with the pending `poly_sub` RTL wiring fix and rerun
   `./sim/scripts/run_poly_sub.sh`.

### 2026-07-12 M0.1 Source Standards And Provenance Audit

Requested:

- Proceed with M0.1 only: source, standards, and provenance audit.
- Make M0 the official first milestone, replacing the old `M1: Algorithm and
  Verification Foundation` wording.
- Keep the local Kyber 2020 C implementation and KATs labeled as legacy Kyber
  regression material, not final FIPS 203 validation evidence.
- Create SHA-256 hashes for local standards.
- Create the canonical FIPS 203 algorithm tracking file at
  `docs/00_project_spec/fips203_algorithm_tracking.md`.
- Do not modify RTL, testbenches, simulation scripts, imported Kyber C source,
  Python model, comparison tools, or KAT workspace.

Files changed:

- `TODO.md`
- `docs/00_project_spec/m0_plan.md`
- `docs/00_project_spec/roadmap.md`
- `docs/00_project_spec/milestone_status.md`
- `docs/00_project_spec/project_spec.md`
- `docs/00_project_spec/fips203_algorithm_tracking.md`
- `docs/01_standard/source_provenance.md`
- `reports/m0_source_audit.md`
- `references/SHA256SUMS`

Commands run:

- `pwd`
- `git branch --show-current`
- `git status --short`
- `git worktree list`
- `sed -n '1,520p' AGENTS.md`
- `find docs/00_project_spec docs/01_standard reports references -maxdepth 2 -type f | sort`
- `sed -n ... TODO.md docs/00_project_spec/roadmap.md docs/00_project_spec/milestone_status.md docs/00_project_spec/project_spec.md`
- `git log --oneline --decorate -5`
- `command -v pdftotext`
- `command -v pdfinfo`
- `pdfinfo references/standards/*.pdf`
- `find ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001 -maxdepth 3 -type f | sort`
- `find ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/KAT -type f -printf '%p %s bytes\n' | sort`
- `pdftotext -layout references/standards/NIST.FIPS.203.pdf - | rg ...`
- `pdftotext -layout references/standards/nist.fips.202.pdf - | rg ...`
- `pdftotext -layout references/standards/kyber-specification-round3-20210804.pdf - | rg ...`
- Per-page `pdftotext` extraction for FIPS 203 algorithm/page anchors.
- `sha256sum references/standards/NIST.FIPS.203.pdf references/standards/nist.fips.202.pdf references/standards/nist.sp.800-185.pdf references/standards/kyber-specification-round3-20210804.pdf`
- `apply_patch`

Verified:

- M0 is now documented as the first roadmap milestone in the active milestone
  documents.
- `docs/00_project_spec/m0_plan.md` defines M0.1 through M0.5 gates.
- `docs/01_standard/source_provenance.md` classifies local standards, the Kyber
  Round-3 specification, the Kyber 2020 C package, and local Kyber KATs.
- `docs/00_project_spec/fips203_algorithm_tracking.md` contains the initial
  required tracking rows for FIPS 203 conversion/compression, sampling,
  NTT/INTT, K-PKE, ML-KEM internal algorithms, and hash/XOF dependencies.
- `references/SHA256SUMS` records SHA-256 hashes for all local standard PDFs.
- No RTL, testbench, simulation script, imported Kyber C source, Python model,
  comparison tool, or KAT workspace file was intentionally modified.

Remains to do:

- Run final M0.1 validation commands:
  `git diff --check`, `git status --short`, and
  `sha256sum -c references/SHA256SUMS`.
- Continue with M0.2 FIPS 203 algorithm tracking after M0.1 is accepted.
- Obtain or import final NIST CAVP/ACVP ML-KEM vectors in a later M0 task.

## Next Session Start Here

1. Read `AGENTS.md`.
2. Confirm branch `test` and cleanly separate the existing staged `AGENTS.md`
   symlink from M0.1 documentation changes.
3. Review:
   - `docs/00_project_spec/m0_plan.md`
   - `docs/00_project_spec/fips203_algorithm_tracking.md`
   - `docs/01_standard/source_provenance.md`
   - `reports/m0_source_audit.md`
   - `references/SHA256SUMS`
4. Run:
   - `git diff --check`
   - `sha256sum -c references/SHA256SUMS`
5. If M0.1 is accepted, continue to M0.2 and refine FIPS 203 algorithm
   tracking without modifying RTL.

### 2026-07-12 M0.2 Detailed FIPS 203 Algorithm Tracking

Requested:

- Implement M0.2 only: complete detailed FIPS 203 algorithm tracking.
- Extract FIPS algorithm numbers, inputs, outputs, dependencies, ML-KEM-768
  parameters, verification requirements, legacy C candidate mappings, and
  unresolved FIPS-vs-Kyber differences.
- Update `TODO.md`, `milestone_status.md`, and the relevant M0 report.
- Do not modify RTL, TB, sim, C source, Python model, KATs, or comparison
  tools. Do not start M0.3.

Files changed:

- `TODO.md`
- `docs/00_project_spec/fips203_algorithm_tracking.md`
- `docs/00_project_spec/milestone_status.md`
- `reports/m0_source_audit.md`

Commands run:

- `pwd`
- `git branch --show-current`
- `git status --short`
- `git worktree list`
- `sed -n ... AGENTS.md TODO.md docs/00_project_spec/fips203_algorithm_tracking.md`
- `sed -n ... docs/00_project_spec/milestone_status.md reports/m0_source_audit.md`
- `pdftotext -layout -f 27 -l 48 references/standards/NIST.FIPS.203.pdf -`
- `pdftotext -layout references/standards/NIST.FIPS.203.pdf - | rg ...`
- Per-page `pdftotext` extraction for FIPS 203 algorithm and Appendix C page
  anchors.
- `rg -n ... ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/.../kyber768`
- `apply_patch`
- `git diff --check`
- `git status --short`
- `git diff --stat`
- `git status --short -- rtl tb sim ref_model/c_ref ref_model/python_model ref_model/kat ref_model/compare reports/simulation`

Verified:

- Current branch is `test`.
- `git diff --check` passed.
- Changed-path scope is limited to the four approved documentation files.
- M0.2 tracking file records the required FIPS 203 algorithms and dependency
  functions with source anchors, interfaces, ML-KEM-768 parameters, legacy C
  candidate mappings, planned RTL milestone, verification requirements, status,
  and unresolved differences.
- Local Kyber 2020 KEM top-level functions remain classified as legacy
  candidates only and not as FIPS 203-equivalent oracles.
- No implementation directories were intentionally modified.

Remains to do:

- Begin M0.3 C/KAT harness only after explicit approval.
- Obtain final NIST CAVP/ACVP ML-KEM vectors in a later M0 task.

## Next Session Start Here

1. Read `AGENTS.md` and `TODO.md`.
2. Inspect `docs/00_project_spec/fips203_algorithm_tracking.md`.
3. If approved, start M0.3 by designing a generated-output location under
   `ref_model/c_ref/build/` without writing into the imported Kyber package.
4. Do not modify RTL before M1 architecture decisions are explicitly reopened.

### 2026-07-12 M0.3 Legacy Kyber768 C/KAT Harness

Requested:

- Implement M0.3 only: build and run the local Kyber768 2020 reference
  implementation without modifying the imported source tree.
- Use ignored `ref_model/c_ref/build/` or a temporary directory for generated
  files.
- Reproduce `PQCgenKAT_kem` output and compare exactly against the local
  `KAT/kyber768/PQCkemKAT_2400.rsp`.
- Add a strict `.req/.rsp` parser under `ref_model/kat/`.
- Parse all 100 Kyber768 cases and validate `count`, `seed`, `pk`, `sk`, `ct`,
  and `ss`.
- Create a provenance manifest labeling vectors as legacy Kyber 2020, not final
  FIPS 203 ML-KEM vectors.
- Add reproducible scripts and an M0.3 report.
- Do not modify RTL, TB, sim, Python model, comparison tools, or `PQC_main`.

Files changed:

- `.gitignore`
- `TODO.md`
- `docs/00_project_spec/m0_plan.md`
- `docs/00_project_spec/milestone_status.md`
- `ref_model/c_ref/run_kyber768_kat.sh`
- `ref_model/kat/parse_legacy_kyber_kat.py`
- `ref_model/kat/kyber768_legacy_provenance.md`
- `reports/m0_3_c_kat_harness.md`

Commands run:

- `pwd`
- `git branch --show-current`
- `git status --short`
- `git worktree list`
- `git log --oneline --decorate -5`
- `sed -n ... AGENTS.md TODO.md docs/00_project_spec/m0_plan.md docs/00_project_spec/milestone_status.md`
- `find ref_model ...`
- `sed -n ... .gitignore Makefile PQCgenKAT_kem.c`
- `sha256sum .../KAT/kyber768/PQCkemKAT_2400.req .../PQCkemKAT_2400.rsp`
- `chmod +x ref_model/c_ref/run_kyber768_kat.sh ref_model/kat/parse_legacy_kyber_kat.py`
- `bash ref_model/c_ref/run_kyber768_kat.sh`
- `python3 ref_model/kat/parse_legacy_kyber_kat.py --expect kyber768-2020 --req ... --rsp ...`
- `git status --short -- ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001`
- `git diff -- ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001`
- `apply_patch`

Verified:

- The Kyber768 reference implementation was copied to
  `ref_model/c_ref/build/kyber768_ref/`, built, and run there.
- Generated `PQCkemKAT_2400.req` exactly matches the local legacy request file.
- Generated `PQCkemKAT_2400.rsp` exactly matches the local legacy response file.
- Strict parser validated 100 request records and 100 response records.
- Parser validated sequential `count`, matching request/response `seed`, and
  required byte lengths for `seed`, `pk`, `sk`, `ct`, and `ss`.
- Imported Kyber source tree status/diff checks produced no output.

Remains to do:

- Start M0.4 only after explicit approval.
- Final NIST CAVP/ACVP ML-KEM vectors remain missing locally.

## Next Session Start Here

1. Read `AGENTS.md`, `TODO.md`, and `reports/m0_3_c_kat_harness.md`.
2. Confirm M0.3 generated files remain under ignored `ref_model/c_ref/build/`.
3. Do not treat legacy Kyber 2020 KATs as FIPS 203 ML-KEM validation vectors.
4. If approved, start M0.4 independent Python ML-KEM-768 golden model from
   FIPS 203 tracking, not from blind C translation.

### 2026-07-12 M0.4a Python Golden Model Foundations

Requested:

- Implement M0.4a only: independent Python foundations for ML-KEM-768.
- Implement parameters, modular arithmetic helpers, codec/compression, NTT,
  inverse NTT, `MultiplyNTTs`, `SampleNTT`, `SamplePolyCBD`, and hashlib-based
  SHA3/SHAKE wrappers.
- Add deterministic self-tests and unit tests.
- Cross-check against legacy C only where equivalence is already documented as
  approved.
- Do not implement K-PKE, full ML-KEM, M0.5, RTL, TB, sim, imported C changes,
  or `PQC_main` changes.

Files changed:

- `TODO.md`
- `docs/00_project_spec/m0_plan.md`
- `docs/00_project_spec/milestone_status.md`
- `ref_model/python_model/__init__.py`
- `ref_model/python_model/params.py`
- `ref_model/python_model/mod_arith.py`
- `ref_model/python_model/symmetric.py`
- `ref_model/python_model/codec.py`
- `ref_model/python_model/ntt.py`
- `ref_model/python_model/sampling.py`
- `ref_model/python_model/selftest.py`
- `ref_model/python_model/test_foundations.py`
- `reports/m0_4a_python_foundations.md`

Commands run:

- `pwd`
- `git branch --show-current`
- `git status --short`
- `git worktree list`
- `git log --oneline --decorate -5`
- `sed -n ... AGENTS.md TODO.md docs/00_project_spec/m0_plan.md docs/00_project_spec/milestone_status.md docs/00_project_spec/fips203_algorithm_tracking.md`
- `find ref_model/python_model ...`
- `pdftotext -layout -f 27 -l 36 references/standards/NIST.FIPS.203.pdf -`
- `python3 -m py_compile ref_model/python_model/*.py`
- `python3 -m ref_model.python_model.selftest`
- `python3 -m unittest discover -s ref_model/python_model -p 'test*.py'`
- `git diff --check`
- `git status --short`
- `git diff --stat`
- `git status --short -- rtl tb sim ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001 ref_model/compare reports/simulation`
- `git -C /home/hien/Projects/PQC_main status --short`
- `apply_patch`

Verified:

- Python compile check passed.
- Deterministic selftests passed.
- Unit tests passed: 8 tests.
- `git diff --check` passed.
- No RTL, TB, sim, imported C source, comparison-tool, reports/simulation, or
  `PQC_main` changes were reported.
- No legacy C/Python differential result was claimed because the relevant local
  C mappings remain documented as `legacy-candidate` and unresolved.

Remains to do:

- K-PKE and full ML-KEM remain unimplemented.
- Final NIST CAVP/ACVP ML-KEM vectors remain missing locally.
- M0.5 comparison tooling has not started.

## Next Session Start Here

1. Read `AGENTS.md`, `TODO.md`, and `reports/m0_4a_python_foundations.md`.
2. Treat `ref_model/python_model/` as FIPS-derived Python foundations only.
3. Do not claim FIPS validation until final CAVP/ACVP vectors are imported and
   passed.
4. If approved, continue M0.4 with K-PKE/full ML-KEM Python modeling; do not
   start M0.5 yet.

### 2026-07-12 M0.4b Complete Python ML-KEM-768 Golden Model

Requested:

- Implement M0.4b only: complete independent Python ML-KEM-768 golden model.
- Implement FIPS 203 matrix generation/transposition, PRF/XOF/CBD orchestration,
  K-PKE keygen/encrypt/decrypt, deterministic ML-KEM internal algorithms, and
  implicit rejection.
- Keep deterministic APIs accepting explicit `d`, `z`, `m`, and randomness.
- Follow FIPS byte layouts/input checks and avoid legacy `kem.c` behavior where
  it differs from FIPS 203.
- Add unit tests and deterministic roundtrip tests, including modified
  ciphertext fallback selection.
- Do not modify RTL, TB, sim, imported C source, or `PQC_main`.
- Do not claim KAT verification because final CAVP vectors are not present.
- Do not start M0.5.

Files changed:

- `TODO.md`
- `docs/00_project_spec/m0_plan.md`
- `docs/00_project_spec/milestone_status.md`
- `ref_model/python_model/params.py`
- `ref_model/python_model/kpke.py`
- `ref_model/python_model/mlkem.py`
- `ref_model/python_model/selftest.py`
- `ref_model/python_model/test_foundations.py`
- `reports/m0_4b_python_mlkem_model.md`

Commands run:

- `pwd`
- `git branch --show-current`
- `git status --short`
- `git worktree list`
- `git log --oneline --decorate -5`
- `sed -n ... AGENTS.md TODO.md docs/00_project_spec/m0_plan.md docs/00_project_spec/milestone_status.md reports/m0_4a_python_foundations.md`
- `find ref_model/python_model -maxdepth 2 -type f`
- `sed -n ... ref_model/python_model/*.py`
- `python3 -m py_compile ref_model/python_model/*.py`
- `python3 -m ref_model.python_model.selftest`
- `python3 -m unittest discover -s ref_model/python_model -p 'test*.py'`
- `git diff --check`
- `git status --short`
- `git diff --stat`
- `git status --short -- rtl tb sim ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001 ref_model/compare reports/simulation`
- `git -C /home/hien/Projects/PQC_main status --short`
- `apply_patch`

Verified:

- Python compile check passed.
- Deterministic Python selftest passed.
- Unit tests passed: 13 tests.
- Successful encapsulation/decapsulation agreement is tested.
- Modified ciphertext fallback selection to `J(z || c)` is tested.
- `git diff --check` passed.
- No RTL, TB, sim, imported C source, comparison-tool, reports/simulation, or
  `PQC_main` changes were reported.
- No final KAT/CAVP verification is claimed.

Remains to do:

- M0.5 comparison tooling has not started.
- Final NIST CAVP/ACVP ML-KEM vectors remain missing locally.

## Next Session Start Here

1. Read `AGENTS.md`, `TODO.md`, and `reports/m0_4b_python_mlkem_model.md`.
2. Treat `ref_model/python_model/` as the current independent Python internal
   ML-KEM-768 model, not final CAVP/KAT-validated evidence.
3. Do not modify RTL until M1 architecture decisions are explicitly reopened.
4. If approved, start M0.5 comparison tooling and final M0 report.

### 2026-07-13 M0.5 Comparison Tools and M0 Closure

Requested:

- Implement M0.5 only: one deterministic shared vector schema, reproducible
  ML-KEM-768 exports, strict first-mismatch comparison, tests, reports, and M0
  closure without modifying RTL, TB, sim, imported C, or `PQC_main`.
- Keep bulk vectors ignored, track only a curated smoke set, and retain final
  NIST CAVP/ACVP verification as explicitly pending.

Files changed:

- `.gitignore`
- `TODO.md`
- `docs/00_project_spec/m0_plan.md`
- `docs/00_project_spec/milestone_status.md`
- `docs/04_verification/verification_plan.md`
- `docs/04_verification/test_vector_plan.md`
- `docs/04_verification/regression_plan.md`
- `ref_model/README.md`
- `ref_model/compare/__init__.py`
- `ref_model/compare/vector_schema.py`
- `ref_model/compare/generate_vectors.py`
- `ref_model/compare/compare_vectors.py`
- `ref_model/compare/test_compare_tools.py`
- `ref_model/compare/vectors/mlkem768_smoke.json`
- `reports/m0_5_comparison_tools.md`
- `reports/m0_completion_report.md`

Commands run:

- `pwd`
- `git branch --show-current`
- `git status --short`
- `git worktree list`
- `git log --oneline --decorate -5`
- `sed -n ... AGENTS.md TODO.md` and M0/model/verification documents
- `find ref_model ...` and `find reports ...`
- `python3 -m py_compile ref_model/python_model/*.py ref_model/compare/*.py`
- `python3 -m unittest discover -s ref_model -p 'test*.py'`
- `python3 -m ref_model.python_model.selftest`
- `python3 -m ref_model.compare.generate_vectors --output ref_model/compare/generated/mlkem768_smoke.json`
- `python3 -m ref_model.compare.compare_vectors ref_model/compare/vectors/mlkem768_smoke.json ref_model/compare/generated/mlkem768_smoke.json`
- `git diff --check`
- restricted `git status`/`git diff` checks for prohibited project paths
- `git -C /home/hien/Projects/PQC_main status --short`
- `git diff --stat`

Verified:

- Python compilation passed.
- All 18 discovered Python model/comparison tests passed.
- Deterministic Python model self-test passed.
- Regenerated smoke vectors matched the curated set exactly.
- Schema tests cover export/reload, malformed document rejection, duplicate or
  extra structural data rejection, reproducibility, and exact mismatch paths.
- Restricted project paths and the read-only `PQC_main` baseline showed no
  changes; `git diff --check` passed.
- M0.1 through M0.5 are complete without an RTL validation claim.

Remains to do:

- Obtain authoritative final NIST CAVP/ACVP ML-KEM vectors, record provenance
  and hashes, and validate the Python model; this is still pending.
- Do not start M1 or modify RTL until explicitly approved and architecture
  decisions are locked.

## Next Session Start Here

1. Read `AGENTS.md`, `TODO.md`, and `reports/m0_completion_report.md`.
2. Treat `mlkem-vector-v1` as the shared Python/future-RTL vector contract.
3. Do not claim CAVP/ACVP validation; authoritative final vectors are absent.
4. Await explicit approval before beginning M1 architecture work.

### 2026-07-13 M1 Architecture Freeze v0.1 Documentation

Requested:

- Freeze approved interface, representation/domain, reset/control, synchronous
  memory, pipeline metadata, and one-butterfly NTT/INTT architecture contracts.
- Prove the two-source/two-destination-bank schedule conflict-free, map Python
  vectors to future RTL, define assertions, and rerun the stale `poly_sub` test.
- Do not modify RTL, TB, sim scripts, reference models, or start M2.

Files changed:

- `TODO.md`
- `docs/00_project_spec/m1_plan.md`
- `docs/00_project_spec/milestone_status.md`
- `docs/03_architecture/README.md`
- `docs/03_architecture/interface_contract.md`
- `docs/03_architecture/representation_domain_contract.md`
- `docs/03_architecture/reset_control_contract.md`
- `docs/03_architecture/pipeline_contract.md`
- `docs/03_architecture/memory_architecture.md`
- `docs/03_architecture/ntt_architecture.md`
- `docs/03_architecture/top_architecture.md`
- `docs/04_verification/verification_plan.md`
- `docs/04_verification/regression_plan.md`
- `docs/04_verification/m1_architecture_verification_plan.md`
- `reports/simulation/poly_sub_report.md`
- `reports/m1_architecture_freeze_v0_1.md`

Commands run:

- Repository startup/status and documentation/RTL audit commands required by
  `AGENTS.md`.
- `bash sim/scripts/run_poly_sub.sh`
- `git diff --check`
- restricted Git status/diff checks for RTL, TB, sim scripts, reference models,
  and the read-only `PQC_main` worktree.

Verified:

- `poly_sub` passed `pass_count=1024 fail_count=0`; its stale report is resolved.
- The bank proof covers all seven NTT and seven INTT stages using
  `bank=i[p] xor i[r]`, `addr=remove_bit(i,r)` transitions.
- M1 documentation records cycle/bandwidth tables, vector mapping, protocol and
  collision assertions, and completion-after-final-write semantics.
- No RTL, TB, sim script, reference-model, or `PQC_main` file was modified.

Remains to do:

- Do not start M2 until explicitly approved.
- Implement and exhaustively verify the frozen contracts in later milestones.
- Final NIST CAVP/ACVP vector validation remains pending.

## Next Session Start Here

1. Read `AGENTS.md`, `TODO.md`, `docs/00_project_spec/m1_plan.md`, and
   `reports/m1_architecture_freeze_v0_1.md`.
2. Treat M1 contracts as governing future RTL; existing RTL remains baseline-only.
3. Await explicit M2 approval; do not modify RTL beforehand.

### 2026-07-13 M2.1 Synchronous Memory and Pipeline Primitives

Requested:

- Implement only generic synchronous 1R/1W RAM, conflict-free NTT ping-pong
  banks/mapping, fixed-latency metadata delay, and one valid/ready register slice.
- Verify memory latency/reset/collision, all NTT stage maps, role swaps,
  metadata alignment, backpressure, and adjacent regressions.

Files changed:

- Added `rtl/memory/sync_1r1w_ram.v`, `ntt_bank_map.v`, and
  `ntt_pingpong_banks.v`.
- Added `rtl/control/fixed_latency_delay.v` and `rv_register_slice.v`.
- Added four unit testbenches and five simulation scripts for M2.1.
- Added `docs/00_project_spec/m2_plan.md` and
  `reports/simulation/m2_1_primitives_report.md`.
- Updated `TODO.md`, milestone status, RTL README, and M1 architecture contracts
  with the implemented M2.1 boundary.

Commands run:

- `bash sim/scripts/run_m2_1_primitives.sh`
- `bash sim/scripts/run_ntt_core.sh`
- `bash sim/scripts/run_intt_core.sh`
- `bash sim/scripts/run_ntt_intt_roundtrip.sh`
- `bash sim/scripts/run_poly_add.sh`
- `bash sim/scripts/run_poly_sub.sh`
- `bash sim/scripts/run_poly_basemul_montgomery.sh`
- `git diff --check` and restricted-path/reference-baseline checks.

Verified:

- RAM: 515/0 PASS; expected collision assertion PASS.
- Bank mapping/ping-pong: 4866/0 PASS over all coefficients/stages and swaps.
- Pipeline/control: 35/0 PASS including latency, metadata, reset, and stall checks.
- Adjacent NTT/INTT/roundtrip/poly regressions all PASS with zero failures.
- Memory contents and payload registers are not reset; only valid/control state is.
- No arithmetic, NTT controller, model, or M2.2 work was added.

Remains to do:

- Do not start M2.2 without explicit approval.
- No synthesis/Fmax claim exists; later implementation must measure timing.
- Final NIST CAVP/ACVP validation remains pending.

## Next Session Start Here

1. Read `AGENTS.md`, `TODO.md`, `docs/00_project_spec/m2_plan.md`, and the M2.1 report.
2. Preserve legacy RTL while integrating M1-compliant primitives incrementally.
3. Await explicit approval and a module contract before M2.2.
