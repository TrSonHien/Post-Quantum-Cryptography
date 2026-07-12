# Yosys Synthesis Script for ML-KEM Arithmetic Candidates
# Reproducible script to run yosys in non-interactive batch mode.

yosys -import

# Read design HDL
set hdl_files [split $env(HDL_FILES) " "]
foreach f $hdl_files {
    if {[string match "*.vh" $f]} {
        # Skip header files
    } else {
        read_verilog -sv -I../../rtl/common -I../../rtl/arithmetic -I../../rtl/ntt -I../../rtl/control -Iwrappers $f
    }
}

# Elaborate design top
hierarchy -top $env(SYNTH_TOP)

# Generic synthesis pass
synth -top $env(SYNTH_TOP)

# Map technology library if LIB_FILE is provided
if {[info exists env(LIB_FILE)] && $env(LIB_FILE) != ""} {
    dfflibmap -liberty $env(LIB_FILE)
    abc -liberty $env(LIB_FILE)
}

# Report area and cell statistics
stat

# Report timing estimates (Yosys internal static timing analysis)
ltp

write_verilog -noattr reports/$env(SYNTH_TOP)_synthesized.v
