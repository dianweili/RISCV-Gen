# Linux 环境快速启动指南

## 从 GitHub 克隆项目

```bash
# 克隆仓库
git clone https://github.com/dianweili/RISCV-Gen.git
cd RISCV-Gen

# 查看项目结构
ls -la
```

---

## 安装开发工具

### Ubuntu/Debian

```bash
# 更新包管理器
sudo apt update && sudo apt upgrade -y

# 安装必需工具
sudo apt install -y \
    verilator \
    gcc-riscv64-unknown-elf \
    make \
    gtkwave \
    git

# 创建 riscv32 软链接（Ubuntu 只提供 riscv64）
sudo ln -sf /usr/bin/riscv64-unknown-elf-gcc /usr/bin/riscv32-unknown-elf-gcc
sudo ln -sf /usr/bin/riscv64-unknown-elf-as /usr/bin/riscv32-unknown-elf-as
sudo ln -sf /usr/bin/riscv64-unknown-elf-ld /usr/bin/riscv32-unknown-elf-ld
sudo ln -sf /usr/bin/riscv64-unknown-elf-objcopy /usr/bin/riscv32-unknown-elf-objcopy

# 验证安装
verilator --version
riscv32-unknown-elf-gcc --version
make --version
```

### 如果 Verilator 版本过低（需要 5.x+）

```bash
# Ubuntu 22.04 默认是 4.x，需要从源码编译
sudo apt install -y git autoconf flex bison

git clone https://github.com/verilator/verilator
cd verilator
git checkout stable
autoconf
./configure
make -j$(nproc)
sudo make install

# 验证
verilator --version  # 应该显示 5.x
```

---

## 验证环境

```bash
cd RISCV-Gen

# 运行环境检查脚本
chmod +x check_tools.sh
./check_tools.sh

# 预期输出：
# ✓ Verilator: ...
# ✓ RISC-V GCC (32-bit): ...
# ✓ Make: ...
# ✓ 环境配置完成！可以开始测试
```

---

## 运行测试

### 1. ALU 单元测试（30 秒）

```bash
make test_alu
```

**预期输出：**
```
=== ALU Unit Test ===
ADD: 10 + 20 = 30
SUB: 50 - 20 = 30
...
=== All ALU tests passed ===
```

### 2. 寄存器堆测试（30 秒）

```bash
make test_regfile
```

**预期输出：**
```
=== Register File Unit Test ===
x1 = 0xdeadbeef (expected 0xDEADBEEF)
x0 = 0x00000000 (expected 0x00000000)
...
=== All register file tests passed ===
```

### 3. 编译顶层模块（1 分钟）

```bash
make test_top
```

### 4. 汇编集成测试（2 分钟）

```bash
make test_asm
```

**预期输出：**
```
=== Running Tests ===

Running boot_test...
[PASS] Test passed at cycle 45
✓ boot_test PASSED

Running arith_test...
[PASS] Test passed at cycle 78
✓ arith_test PASSED

...

=== Test Summary ===
Passed: 5
Failed: 0
All tests passed!
```

---

## 查看波形（可选）

```bash
# 运行单个测试生成波形
cd build/obj_top
./sim_top +hex=../boot_test.hex

# 打开 GTKWave 查看
gtkwave ../../sim_riscv.vcd &
```

---

## 综合（需要 Yosys + ASAP7 PDK）

### 安装 Yosys

```bash
sudo apt install -y yosys
```

### 下载 ASAP7 PDK

```bash
# 从 http://asap.asu.edu/asap/ 下载 ASAP7 PDK
# 或使用 git
git clone https://github.com/The-OpenROAD-Project/asap7.git

# 设置环境变量
export ASAP7_LIBERTY=/path/to/asap7/lib/asap7sc7p5t_SEQ_RVT.lib
```

### 运行综合

```bash
cd RISCV-Gen
make synth

# 查看结果
cat syn/riscv_top_synth.v | grep -c "DFF"  # 统计触发器数量
```

---

## 物理设计（需要 OpenLane2）

### 安装 OpenLane2

```bash
# 参考 OpenLane2 官方文档
# https://openlane2.readthedocs.io/

# 简化安装（使用 Docker）
docker pull efabless/openlane2
```

### 运行 PnR

```bash
cd RISCV-Gen
make pnr

# 或使用 Docker
docker run -it -v $(pwd):/workspace efabless/openlane2 \
    openlane /workspace/pnr/config.json
```

---

## 关键文件位置

| 文件 | 说明 |
|------|------|
| `rtl/core/riscv_top.sv` | 顶层模块（350 行） |
| `rtl/pkg/riscv_pkg.sv` | ISA 定义（200 行） |
| `rtl/pkg/pipeline_pkg.sv` | 流水线寄存器结构（150 行） |
| `rtl/core/id_stage.sv` | 译码器（200 行，最复杂） |
| `rtl/units/hazard_unit.sv` | 冒险检测（50 行） |
| `Makefile` | 构建脚本 |
| `check_tools.sh` | 环境检查脚本 |

---

## 测试签名说明

所有汇编测试使用相同的 PASS/FAIL 机制：
- **PASS**: 向地址 `0x100` 写入 `0xDEADBEEF`
- **FAIL**: 向地址 `0x100` 写入 `0xBADBAD`

测试台会监控这个地址，检测到 PASS 值后停止仿真。

---

## 内存映射

```
0x0000_0000 - 0x0000_3FFF : 指令存储器 (IMEM, 16KB)
0x0001_0000 - 0x0001_3FFF : 数据存储器 (DMEM, 16KB)
0x0000_0100                : 测试签名地址
```

---

## 设计参数

| 参数 | 值 |
|------|-----|
| 目标频率 | 800 MHz |
| 时钟周期 | 1.25 ns |
| 工艺 | ASAP7 7nm |
| 电压 | 0.75V |
| 估计 CPI | 1.2-1.3 |
| 估计面积 | 6K 门（不含存储器） |

---

## 故障排除

### Verilator 版本过低
```bash
verilator --version  # 需要 5.x+
# 如果是 4.x，按上面步骤从源码编译
```

### 找不到 riscv32-unknown-elf-gcc
```bash
# 检查是否有 riscv64
which riscv64-unknown-elf-gcc

# 创建软链接
sudo ln -sf /usr/bin/riscv64-unknown-elf-gcc /usr/bin/riscv32-unknown-elf-gcc
```

### 编译错误
```bash
# 清理并重新编译
make clean
make test_alu
```

---

## 下一步

1. ✅ 克隆仓库
2. ✅ 安装工具
3. ✅ 运行 `./check_tools.sh`
4. ✅ 运行 `make test_alu`
5. ✅ 运行 `make test_regfile`
6. ✅ 运行 `make test_asm`
7. ⏳ 运行 `make synth`（可选）
8. ⏳ 运行 `make pnr`（可选）

---

## 相关文档

- `README.md` — 项目总览
- `ARCHITECTURE.md` — 架构详解
- `IMPLEMENTATION.md` — 实现细节
- `QUICKSTART.md` — 快速开始
- `STATUS.md` — 项目状态

---

**GitHub 仓库：** https://github.com/dianweili/RISCV-Gen
