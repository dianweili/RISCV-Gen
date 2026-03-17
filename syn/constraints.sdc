# constraints.sdc — Timing constraints for RISC-V processor
# Target: 800 MHz (1.25 ns period) @ ASAP7 7nm, 0.75V

# Clock definition
create_clock -name clk -period 1.25 [get_ports clk]

# Input delays (20% of clock period)
set_input_delay -clock clk -max 0.25 [all_inputs]
set_input_delay -clock clk -min 0.0  [all_inputs]

# Output delays (20% of clock period)
set_output_delay -clock clk -max 0.25 [all_outputs]
set_output_delay -clock clk -min 0.0  [all_outputs]

# Clock uncertainty (jitter + skew)
set_clock_uncertainty -setup 0.05 [get_clocks clk]
set_clock_uncertainty -hold  0.02 [get_clocks clk]

# Clock transition
set_clock_transition 0.05 [get_clocks clk]

# Input/output transition
set_input_transition 0.1 [all_inputs]

# Load capacitance (typical for 7nm)
set_load 0.01 [all_outputs]

# False paths (if any)
# set_false_path -from [get_ports rst_n] -to [all_registers]

# Multi-cycle paths (if any)
# Example: CSR operations might take 2 cycles
# set_multicycle_path -setup 2 -from [get_pins csr_*] -to [get_pins *]

# Max fanout
set_max_fanout 16 [current_design]

# Max transition
set_max_transition 0.2 [current_design]

# Operating conditions
# set_operating_conditions -max typical -min typical
