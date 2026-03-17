# Windows 环境安装指南

## 当前状态

你的系统：Windows 10/11 + Git Bash (MINGW64)
已安装：Chocolatey, Winget
缺少：Verilator, RISC-V 工具链, Yosys

## 方案 1：使用 WSL2（推荐）

### 安装 WSL2 + Ubuntu

```powershell
# 在 PowerShell (管理员) 中运行
wsl --install -d Ubuntu-22.04
# 重启后设置用户名密码
```

### 在 WSL2 中安装工具

```bash
# 更新包管理器
sudo apt update && sudo apt upgrade -y

# 安装 Verilator
sudo apt install -y verilator

# 安装 RISC-V 工具链
sudo apt install -y gcc-riscv64-unknown-elf

# 安装其他工具
sudo apt install -y make gtkwave

# 验证安装
verilator --version
riscv64-unknown-elf-gcc --version
```

### 访问 Windows 文件

```bash
# 项目在 WSL 中的路径
cd /mnt/d/Project/RISCV-Gen

# 运行测试
make test_alu
make test_regfile
```

## 方案 2：使用 MSYS2（轻量级）

### 安装 MSYS2

```powershell
# 使用 Chocolatey 安装
choco install msys2 -y
```

### 在 MSYS2 MINGW64 终端中安装

```bash
# 更新包数据库
pacman -Syu

# 安装 Verilator
pacman -S mingw-w64-x86_64-verilator

# 安装 Make
pacman -S make

# RISC-V 工具链需要手动下载（见下方）
```

### 下载 RISC-V 工具链

访问：https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases

下载：`xpack-riscv-none-elf-gcc-13.2.0-2-win32-x64.zip`

解压到：`C:\riscv-toolchain`

添加到 PATH：
```bash
export PATH="/c/riscv-toolchain/bin:$PATH"
```

## 方案 3：使用 Docker（隔离环境）

### 安装 Docker Desktop

```powershell
winget install Docker.DockerDesktop
```

### 创建 Dockerfile

```dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    verilator \
    gcc-riscv64-unknown-elf \
    make \
    gtkwave \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
```

### 构建并运行

```bash
# 在项目目录
docker build -t riscv-dev .
docker run -it -v D:/Project/RISCV-Gen:/workspace riscv-dev bash

# 在容器内
make test_alu
```

## 方案 4：仅验证 RTL 语法（最简单）

如果只想检查 RTL 语法，可以使用在线工具或轻量级工具：

### 使用 Icarus Verilog (iverilog)

```powershell
# 使用 Chocolatey 安装
choco install iverilog -y
```

```bash
# 编译检查语法
cd D:/Project/RISCV-Gen
iverilog -g2012 -o build/test.vvp \
  rtl/pkg/*.sv rtl/units/*.sv rtl/core/*.sv rtl/mem/*.sv
```

### 使用在线工具

- EDA Playground: https://www.edaplayground.com/
- HDLBits: https://hdlbits.01xz.net/

## 推荐方案对比

| 方案 | 优点 | 缺点 | 适用场景 |
|------|------|------|----------|
| WSL2 | 完整 Linux 环境，工具齐全 | 需要重启，占用空间大 | 完整开发流程 |
| MSYS2 | 轻量，原生 Windows | 工具链不完整 | 快速测试 |
| Docker | 隔离环境，可复现 | 需要 Docker 知识 | CI/CD 集成 |
| Icarus | 最简单，快速安装 | 功能有限 | 语法检查 |

## 快速开始（推荐 WSL2）

```bash
# 1. 安装 WSL2
wsl --install -d Ubuntu-22.04

# 2. 重启后，在 WSL2 中
sudo apt update
sudo apt install -y verilator gcc-riscv64-unknown-elf make

# 3. 进入项目
cd /mnt/d/Project/RISCV-Gen

# 4. 运行测试
make test_alu
make test_regfile

# 5. 如果成功，继续
make test_asm
```

## 故障排除

### WSL2 无法访问 D 盘

```bash
# 检查挂载
ls /mnt/d

# 如果不存在，手动挂载
sudo mkdir -p /mnt/d
sudo mount -t drvfs D: /mnt/d
```

### RISC-V 工具链版本问题

```bash
# Ubuntu 的包可能是 riscv64，但我们需要 riscv32
# 创建软链接
sudo ln -s /usr/bin/riscv64-unknown-elf-gcc /usr/bin/riscv32-unknown-elf-gcc
sudo ln -s /usr/bin/riscv64-unknown-elf-as /usr/bin/riscv32-unknown-elf-as
sudo ln -s /usr/bin/riscv64-unknown-elf-ld /usr/bin/riscv32-unknown-elf-ld
sudo ln -s /usr/bin/riscv64-unknown-elf-objcopy /usr/bin/riscv32-unknown-elf-objcopy
```

### Verilator 版本过低

```bash
# 从源码编译最新版
sudo apt install -y git autoconf flex bison
git clone https://github.com/verilator/verilator
cd verilator
autoconf
./configure
make -j$(nproc)
sudo make install
```

## 下一步

安装完成后，返回主 README.md 继续"Quick Start"部分。
