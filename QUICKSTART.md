# Quick Start Guide

Get the RISC-V RV32I processor running in 5 minutes.

## Prerequisites Check

```bash
# Check Verilator
verilator --version  # Need 5.x+

# Check RISC-V toolchain
riscv32-unknown-elf-gcc --version

# Check Make
make --version
```

## Step 1: Run Unit Tests (30 seconds)

```bash
# Test ALU
make test_alu

# Test register file
make test_regfile

# Run all unit tests
make test_all
```

Expected output:
```
=== ALU Unit Test ===
ADD: 10 + 20 = 30
SUB: 50 - 20 = 30
...
=== All ALU tests passed ===
```

## Step 2: Build Top-Level Simulator (1 minute)

```bash
make test_top
```

This compiles the entire processor with Verilator.

## Step 3: Run Assembly Tests (2 minutes)

```bash
# Run all directed tests
make test_asm
```

This will:
1. Compile 5 assembly test programs
2. Run each on the processor simulator
3. Check for PASS/FAIL signatures

Expected output:
```
=== Running assembly tests ===

Running boot_test...
[PASS] Test passed at cycle 45

Running arith_test...
[PASS] Test passed at cycle 78
...
=== All assembly tests passed ===
```

## Step 4: View Waveforms (Optional)

```bash
# Run a single test with waveform dump
cd build/obj_top
./sim_top +hex=../boot_test.hex

# Open waveform
gtkwave ../../sim_riscv.vcd
```

## Step 5: Synthesize (Optional, 5 minutes)

```bash
# Requires Yosys and ASAP7 PDK
export ASAP7_LIBERTY=/path/to/asap7sc7p5t_SEQ_RVT.lib
make synth
```

## Troubleshooting

### "verilator: command not found"

Install Verilator:
```bash
# Ubuntu/Debian
sudo apt install verilator

# macOS
brew install verilator

# From source
git clone https://github.com/verilator/verilator
cd verilator && autoconf && ./configure && make && sudo make install
```

### "riscv32-unknown-elf-as: command not found"

Install RISC-V toolchain:
```bash
# Ubuntu/Debian
sudo apt install gcc-riscv64-unknown-elf

# macOS
brew tap riscv/riscv
brew install riscv-tools

# Or download prebuilt from:
# https://github.com/riscv-collab/riscv-gnu-toolchain/releases
```

### Compilation errors

Check SystemVerilog support:
```bash
verilator --version  # Must be 5.x or later
```

### Tests fail

1. Check register dump in log files:
   ```bash
   cat build/boot_test.log
   ```

2. Enable waveform and inspect:
   ```bash
   gtkwave sim_riscv.vcd
   ```

3. Check for timing issues (increase MAX_CYCLES in testbench)

## Next Steps

### Write Your Own Test

1. Create `verif/asm/my_test.S`:
```assembly
.section .text
.globl _start

_start:
    li x1, 42
    li x2, 0x100
    sw x1, 0(x2)

    # Write PASS
    li x3, 0xDEADBEEF
    sw x3, 0(x2)

loop:
    j loop
```

2. Compile and run:
```bash
cd verif/scripts
riscv32-unknown-elf-as -march=rv32i -o ../../build/my_test.o ../asm/my_test.S
riscv32-unknown-elf-ld -T linker.ld -o ../../build/my_test.elf ../../build/my_test.o
riscv32-unknown-elf-objcopy -O verilog ../../build/my_test.elf ../../build/my_test.hex
cd ../../build/obj_top
./sim_top +hex=../my_test.hex
```

### Explore the Design

Key files to understand:
1. `rtl/pkg/riscv_pkg.sv` - ISA definitions
2. `rtl/core/id_stage.sv` - Instruction decoder
3. `rtl/units/hazard_unit.sv` - Pipeline control
4. `rtl/core/riscv_top.sv` - Top-level integration

### Run Synthesis

```bash
cd syn
yosys -s synth.tcl
# Check reports in syn/ directory
```

### Run Physical Design

```bash
cd pnr
openlane config.json
# Results in pnr/runs/<timestamp>/
```

## Performance Tips

### Faster Simulation

Add to testbench:
```systemverilog
initial begin
  $dumpfile("sim.vcd");
  $dumpvars(1, tb_riscv_top);  // Only dump top-level signals
end
```

### Parallel Testing

```bash
# Run tests in parallel
make test_alu & make test_regfile & wait
```

### Optimize Synthesis

Edit `syn/synth.tcl`:
```tcl
# More aggressive optimization
synth -top riscv_top -flatten -run :fine
abc -liberty $env(ASAP7_LIBERTY) -D 1250  # 800 MHz = 1250 ps
```

## Common Commands

```bash
# Clean everything
make clean

# Rebuild from scratch
make clean && make test_all

# Run specific test
cd build/obj_top
./sim_top +hex=../arith_test.hex

# Check synthesis results
cat syn/riscv_top_synth.v | grep -c "DFF"  # Count flip-flops

# View timing report
cat pnr/runs/*/reports/signoff/sta-rcx_nom/summary.rpt
```

## Getting Help

1. Check `README.md` for detailed documentation
2. Check `IMPLEMENTATION.md` for design details
3. View waveforms to debug issues
4. Check log files in `build/` directory

## Success Criteria

You've successfully completed the quick start if:
- ✅ All unit tests pass
- ✅ All 5 assembly tests pass
- ✅ You can view waveforms in GTKWave
- ✅ Synthesis completes without errors

Congratulations! You now have a working RISC-V processor.
