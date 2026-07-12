# Synopsys Design Constraints (SDC) for ML-KEM Arithmetic Pipelines
# Target clock period is swept during timing search. Default is set to 2.0ns (500 MHz).

if {![info exists sdc_clk_period]} {
    set sdc_clk_period 2.0
}

create_clock -name clk -period $sdc_clk_period [get_ports clk]

# Clock uncertainty to model jitter and skew
set_clock_uncertainty 0.1 [get_clocks clk]

# Input / Output constraints representing typical design boundaries (30% of period)
set input_delay_val  [expr $sdc_clk_period * 0.3]
set output_delay_val [expr $sdc_clk_period * 0.3]

set all_inputs_except_clk [remove_from_collection [all_inputs] [get_ports clk]]
set_input_delay -clock clk -max $input_delay_val $all_inputs_except_clk
set_output_delay -clock clk -max $output_delay_val [all_outputs]

# Design Rules
set_max_fanout 20 [current_design]
set_max_transition 0.2 [current_design]
