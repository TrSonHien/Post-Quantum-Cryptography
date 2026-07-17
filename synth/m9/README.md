# M9 synthesis collateral

`rtl.f` is the complete synthesizable source list for `mlkem768_top`; it
contains no testbench files and assumes `rtl/common/kyber_params.vh` is found
through the include path. `constraints.sdc` is an exploratory 20 ns clock
constraint, not an ML-KEM performance target.

`run_yosys.sh` records a generic hierarchy/resource baseline when Yosys is
installed. It cannot establish ASIC area, WNS/TNS, or Fmax without a target
cell library. `run_genus.sh` requires a licensed Genus executable and
`LIB_FILE=/path/to/stdcell.lib`; it then applies the same complete hierarchy
and exploratory SDC. Generated logs, reports, mapped netlists, and databases
are intentionally not release artifacts.
