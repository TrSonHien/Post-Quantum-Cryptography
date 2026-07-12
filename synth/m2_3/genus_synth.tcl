# Cadence Genus Synthesis Script for ML-KEM Arithmetic Candidates
# Reproducible script to run genus in non-interactive batch mode.

if {![info exists env(SYNTH_TOP)]} {
    puts "ERROR: SYNTH_TOP environment variable not set."
    exit 1
}
set top_name $env(SYNTH_TOP)

if {![info exists env(LIB_FILE)]} {
    puts "ERROR: LIB_FILE environment variable not set."
    exit 1
}
set lib_file $env(LIB_FILE)

if {![info exists env(HDL_FILES)]} {
    puts "ERROR: HDL_FILES environment variable not set."
    exit 1
}
set hdl_files $env(HDL_FILES)

set sdc_file "constraints.sdc"
if {[info exists env(SDC_FILE)]} {
    set sdc_file $env(SDC_FILE)
}

# Step 1: Set library and search paths
set_db library $lib_file
set_db init_hdl_search_path {../../rtl/common ../../rtl/arithmetic ../../rtl/ntt ../../rtl/control wrappers}

# Step 2: Read HDL source files
read_hdl -language sv $hdl_files

# Step 3: Elaborate design
elaborate $top_name

# Step 4: Apply constraints
read_sdc $sdc_file

# Step 5: Synthesize design to generic gates, then map to technology library
syn_generic
syn_map

# Step 6: Generate reports
report_timing > reports/${top_name}_timing.rpt
report_area   > reports/${top_name}_area.rpt
report_gates  > reports/${top_name}_gates.rpt

exit 0
