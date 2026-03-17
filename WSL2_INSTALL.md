# WSL2 安装和配置步骤

## 第一步：安装 WSL2

### 1. 在 PowerShell（管理员）中运行

```powershell
# 打开 PowerShell（管理员）
# 按 Win+X，选择"Windows PowerShell (管理员)"

# 安装 WSL2 和 Ubuntu
wsl --install -d Ubuntu-22.04

# 如果提示需要启用功能，运行：
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# 重启电脑
shutdown /r /t 0
```

### 2. 重启后首次配置

重启后，Ubuntu 会自动启动，提示你：
```
Enter new UNIX username: [输入用户名，如 lidia]
New password: [输入密码]
Retype new password: [再次输入密码]
```

## 第二步：在 WSL2 中安装开发工具

打开 Ubuntu 终端（从开始菜单搜索"Ubuntu"），运行：

```bash
# 更新包管理器
sudo apt update && sudo apt upgrade -y

# 安装 Verilator（RTL 仿真器）
sudo apt install -y verilator

# 安装 RISC-V 工具链
sudo apt install -y gcc-riscv64-unknown-elf

# 安装其他必要工具
sudo apt install -y make gtkwave git

# 创建 riscv32 软链接（因为 Ubuntu 包是 riscv64）
sudo ln -sf /usr/bin/riscv64-unknown-elf-gcc /usr/bin/riscv32-unknown-elf-gcc
sudo ln -sf /usr/bin/riscv64-unknown-elf-as /usr/bin/riscv32-unknown-elf-as
sudo ln -sf /usr/bin/riscv64-unknown-elf-ld /usr/bin/riscv32-unknown-elf-ld
sudo ln -sf /usr/bin/riscv64-unknown-elf-objcopy /usr/bin/riscv32-unknown-elf-objcopy

# 验证安装
echo "=== 验证工具安装 ==="
verilator --version
riscv32-unknown-elf-gcc --version
make --version
```

## 第三步：访问项目并运行测试

```bash
# 进入项目目录（Windows D盘在 WSL 中挂载为 /mnt/d）
cd /mnt/d/Project/RISCV-Gen

# 查看文件
ls -la

# 运行 ALU 单元测试
make test_alu

# 运行寄存器堆测试
make test_regfile

# 如果上面成功，编译顶层模块
make test_top

# 编译汇编测试
make test_asm
```

## 预期输出

### test_alu 成功输出：
```
=== ALU Unit Test ===
ADD: 10 + 20 = 30
SUB: 50 - 20 = 30
AND: 0xf0f0 & 0xff00 = 0xf000
...
=== All ALU tests passed ===
```

### test_regfile 成功输出：
```
=== Register File Unit Test ===
x1 = 0xdeadbeef (expected 0xDEADBEEF)
x0 = 0x00000000 (expected 0x00000000)
...
=== All register file tests passed ===
```

## 常见问题

### Q1: 无法访问 /mnt/d
```bash
# 检查挂载
ls /mnt/

# 如果没有 d，手动挂载
sudo mkdir -p /mnt/d
sudo mount -t drvfs D: /mnt/d
```

### Q2: Verilator 版本过低
```bash
verilator --version  # 需要 5.x+

# 如果版本低于 5.0，从源码编译
sudo apt install -y git autoconf flex bison
git clone https://github.com/verilator/verilator
cd verilator
git checkout stable
autoconf
./configure
make -j$(nproc)
sudo make install
```

### Q3: 编译错误 "file not found"
```bash
# 检查文件权限
ls -la rtl/pkg/

# 如果有权限问题
chmod -R 755 rtl/ tb/ verif/
```

### Q4: 在 Windows 中查看 WSL 文件
```
在 Windows 资源管理器地址栏输入：
\\wsl$\Ubuntu-22.04\mnt\d\Project\RISCV-Gen
```

## 下一步

安装完成后，按照以下顺序测试：

1. ✅ `make test_alu` — 测试 ALU
2. ✅ `make test_regfile` — 测试寄存器堆
3. ✅ `make test_top` — 编译顶层模块
4. ✅ `make test_asm` — 运行汇编测试（需要 RISC-V 工具链）

如果遇到问题，请告诉我具体的错误信息。
