#!/usr/bin/env bash
# ==============================================================================
# ML-KEM Arithmetic Synthesis Sweep Runner
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "=== ML-KEM Synthesis Timing Sweep Setup ==="

# Check for synthesis tools in PATH
GENUS_CMD=$(which genus 2>/dev/null || echo "")
YOSYS_CMD=$(which yosys 2>/dev/null || echo "")
TOOL_AVAILABLE=""

if [ -n "${GENUS_CMD}" ]; then
    TOOL_AVAILABLE="genus"
    echo "Found Cadence Genus: ${GENUS_CMD}"
elif [ -n "${YOSYS_CMD}" ]; then
    TOOL_AVAILABLE="yosys"
    echo "Found Yosys: ${YOSYS_CMD}"
else
    echo "======================================================================="
    echo "BLOCKER: No ASIC synthesis tools (Cadence Genus or Yosys) found in PATH."
    echo "BLOCKER: No commercial/open-source standard cell Liberty (.lib) PDK"
    echo "         file was found configured."
    echo "======================================================================="
    echo "The reproducible synthesis infrastructure has been fully created in:"
    echo "  - wrappers: ${SCRIPT_DIR}/wrappers/"
    echo "  - constraints: ${SCRIPT_DIR}/constraints.sdc"
    echo "  - Genus script: ${SCRIPT_DIR}/genus_synth.tcl"
    echo "  - Yosys script: ${SCRIPT_DIR}/yosys_synth.tcl"
    echo ""
    echo "To run this sweep once tools are configured, execute:"
    echo "  export LIB_FILE=/path/to/your/stdcell.lib"
    echo "  ./run_synth_sweep.sh"
    exit 0
fi

# If we get here, a tool is available. We assume the user has exported LIB_FILE.
LIB_FILE="${LIB_FILE:-}"
if [ -z "${LIB_FILE}" ]; then
    echo "ERROR: Please export LIB_FILE to point to a valid Liberty (.lib) library."
    exit 1
fi

mkdir -p "${SCRIPT_DIR}/reports"

# Candidate HDL definition list
# Format: TOP_NAME|HDL_FILES
CANDIDATES=(
    "mod_add_wrap|mod_add.v wrappers/mod_add_wrap.v"
    "mod_add_pipe|mod_add_pipe.v"
    "mod_sub_wrap|mod_sub.v wrappers/mod_sub_wrap.v"
    "mod_sub_pipe|mod_sub_pipe.v"
    "montgomery_reduce_wrap|reduction.v wrappers/montgomery_reduce_wrap.v"
    "montgomery_reduce_pipe|montgomery_reduce_pipe.v"
    "mod_mul_wrap|reduction.v mod_mul.v wrappers/mod_mul_wrap.v"
    "mod_mul_pipe|montgomery_reduce_pipe.v mod_mul_pipe.v"
    "barrett_reduce_wrap|reduction.v wrappers/barrett_reduce_wrap.v"
    "barrett_reduce_pipe|barrett_reduce_pipe.v"
    "butterfly_unit_wrap|reduction.v mod_mul.v mod_add.v mod_sub.v butterfly_unit.v wrappers/butterfly_unit_wrap.v"
    "butterfly_pipe|fixed_latency_delay.v montgomery_reduce_pipe.v mod_mul_pipe.v mod_add_pipe.v mod_sub_pipe.v butterfly_pipe.v"
    "intt_butterfly_unit_wrap|reduction.v mod_mul.v mod_add.v mod_sub.v intt_butterfly_unit.v wrappers/intt_butterfly_unit_wrap.v"
    "intt_butterfly_pipe|fixed_latency_delay.v montgomery_reduce_pipe.v mod_mul_pipe.v mod_add_pipe.v mod_sub_pipe.v intt_butterfly_pipe.v"
)

PERIOD_SWEEP=(5.0 4.0 3.0 2.0 1.5 1.2 1.0 0.8)

echo "Starting synthesis timing sweep on candidates..."
for cand in "${CANDIDATES[@]}"; do
    IFS='|' read -r top hdls <<< "${cand}"
    echo "--------------------------------------------------"
    echo "Candidate: ${top}"
    echo "--------------------------------------------------"
    
    # Resolve full paths for HDL files
    RESOLVED_HDLS=""
    for hdl in ${hdls}; do
        if [ -f "${SCRIPT_DIR}/wrappers/${hdl}" ]; then
            RESOLVED_HDLS="${RESOLVED_HDLS} wrappers/${hdl}"
        elif [ -f "${ROOT_DIR}/rtl/arithmetic/${hdl}" ]; then
            RESOLVED_HDLS="${RESOLVED_HDLS} ${ROOT_DIR}/rtl/arithmetic/${hdl}"
        elif [ -f "${ROOT_DIR}/rtl/ntt/${hdl}" ]; then
            RESOLVED_HDLS="${RESOLVED_HDLS} ${ROOT_DIR}/rtl/ntt/${hdl}"
        elif [ -f "${ROOT_DIR}/rtl/control/${hdl}" ]; then
            RESOLVED_HDLS="${RESOLVED_HDLS} ${ROOT_DIR}/rtl/control/${hdl}"
        else
            echo "ERROR: HDL file ${hdl} not found!"
            exit 1
        fi
    done

    best_period="N/A"
    for period in "${PERIOD_SWEEP[@]}"; do
        echo "  Testing clock period: ${period}ns..."
        
        # Setup run environment
        export SYNTH_TOP="${top}"
        export LIB_FILE="${LIB_FILE}"
        export HDL_FILES="${RESOLVED_HDLS}"
        export SDC_FILE="${SCRIPT_DIR}/constraints.sdc"
        
        # Override period inside constraints.sdc parameter
        export sdc_clk_period="${period}"
        
        # Execute synthesis based on tool
        if [ "${TOOL_AVAILABLE}" = "genus" ]; then
            genus -files "${SCRIPT_DIR}/genus_synth.tcl" -log "${SCRIPT_DIR}/reports/${top}_${period}ns.log" >/dev/null 2>&1 || true
            # Parse WNS from Genus timing report
            timing_rpt="${SCRIPT_DIR}/reports/${top}_timing.rpt"
            if [ -f "${timing_rpt}" ]; then
                wns=$(grep "slack" "${timing_rpt}" | head -n 1 | awk '{print $3}')
                echo "    WNS: ${wns}ns"
                # If WNS >= 0, timing met
                if (( $(echo "${wns} >= 0.0" | bc -l) )); then
                    best_period="${period}"
                else
                    echo "    Timing violated at ${period}ns. Stopping sweep."
                    break
                fi
            fi
        else
            yosys -c "${SCRIPT_DIR}/yosys_synth.tcl" > "${SCRIPT_DIR}/reports/${top}_${period}ns.log" 2>&1 || true
            # Yosys output parse (mocking check or parsing abc results if timing is output)
            echo "    Yosys run completed."
        fi
    done
    echo "  Best passing clock period for ${top}: ${best_period}ns"
done
