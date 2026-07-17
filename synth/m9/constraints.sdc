# Exploratory M9 full-top constraint only. It is not a project timing target.
create_clock -name clk -period 20.0 [get_ports clk]
set_clock_uncertainty 0.2 [get_clocks clk]
set_input_delay 2.0 -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay 2.0 -clock clk [all_outputs]
