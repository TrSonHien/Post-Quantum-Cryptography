# ML-KEM (Kyber) Hardware Exploration

A learning-oriented RTL design and physical design (ASIC) exploration repository focused on studying and prototyping hardware architectures for the NIST ML-KEM (Kyber) Key Encapsulation Mechanism.

---

## Current Status

> [!NOTE]
> This repository is in an early prototype and study phase. 
> The current files serve as structural scaffolding to test the verification and simulation setups. Cryptographic hardware primitives for ML-KEM are currently in the planning phase.

- **Simulation Toolchain**: Basic simulation filelists and Makefiles are configured locally to verify local compilation, linting, and toolchain configurations.
- **ASIC/Physical Design**: The `pd/` flow directory is initialized but empty. No synthesis or place-and-route scripts exist yet.
- **Reference Documents**: Large specification PDFs and reference material are treated as local-only references and are not tracked in the remote Git repository.

---

## Repository & Workspace Layout

The following layout describes how files are organized in the workspace, distinguishing between currently tracked files, planned files, and local-only reference directories.

### Currently Tracked / Staged
* [README.md](file:///home/hien/Projects/Post_Quantum_Cryptography/README.md) - Project documentation (this file)
* [thoughts.txt](file:///home/hien/Projects/Post_Quantum_Cryptography/thoughts.txt) - Initial design thoughts, target architectures, and hardware roadmaps

### Planned for Staging (Tracked in upcoming commits)
* `rtl/` - Simulation setup, test compilation filelists, and testbenches (`module_top.v`, `tb.v`, `sim/Makefile`)
* `.gitignore` - Git ignore configuration for EDA tool and simulator logs
* `AGENTS.md` - Context and guidelines for agentic development
* `.agents/` - Automation workflows (e.g., repository startup context)

### Local-Only (Untracked / Excluded from Git commits)
* `documents/` - Local directory for specifications and reference implementations
  * `kyber-specification-round3-20210804.pdf` (local copy of Kyber Round 3 spec)
  * `NIST-PQ-Submission-Kyber-20201001/` (local copy of Kyber NIST submission package)
* `images/` - Block diagrams and waveform screenshots
* `pd/` - Future physical design and synthesis run scripts

---

## Verification & Simulation Setup (Planned for Commit)

The simulation configuration inside the `rtl/` directory is designed to support the following tools:
* **Simulator**: ModelSim / QuestaSim (configured via `vsim`/`vlog`) for functional verification.
* **Linter**: Verilator for design rule checks (linting/DRC).

Targets are provided in the `rtl/sim/` Makefile to support compilation flow checks (`make build`), functional runs (`make run`), linting (`make drc`), and code coverage generation.

---

## Limitations
- **No cryptographic logic**: The repository does not currently contain active Kyber module implementations.
- **Out of Scope**: Dilithium / ML-DSA is not planned or supported in this repository; the focus is strictly on ML-KEM.
- **Not synthesizable/ASIC ready**: No constraints (SDC), timing analysis, or physical design scripts are set up.

---

## Roadmap

1. **Phase 1: Symmetric Engine Primitives**
   - Implement Keccak-f[1600] permutation engine (SHA-3, SHAKE-128, SHAKE-256) for matrix/vector generation and hashing in Kyber.
2. **Phase 2: Polynomial Primitives**
   - Design a configurable Butterfly Unit for Number Theoretic Transform (NTT) multiplication.
   - Implement Barrett/Montgomery modular reduction modules.
3. **Phase 3: Integration**
   - Integrate components into ML-KEM/Kyber (Keygen, Encapsulation, Decapsulation) state machines.
4. **Phase 4: ASIC Flow Setup**
   - Write SDC timing constraints.
   - Develop Cadence Genus synthesis and Innovus place-and-route scripts under `pd/`.

---

## References
* **NIST FIPS 203 (ML-KEM)**: [FIPS 203 Standard Document](https://csrc.nist.gov/pubs/fips/203/ipd)
* **Kyber Round 3 Specification**: Available in local `documents/` directory if downloaded, or online via [pq-crystals.org](https://pq-crystals.org/kyber/)
