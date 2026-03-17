#!/bin/bash
# check_tools.sh — 检查开发工具是否正确安装

echo "=========================================="
echo "  RISC-V 开发环境检查"
echo "=========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_tool() {
    local tool=$1
    local name=$2

    if command -v $tool &> /dev/null; then
        version=$($tool --version 2>&1 | head -1)
        echo -e "${GREEN}✓${NC} $name: $version"
        return 0
    else
        echo -e "${RED}✗${NC} $name: 未安装"
        return 1
    fi
}

# 检查必需工具
echo "必需工具："
check_tool "verilator" "Verilator"
VERILATOR_OK=$?

check_tool "riscv32-unknown-elf-gcc" "RISC-V GCC (32-bit)"
RISCV32_OK=$?

if [ $RISCV32_OK -ne 0 ]; then
    check_tool "riscv64-unknown-elf-gcc" "RISC-V GCC (64-bit)"
    RISCV64_OK=$?
    if [ $RISCV64_OK -eq 0 ]; then
        echo -e "${YELLOW}⚠${NC}  提示：检测到 riscv64，需要创建 riscv32 软链接"
        echo "    运行：sudo ln -sf /usr/bin/riscv64-unknown-elf-gcc /usr/bin/riscv32-unknown-elf-gcc"
    fi
fi

check_tool "make" "Make"
MAKE_OK=$?

echo ""
echo "可选工具："
check_tool "gtkwave" "GTKWave (波形查看)"
check_tool "yosys" "Yosys (综合)"
check_tool "git" "Git"

echo ""
echo "=========================================="

# 检查项目文件
echo ""
echo "项目文件检查："
if [ -f "rtl/pkg/riscv_pkg.sv" ]; then
    echo -e "${GREEN}✓${NC} RTL 文件存在"
    RTL_OK=0
else
    echo -e "${RED}✗${NC} RTL 文件不存在（请确认在项目根目录运行）"
    RTL_OK=1
fi

if [ -f "Makefile" ]; then
    echo -e "${GREEN}✓${NC} Makefile 存在"
    MAKEFILE_OK=0
else
    echo -e "${RED}✗${NC} Makefile 不存在"
    MAKEFILE_OK=1
fi

echo ""
echo "=========================================="
echo ""

# 总结
if [ $VERILATOR_OK -eq 0 ] && [ $RISCV32_OK -eq 0 ] && [ $MAKE_OK -eq 0 ] && [ $RTL_OK -eq 0 ]; then
    echo -e "${GREEN}✓ 环境配置完成！可以开始测试${NC}"
    echo ""
    echo "运行以下命令开始测试："
    echo "  make test_alu       # 测试 ALU"
    echo "  make test_regfile   # 测试寄存器堆"
    echo "  make test_asm       # 运行汇编测试"
    exit 0
else
    echo -e "${RED}✗ 环境配置不完整${NC}"
    echo ""
    echo "请按照 WSL2_INSTALL.md 中的步骤安装缺失的工具"
    exit 1
fi
