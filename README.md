# RISC-V RV32I 5-Stage Pipeline Processor

Complete ASIC implementation of a RISC-V RV32I processor with 5-stage pipeline, from RTL to physical design using open-source tools.

## Features

- **ISA**: RISC-V RV32I base integer instruction set
- **Pipeline**: 5-stage (IF, ID, EX, MEM, WB)
- **Hazard Handling**:
  - Data forwarding (EX→EX, MEM→EX)
  - Load-use stall detection
  - Branch/jump flush control
- **CSR Support**: Minimal trap handling (mstatus, mtvec, mepc, mcause, mtval)
- **Target**: ASAP7 7nm PDK, 800 MHz @ 0.75V

## Directory Structure

```
RISCV-Gen/
├── rtl/              # RTL source files
│   ├── pkg/          # Package definitions
│   ├── core/         # Pipeline stages
│   ├── units/        # Functional units
│   └── mem/          # Memory models
├── tb/               # Testbenches
├── verif/            # Verification
│   ├── asm/          # Assembly tests
│   └── scripts/      # Test scripts
├── syn/              # Synthesis
└── pnr/              # Place & Route
```

## Prerequisites

### Required Tools

- **Verilator** 5.x - RTL simulation
- **RISC-V GNU Toolchain** - Assembly compilation
  ```bash
  # Ubuntu/Debian
  sudo apt install gcc-riscv64-unknown-elf
  ```
- **Yosys** - Logic synthesis
- **OpenLane2** - Physical design flow
- **ASAP7 PDK** - 7nm process design kit

### Optional Tools

- **GTKWave** - Waveform viewer
- **RISCOF** - RISC-V compliance testing

## Quick Start

### 1. Run Unit Tests

```bash
cd tb
make test_alu
make test_regfile
```

### 2. Run Directed Assembly Tests

```bash
cd verif/scripts
chmod +x run_directed.sh
./run_directed.sh
```

### 3. Synthesize Design

```bash
cd syn
yosys -s synth.tcl
```

### 4. Place & Route

```bash
cd pnr
openlane config.json
```

## Microarchitecture

### Pipeline Stages

```
┌────┐   ┌────┐   ┌────┐   ┌─────┐   ┌────┐
│ IF │──▶│ ID │──▶│ EX │──▶│ MEM │──▶│ WB │
└────┘   └────┘   └────┘   └─────┘   └────┘
```

### Hazard Handling

**Data Hazards:**
- EX→EX forwarding: 0-cycle penalty
- MEM→EX forwarding: 0-cycle penalty
- Load-use: 1-cycle stall

**Control Hazards:**
- JAL: 1-cycle penalty (resolved in ID)
- Branch: 2-cycle penalty (resolved in EX)
- JALR: 2-cycle penalty (resolved in EX)

### Performance

- **CPI**: ~1.2 (with typical branch/load mix)
- **Frequency**: 800 MHz target @ ASAP7 7nm
- **Area**: ~5K-8K standard cells (estimated)

## Testing

### Directed Tests

Located in `verif/asm/`:
- `boot_test.S` - Basic boot and arithmetic
- `arith_test.S` - Comprehensive ALU operations
- `branch_test.S` - All branch instructions
- `load_store_test.S` - Memory access with alignment
- `hazard_test.S` - Data forwarding and stalls

### Running Tests

```bash
# All directed tests
cd verif/scripts
./run_directed.sh

# Single test
cd tb
verilator --cc --exe --build tb_riscv_top.sv ../rtl/**/*.sv
./obj_dir/Vtb_riscv_top +hex=../verif/asm/boot_test.hex
```

### Compliance Testing

```bash
cd verif/riscof
riscof run --config config.ini --suite riscv-arch-test/rv32i
```

## Synthesis

### Yosys Synthesis

```bash
cd syn
export ASAP7_LIBERTY=/path/to/asap7sc7p5t_SEQ_RVT.lib
yosys -s synth.tcl
```

Output: `syn/riscv_top_synth.v`

### Timing Constraints

- Clock: 1.25 ns (800 MHz)
- Input delay: 0.25 ns
- Output delay: 0.25 ns
- Clock uncertainty: 50 ps

## Physical Design

### OpenLane2 Flow

```bash
cd pnr
openlane config.json
```

### Configuration

- Die size: 300 µm × 300 µm
- Core utilization: 65%
- Target density: 0.65
- PDN pitch: 25 µm

### Outputs

- GDS: `pnr/runs/<timestamp>/results/final/gds/riscv_top.gds`
- DEF: `pnr/runs/<timestamp>/results/final/def/riscv_top.def`
- Reports: `pnr/runs/<timestamp>/reports/`

## Design Verification

### Functional Coverage

- [x] All RV32I instructions
- [x] Data forwarding paths
- [x] Load-use stalls
- [x] Branch/jump control flow
- [x] Memory alignment
- [ ] CSR operations (partial)
- [ ] Trap handling (minimal)

### Known Limitations

- No interrupts
- No M-extension (multiply/divide)
- No A-extension (atomics)
- Minimal CSR support
- No performance counters

## Performance Optimization

### Critical Paths

1. **EX stage**: ALU + forwarding mux
2. **Hazard detection**: Load-use check
3. **Branch resolution**: Comparator + target calculation

### Optimization Strategies

- Pipeline balancing
- Retiming registers
- Buffering high-fanout nets
- Clock tree synthesis

## Contributing

This is an educational/reference implementation. Contributions welcome:

1. Additional test cases
2. Performance optimizations
3. Extended ISA support (M, C extensions)
4. Formal verification

## License

MIT License - See LICENSE file

## References

- [RISC-V ISA Specification](https://riscv.org/technical/specifications/)
- [ASAP7 PDK](http://asap.asu.edu/asap/)
- [OpenLane Documentation](https://openlane.readthedocs.io/)
- [Verilator Manual](https://verilator.org/guide/latest/)

## Authors

Generated implementation based on RISC-V RV32I specification.

## Acknowledgments

- RISC-V Foundation
- OpenROAD Project
- ASAP7 PDK Team
- Open-source EDA community
