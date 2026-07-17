# M9 mapped full-top baseline. Requires a licensed Genus installation and LIB_FILE.
if {![info exists env(LIB_FILE)] || $env(LIB_FILE) eq ""} {
    puts "ERROR: Set LIB_FILE to a target standard-cell Liberty file."
    exit 2
}
set root [file normalize "../.."]
set_db library $env(LIB_FILE)
set_db init_hdl_search_path [list "$root/rtl/common"]
set rtl_f [open "rtl.f" r]
set hdl_files {}
while {[gets $rtl_f line] >= 0} {
    if {$line ne ""} { lappend hdl_files "$root/$line" }
}
close $rtl_f
read_hdl -language sv $hdl_files
elaborate mlkem768_top
read_sdc constraints.sdc
check_design -unresolved
syn_generic
syn_map
report_area > reports/mlkem768_top_area.rpt
report_gates > reports/mlkem768_top_gates.rpt
report_timing > reports/mlkem768_top_timing.rpt
write_hdl > reports/mlkem768_top_mapped.v
exit
