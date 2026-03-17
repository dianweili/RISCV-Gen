# 完整安装和测试流程

## 📋 概述

本指南将帮助你在 Windows 上通过 WSL2 完成 RISC-V 处理器的编译和测试。

## 🚀 快速开始（3 步完成）

### 步骤 1：安装 WSL2 + Ubuntu

**在 PowerShell（管理员）中运行：**

```powershell
# 1. 打开 PowerShell（管理员）
#    按 Win+X，选择"Windows PowerShell (管理员)"

# 2. 安装 WSL2 和 Ubuntu
wsl --install -d Ubuntu-22.04

# 3. 重启电脑
shutdown /r /t 0
```

**重启后，Ubuntu 会自动启动，设置用户名和密码。**

---

### 步骤 2：安装开发工具

**在 Ubuntu 终端中运行：**

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 一键安装所有工具
sudo apt install -y verilator gcc-riscv64-unknown-elf make gtkwave git

# 创建 riscv32 软链接
sudo ln -sf /usr/bin/riscv64-unknown-elf-gcc /usr/bin/riscv32-unknown-elf-gcc
sudo ln -sf /usr/bin/riscv64-unknown-elf-as /usr/bin/riscv32-unknown-elf-as
sudo ln -sf /usr/bin/riscv64-unknown-elf-ld /usr/bin/riscv32-unknown-elf-ld
sudo ln -sf /usr/bin/riscv64-unknown-elf-objcopy /usr/bin/riscv32-unknown-elf-objcopy
```

---

### 步骤 3：运行测试

```bash
# 进入项目目录
cd /mnt/d/Project/RISCV-Gen

# 检查环境
./check_tools.sh

# 如果检查通过，运行测试
make test_alu
make test_regfile
```

---

## 📊 详细测试流程

### 测试 1：ALU 单元测试（30 秒）

```bash
cd /mnt/d/Project/RISCV-Gen
make test_alu
```

**预期输出：**
```
=== Building ALU test ===
...
=== Running ALU test ===
=== ALU Unit Test ===
ADD: 10 + 20 = 30
SUB: 50 - 20 = 30
AND: 0xf0f0 & 0xff00 = 0xf000
OR: 0xf0f0 | 0x0f0f = 0xffff
XOR: 0xffff ^ 0xf0f0 = 0x0f0f
SLL: 1 << 4 = 16
SRL: 16 >> 2 = 4
SRA: 0xfffffff0 >>> 2 = 0xfffffffc
SLT: -10 < 5 = 1
SLTU: 5 < 10 = 1
PASS_B: b = 0xbeef
=== All ALU tests passed ===
```

---

### 测试 2：寄存器堆测试（30 秒）

```bash
make test_regfile
```

**预期输出：**
```
=== Building register file test ===
...
=== Running register file test ===
=== Register File Unit Test ===
x1 = 0xdeadbeef (expected 0xDEADBEEF)
x0 = 0x00000000 (expected 0x00000000)
x1 = 0xdeadbeef, x31 = 0x12345678
=== All register file tests passed ===
```

---

### 测试 3：编译顶层模块（1 分钟）

```bash
make test_top
```

这会编译整个处理器，但不运行测试。

**预期输出：**
```
=== Building top-level test ===
...
Build complete. Run with: build/obj_top/sim_top +hex=<file.hex>
```

---

### 测试 4：汇编测试（2 分钟）

```bash
make test_asm
```

这会编译并运行 5 个汇编测试程序。

**预期输出：**
```
=== Compiling Assembly Tests ===
Compiling boot_test.S...
Compiling arith_test.S...
...

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

## 🔍 查看波形（可选）

如果想查看仿真波形：

```bash
# 运行单个测试并生成波形
cd build/obj_top
./sim_top +hex=../boot_test.hex

# 在 WSL 中打开 GTKWave
gtkwave ../../sim_riscv.vcd &

# 或者在 Windows 中打开（需要安装 Windows 版 GTKWave）
# 波形文件位置：D:\Project\RISCV-Gen\sim_riscv.vcd
```

---

## ⚙️ 综合（可选，需要 Yosys）

```bash
# 安装 Yosys
sudo apt install -y yosys

# 运行综合
make synth

# 查看结果
cat syn/riscv_top_synth.v | grep -c "DFF"  # 统计触发器数量
```

---

## 🐛 故障排除

### 问题 1：无法访问 /mnt/d

```bash
# 检查挂载
ls /mnt/

# 手动挂载
sudo mkdir -p /mnt/d
sudo mount -t drvfs D: /mnt/d
```

### 问题 2：Verilator 版本过低

```bash
verilator --version  # 检查版本

# 如果低于 5.0，从源码编译
sudo apt install -y git autoconf flex bison
git clone https://github.com/verilator/verilator
cd verilator
git checkout stable
autoconf && ./configure && make -j$(nproc) && sudo make install
```

### 问题 3：编译错误

```bash
# 检查文件权限
ls -la rtl/pkg/

# 修复权限
chmod -R 755 rtl/ tb/ verif/

# 清理并重新编译
make clean
make test_alu
```

### 问题 4：找不到 riscv32-unknown-elf-gcc

```bash
# 检查是否有 riscv64
which riscv64-unknown-elf-gcc

# 创建软链接
sudo ln -sf /usr/bin/riscv64-unknown-elf-gcc /usr/bin/riscv32-unknown-elf-gcc
sudo ln -sf /usr/bin/riscv64-unknown-elf-as /usr/bin/riscv32-unknown-elf-as
sudo ln -sf /usr/bin/riscv64-unknown-elf-ld /usr/bin/riscv32-unknown-elf-ld
sudo ln -sf /usr/bin/riscv64-unknown-elf-objcopy /usr/bin/riscv32-unknown-elf-objcopy
```

---

## 📝 测试清单

完成以下测试即表示环境配置成功：

- [ ] WSL2 已安装并可以启动
- [ ] 可以访问 `/mnt/d/Project/RISCV-Gen`
- [ ] `./check_tools.sh` 全部通过
- [ ] `make test_alu` 通过
- [ ] `make test_regfile` 通过
- [ ] `make test_top` 编译成功
- [ ] `make test_asm` 全部通过（5/5）

---

## 🎯 下一步

测试全部通过后，你可以：

1. **修改 RTL 代码**：编辑 `rtl/` 目录下的文件
2. **添加新测试**：在 `verif/asm/` 添加汇编测试
3. **查看架构**：阅读 `ARCHITECTURE.md`
4. **运行综合**：`make synth`（需要 Yosys）

---

## 💡 提示

- WSL2 中的文件修改会立即反映到 Windows
- 可以在 Windows 中用 VS Code 编辑，在 WSL2 中编译
- 使用 `code .` 在 WSL2 中打开 VS Code（需要安装 Remote-WSL 插件）

---

## 📚 相关文档

- `README.md` — 项目总览
- `QUICKSTART.md` — 快速开始
- `ARCHITECTURE.md` — 架构详解
- `WSL2_INSTALL.md` — WSL2 详细安装
- `WINDOWS_SETUP.md` — 其他 Windows 方案

---

**准备好了吗？开始第一步：在 PowerShell（管理员）中运行 `wsl --install -d Ubuntu-22.04`**
