# M2.3 ASIC Synthesis Comparison Report

## 1. Local vs Server Status

*   **Milestone M2.3a — Synthesis Infrastructure Preparation**: **COMPLETE**
*   **Milestone M2.3b — Server ASIC Synthesis Comparison & Candidate Selection**: **PENDING SERVER EXECUTION**
*   **Overall Milestone M2.3 Status**: **PARTIALLY COMPLETE**

*Note: Since no usable synthesis tool or PDK standard-cell library is present on the local workspace, **no synthesis timing data (Fmax, WNS, TNS), gate/cell area, or legacy-to-pipeline improvement ratios are currently available**. Complete reproducible synthesis scripts, wrappers, and constraints are prepared under [synth/m2_3/](file:///home/hien/Projects/Post_Quantum_Cryptography/synth/m2_3/) to be executed on a target server with licensed EDA tools.*

---

## 2. Pipelined Arithmetic Candidate Architecture & Provisional Selection Matrix

Below is the evaluation matrix detailing the comparison between the legacy combinational arithmetic blocks and the pipelined `v0` candidates.

| Candidate Class | Combinational Top | Pipelined Top | Target Modulus ($q$) | Legacy Stages ($L$/$II$) | Pipelined Stages ($L$/$II$) | Theoretical Bottleneck & Pipelining Benefit | Provisional Status |
| :--- | :--- | :--- | :---: | :---: | :---: | :--- | :--- |
| **Modular Addition** | `mod_add` | `mod_add_pipe` | 3329 | 0 / 1 | 1 / 1 | **Bottleneck**: 13-bit adder followed by a conditional 13-bit subtractor.<br>**Benefit**: Pipelining registers the output, isolating the logic path. | Provisional M3 candidate. Final selection requires server synthesis. |
| **Modular Subtraction** | `mod_sub` | `mod_sub_pipe` | 3329 | 0 / 1 | 1 / 1 | **Bottleneck**: 13-bit subtractor followed by a conditional 13-bit adder.<br>**Benefit**: Registers the output, preventing logic path propagation. | Provisional M3 candidate. Final selection requires server synthesis. |
| **Montgomery Reduction** | `montgomery_reduce` | `montgomery_reduce_pipe` | 3329 | 0 / 1 | 3 / 1 | **Bottleneck**: $16 \times 12$ constant multiplier and 32-bit adder.<br>**Benefit**: Breaks the multiplication and subsequent addition into 3 registered stages. | Provisional M3 candidate. Final selection requires server synthesis. |
| **Modular Multiplication** | `mod_mul` | `mod_mul_pipe` | 3329 | 0 / 1 | 4 / 1 | **Bottleneck**: $12 \times 12$ multiplier followed by Montgomery reduction.<br>**Benefit**: Stage 1 registers the $12 \times 12$ product, and Stages 2-4 run pipelined Montgomery reduction. | Provisional M3 candidate. Final selection requires server synthesis. |
| **Barrett Reduction** | `barrett_reduce` | `barrett_reduce_pipe` | 3329 | 0 / 1 | 3 / 1 | **Bottleneck**: Large $32 \times 37$ constant multiplier, followed by a $21 \times 12$ multiplier and subtraction.<br>**Benefit**: Isolates the large $32 \times 37$ multiplier (Stage 1) and subsequent subtractions (Stages 2-3). | Provisional M3 candidate. Final selection requires server synthesis. |
| **Forward NTT Butterfly** | `butterfly_unit` | `butterfly_pipe` | 3329 | 0 / 1 | 5 / 1 | **Bottleneck**: Sequential modular multiplication followed by parallel modular add/sub.<br>**Benefit**: Stages 1-4 execute pipelined multiplication (`mod_mul_pipe`), and Stage 5 performs add/sub. | Provisional M3 candidate. Final selection requires server synthesis. |
| **Inverse NTT Butterfly** | `intt_butterfly_unit` | `intt_butterfly_pipe` | 3329 | 0 / 1 | 5 / 1 | **Bottleneck**: Modular add/sub followed by modular multiplication.<br>**Benefit**: Stage 1 executes parallel add/sub, and Stages 2-5 perform pipelined multiplication. | Provisional M3 candidate. Final selection requires server synthesis. |

> [!IMPORTANT]
> The `*_pipe` modules are provisional M3 candidates. Final selection requires consistent server synthesis results using a real Liberty, PVT corner, SDC, and synthesis tool.

---

## 3. Server Handoff Checklist

This checklist provides target details for server synthesis run execution and comparison.

### 3.1 Synthesis Execution Setup
*   **Synthesis Tool & Version**: Cadence Genus (v19.1 or later) or Synopsys Design Compiler (vQ-2020.03 or later).
*   **Liberty Path & PVT Corner**: Real target foundry standard-cell library `.lib` (typically typical/worst-case corner, e.g., $125^\circ\text{C}$, $0.9\text{V}$).
*   **Clock Sweep Range**: $5.0\text{ns}$ down to $0.8\text{ns}$ ($200\text{ MHz}$ to $1.25\text{ GHz}$) in steps of $0.2\text{ns}$ to locate the minimum passing period (WNS $\ge 0.0\text{ns}$).
*   **SDC Path**: [synth/m2_3/constraints.sdc](file:///home/hien/Projects/Post_Quantum_Cryptography/synth/m2_3/constraints.sdc)
*   **Output Report Directory**: `synth/m2_3/reports/`

### 3.2 Modules and Top Names
*   **Wrappers for Combinational Legacy Modules**:
    *   `mod_add_wrap` wrapping `mod_add.v`
    *   `mod_sub_wrap` wrapping `mod_sub.v`
    *   `montgomery_reduce_wrap` wrapping `reduction.v` (module `montgomery_reduce`)
    *   `mod_mul_wrap` wrapping `mod_mul.v`
    *   `barrett_reduce_wrap` wrapping `reduction.v` (module `barrett_reduce`)
    *   `butterfly_unit_wrap` wrapping `butterfly_unit.v`
    *   `intt_butterfly_unit_wrap` wrapping `intt_butterfly_unit.v`
*   **Pipelined Sequential Modules (No wrappers required)**:
    *   `mod_add_pipe`
    *   `mod_sub_pipe`
    *   `montgomery_reduce_pipe`
    *   `mod_mul_pipe`
    *   `barrett_reduce_pipe`
    *   `butterfly_pipe`
    *   `intt_butterfly_pipe`

### 3.3 Running the Sweep
Navigate to `synth/m2_3/` and execute:
```bash
export LIB_FILE=/path/to/target_stdcell.lib
chmod +x run_synth_sweep.sh
./run_synth_sweep.sh
```

### 3.4 Required Data Fields & Comparison Format
For each candidate, parse the report to extract:
1.  **Clock Period & Estimated Fmax** (min period where WNS $\ge 0$)
2.  **WNS (Worst Negative Slack)** and **TNS (Total Negative Slack)**
3.  **Critical Path Details**: Startpoint, Endpoint, and Critical Path Logic Class
4.  **Cell Area & Gate Counts** (Combinational vs Sequential)
5.  **Latency & II**

Compile the parsed metrics into a table matching the following format for each class:
```text
| Candidate Top | Clock Period (ns) | Fmax (MHz) | WNS (ns) | Cell Area (um^2) | Seq/Comb Cell Count | Latency / II | Selection Status |
```

---

## 4. Physical Design Risks & Constraints

1.  **Metadata Delay Overheads**:
    Since metadata is external to the arithmetic leaf pipelines, the caller is responsible for implementing timing-matched shift registers (using `fixed_latency_delay`). For wide metadata channels, this will increase sequential cell count and routing density.
2.  **Payload Register Unreset Policy**:
    Leaving intermediate datapath registers without reset minimizes cell area and routing load. However, it requires careful control logic verification to ensure that invalid outputs are never sampled by downstream memory or address registers.
3.  **DSP / Multiplier Clustering**:
    The $12 \times 12$, $16 \times 12$, and $32 \times 37$ multipliers will require localized cell placement to prevent long routing paths from eating into the timing slack. Close placement constraints are recommended during physical design floorplanning.
