#!/bin/bash
# run_directed.sh — Run directed assembly tests with Verilator

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directories
RTL_DIR="../rtl"
TB_DIR="../tb"
ASM_DIR="../verif/asm"
BUILD_DIR="./build"

# Create build directory
mkdir -p $BUILD_DIR

echo "=== RISC-V Directed Test Runner ==="

# Compile RTL with Verilator
echo "Compiling RTL..."
verilator --cc --exe --build -Wall \
  --top-module tb_riscv_top \
  -I$RTL_DIR/pkg \
  $RTL_DIR/pkg/*.sv \
  $RTL_DIR/units/*.sv \
  $RTL_DIR/core/*.sv \
  $RTL_DIR/mem/*.sv \
  $TB_DIR/tb_riscv_top.sv \
  --Mdir $BUILD_DIR \
  -o sim_riscv

if [ $? -ne 0 ]; then
  echo -e "${RED}Compilation failed${NC}"
  exit 1
fi

echo -e "${GREEN}Compilation successful${NC}"

# List of assembly tests
TESTS=(
  "boot_test"
  "arith_test"
  "branch_test"
  "load_store_test"
  "hazard_test"
)

# Compile assembly tests to hex
echo ""
echo "=== Compiling Assembly Tests ==="
for test in "${TESTS[@]}"; do
  echo "Compiling $test.S..."
  riscv32-unknown-elf-as -march=rv32i -mabi=ilp32 \
    -o $BUILD_DIR/$test.o $ASM_DIR/$test.S

  riscv32-unknown-elf-ld -T linker.ld \
    -o $BUILD_DIR/$test.elf $BUILD_DIR/$test.o

  riscv32-unknown-elf-objcopy -O verilog \
    $BUILD_DIR/$test.elf $BUILD_DIR/$test.hex
done

# Run tests
echo ""
echo "=== Running Tests ==="
PASS_COUNT=0
FAIL_COUNT=0

for test in "${TESTS[@]}"; do
  echo ""
  echo "Running $test..."

  if $BUILD_DIR/sim_riscv +hex=$BUILD_DIR/$test.hex > $BUILD_DIR/$test.log 2>&1; then
    if grep -q "\[PASS\]" $BUILD_DIR/$test.log; then
      echo -e "${GREEN}✓ $test PASSED${NC}"
      ((PASS_COUNT++))
    else
      echo -e "${RED}✗ $test FAILED${NC}"
      ((FAIL_COUNT++))
      cat $BUILD_DIR/$test.log
    fi
  else
    echo -e "${RED}✗ $test CRASHED${NC}"
    ((FAIL_COUNT++))
    cat $BUILD_DIR/$test.log
  fi
done

# Summary
echo ""
echo "=== Test Summary ==="
echo -e "Passed: ${GREEN}$PASS_COUNT${NC}"
echo -e "Failed: ${RED}$FAIL_COUNT${NC}"

if [ $FAIL_COUNT -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed${NC}"
  exit 1
fi
