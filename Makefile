# Makefile for RISC-V RV32I Processor

# Directories
RTL_DIR = rtl
TB_DIR = tb
VERIF_DIR = verif
SYN_DIR = syn
PNR_DIR = pnr
BUILD_DIR = build

# Tools
VERILATOR = verilator
YOSYS = yosys
RISCV_PREFIX = riscv32-unknown-elf-
AS = $(RISCV_PREFIX)as
LD = $(RISCV_PREFIX)ld
OBJCOPY = $(RISCV_PREFIX)objcopy

# Verilator flags
VFLAGS = --cc --exe --build --main -Wall --trace --timing -Wno-UNUSEDPARAM -Wno-BLKSEQ -Wno-UNUSEDSIGNAL
VFLAGS += -I$(RTL_DIR)/pkg
VFLAGS += --top-module

# Source files
RTL_PKG = $(RTL_DIR)/pkg/riscv_pkg.sv $(RTL_DIR)/pkg/pipeline_pkg.sv
RTL_UNITS = $(wildcard $(RTL_DIR)/units/*.sv)
RTL_CORE = $(wildcard $(RTL_DIR)/core/*.sv)
RTL_MEM = $(wildcard $(RTL_DIR)/mem/*.sv)
RTL_ALL = $(RTL_PKG) $(RTL_UNITS) $(RTL_CORE) $(RTL_MEM)

# Testbenches
TB_ALU = $(TB_DIR)/tb_alu.sv
TB_REGFILE = $(TB_DIR)/tb_regfile.sv
TB_TOP = $(TB_DIR)/tb_riscv_top.sv

# Assembly tests
ASM_TESTS = boot_test arith_test branch_test load_store_test hazard_test

.PHONY: all clean test_alu test_regfile test_all synth pnr help

# Default target
all: test_all

# Help
help:
	@echo "RISC-V RV32I Processor Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  test_alu      - Run ALU unit test"
	@echo "  test_regfile  - Run register file unit test"
	@echo "  test_all      - Run all unit tests"
	@echo "  test_asm      - Run directed assembly tests"
	@echo "  synth         - Synthesize with Yosys"
	@echo "  pnr           - Place & route with OpenLane"
	@echo "  clean         - Remove build artifacts"
	@echo "  help          - Show this help"

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# ALU unit test
test_alu: $(BUILD_DIR)
	@echo "=== Building ALU test ==="
	$(VERILATOR) $(VFLAGS) tb_alu \
		$(RTL_DIR)/pkg/riscv_pkg.sv \
		$(RTL_DIR)/units/alu.sv \
		$(TB_ALU) \
		--Mdir $(BUILD_DIR)/obj_alu \
		-o sim_alu
	@echo "=== Running ALU test ==="
	$(BUILD_DIR)/obj_alu/sim_alu

# Register file unit test
test_regfile: $(BUILD_DIR)
	@echo "=== Building register file test ==="
	$(VERILATOR) $(VFLAGS) tb_regfile \
		$(RTL_DIR)/units/regfile.sv \
		$(TB_REGFILE) \
		--Mdir $(BUILD_DIR)/obj_regfile \
		-o sim_regfile
	@echo "=== Running register file test ==="
	$(BUILD_DIR)/obj_regfile/sim_regfile

# Top-level test (requires hex file)
test_top: $(BUILD_DIR)
	@echo "=== Building top-level test ==="
	$(VERILATOR) $(VFLAGS) tb_riscv_top \
		$(RTL_ALL) \
		$(TB_TOP) \
		--Mdir $(BUILD_DIR)/obj_top \
		-o sim_top
	@echo "Build complete. Run with: $(BUILD_DIR)/obj_top/sim_top +hex=<file.hex>"

# Compile assembly test
$(BUILD_DIR)/%.hex: $(VERIF_DIR)/asm/%.S $(BUILD_DIR)
	@echo "Compiling $<..."
	riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -c -o $(BUILD_DIR)/$*.o $<
	riscv64-unknown-elf-ld -m elf32lriscv -T $(VERIF_DIR)/scripts/linker.ld -o $(BUILD_DIR)/$*.elf $(BUILD_DIR)/$*.o
	riscv64-unknown-elf-objcopy -O verilog --verilog-data-width=4 $(BUILD_DIR)/$*.elf $@

# Run assembly tests
test_asm: test_top $(addprefix $(BUILD_DIR)/, $(addsuffix .hex, $(ASM_TESTS)))
	@echo "=== Running assembly tests ==="
	@for test in $(ASM_TESTS); do \
		echo ""; \
		echo "Running $$test..."; \
		$(BUILD_DIR)/obj_top/sim_top +hex=$(BUILD_DIR)/$$test.hex || exit 1; \
	done
	@echo ""
	@echo "=== All assembly tests passed ==="

# Run all unit tests
test_all: test_alu test_regfile
	@echo ""
	@echo "=== All unit tests passed ==="

# Synthesis
synth:
	@echo "=== Running Yosys synthesis ==="
	cd $(SYN_DIR) && $(YOSYS) -s synth.tcl

# Place & Route
pnr: synth
	@echo "=== Running OpenLane PnR ==="
	cd $(PNR_DIR) && openlane config.json

# Clean
clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(SYN_DIR)/*.v $(SYN_DIR)/*.json
	rm -rf $(PNR_DIR)/runs
	rm -f *.vcd *.log

# Phony targets
.PHONY: all help test_alu test_regfile test_top test_asm test_all synth pnr clean
