# synth.tcl — Yosys synthesis script for RISC-V RV32I processor
# Target: ASAP7 7nm PDK

yosys -import

# Read SystemVerilog source files
read_verilog -sv rtl/pkg/riscv_pkg.sv
read_verilog -sv rtl/pkg/pipeline_pkg.sv
read_verilog -sv rtl/units/alu.sv
read_verilog -sv rtl/units/branch_comp.sv
read_verilog -sv rtl/units/regfile.sv
read_verilog -sv rtl/units/forward_unit.sv
read_verilog -sv rtl/units/hazard_unit.sv
read_verilog -sv rtl/units/csr_regfile.sv
read_verilog -sv rtl/core/if_stage.sv
read_verilog -sv rtl/core/id_stage.sv
read_verilog -sv rtl/core/ex_stage.sv
read_verilog -sv rtl/core/mem_stage.sv
read_verilog -sv rtl/core/wb_stage.sv
read_verilog -sv rtl/core/riscv_top.sv

# Hierarchy check
hierarchy -check -top riscv_top

# High-level synthesis
synth -top riscv_top -flatten

# Map to ASAP7 standard cells
# Note: Set ASAP7_LIBERTY environment variable to point to liberty file
if {[info exists env(ASAP7_LIBERTY)]} {
    dfflibmap -liberty $env(ASAP7_LIBERTY)
    abc -liberty $env(ASAP7_LIBERTY) -constr syn/constraints.sdc
} else {
    puts "Warning: ASAP7_LIBERTY not set, using generic mapping"
    dfflibmap
    abc -constr syn/constraints.sdc
}

# Clean up
clean

# Statistics
stat

# Write synthesized netlist
write_verilog -noattr syn/riscv_top_synth.v

# Write JSON for OpenLane
write_json syn/riscv_top_synth.json

puts "Synthesis complete!"
puts "Output: syn/riscv_top_synth.v"
