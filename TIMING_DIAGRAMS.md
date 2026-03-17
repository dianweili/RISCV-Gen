# RISC-V RV32I Pipeline Timing Diagrams (WaveDrom)

本文档使用 WaveDrom 格式描述处理器的典型工作时序。

## 查看方法

1. 访问 https://wavedrom.com/editor.html
2. 复制下面的 JSON 代码
3. 粘贴到编辑器中查看波形图

---

## 1. 无冒险的理想流水线

```wavedrom
{
  signal: [
    {name: 'clk', wave: 'p........'},
    {},
    {name: 'IF', wave: 'x2345678x', data: ['I1','I2','I3','I4','I5','I6','I7']},
    {name: 'ID', wave: 'xx2345678', data: ['I1','I2','I3','I4','I5','I6']},
    {name: 'EX', wave: 'xxx234567', data: ['I1','I2','I3','I4','I5']},
    {name: 'MEM', wave: 'xxxx23456', data: ['I1','I2','I3','I4']},
    {name: 'WB', wave: 'xxxxx2345', data: ['I1','I2','I3']},
    {},
    {name: 'CPI', wave: 'x........', data: ['1.0']}
  ],
  config: { hscale: 2 },
  head: {
    text: 'Ideal Pipeline - No Hazards (CPI = 1.0)',
    tick: 0
  }
}
```

---

## 2. Load-Use 冒险（1 周期停顿）

```wavedrom
{
  signal: [
    {name: 'clk', wave: 'p..........'},
    {},
    {name: 'IF', wave: 'x234.5678x.', data: ['LW','ADD','I3','I4','I5','I6']},
    {name: 'ID', wave: 'xx23.45678.', data: ['LW','ADD','ADD','I3','I4','I5']},
    {name: 'EX', wave: 'xxx2.34567.', data: ['LW','NOP','ADD','I3','I4']},
    {name: 'MEM', wave: 'xxxx.23456.', data: ['LW','NOP','ADD','I3']},
    {name: 'WB', wave: 'xxxxx.2345.', data: ['LW','NOP','ADD']},
    {},
    {name: 'pc_stall', wave: '0...10....'},
    {name: 'id_ex_flush', wave: '0...10....'},
    {},
    {name: 'Note', wave: 'x...=.....', data: ['STALL']}
  ],
  config: { hscale: 2 },
  head: {
    text: 'Load-Use Hazard (1-cycle stall)',
    tick: 0
  }
}
```

**说明：**
- Cycle 3: 检测到 LW 的 rd 与 ADD 的 rs1/rs2 冲突
- Cycle 4: 停顿 IF/ID，插入 bubble 到 ID/EX
- Cycle 5: ADD 继续执行，使用前递的 LW 结果

---

## 3. 分支预测失败（2 周期惩罚）

```wavedrom
{
  signal: [
    {name: 'clk', wave: 'p..........'},
    {},
    {name: 'IF', wave: 'x234..678x.', data: ['BEQ','I2','I3','T1','T2','T3']},
    {name: 'ID', wave: 'xx23..4567.', data: ['BEQ','I2','I3','T1','T2']},
    {name: 'EX', wave: 'xxx2..3456.', data: ['BEQ','NOP','NOP','T1']},
    {name: 'MEM', wave: 'xxxx..2345.', data: ['BEQ','NOP','NOP']},
    {name: 'WB', wave: 'xxxxx..234.', data: ['BEQ','NOP']},
    {},
    {name: 'branch_taken', wave: '0..10.....'},
    {name: 'if_id_flush', wave: '0..10.....'},
    {name: 'id_ex_flush', wave: '0..10.....'},
    {name: 'pc_sel', wave: '0..3.0....', data: ['BR']},
    {},
    {name: 'Note', wave: 'x..==.....', data: ['TAKEN','FLUSH']}
  ],
  config: { hscale: 2 },
  head: {
    text: 'Branch Misprediction (2-cycle penalty)',
    tick: 0
  }
}
```

**说明：**
- Cycle 3: BEQ 在 EX 阶段判断为 taken
- Cycle 4-5: 冲刷 IF/ID 和 ID/EX 中的指令（I2, I3）
- Cycle 6: 从分支目标 T1 开始取指

---

## 4. 数据前递（EX→EX）

```wavedrom
{
  signal: [
    {name: 'clk', wave: 'p.........'},
    {},
    {name: 'IF', wave: 'x23456789x', data: ['ADD','SUB','AND','OR','XOR','I6','I7']},
    {name: 'ID', wave: 'xx2345678x', data: ['ADD','SUB','AND','OR','XOR','I6']},
    {name: 'EX', wave: 'xxx234567x', data: ['ADD','SUB','AND','OR','XOR']},
    {name: 'MEM', wave: 'xxxx23456x', data: ['ADD','SUB','AND','OR']},
    {name: 'WB', wave: 'xxxxx2345x', data: ['ADD','SUB','AND']},
    {},
    {name: 'fwd_a', wave: 'xxx.2.0...', data: ['10']},
    {name: 'fwd_b', wave: 'xxx.2.0...', data: ['10']},
    {},
    {name: 'Note', wave: 'x...=.....', data: ['FWD']}
  ],
  config: { hscale: 2 },
  head: {
    text: 'Data Forwarding (EX→EX, no stall)',
    tick: 0
  },
  foot: {
    text: 'SUB uses ADD result via forwarding (fwd=10)'
  }
}
```

**说明：**
- Cycle 4: SUB 在 EX 阶段需要 ADD 的结果
- Forward unit 检测到 EX/MEM.rd == ID/EX.rs1/rs2
- 设置 fwd_a/fwd_b = 10，从 EX/MEM.alu_result 前递

---

## 5. JAL 指令（1 周期惩罚）

```wavedrom
{
  signal: [
    {name: 'clk', wave: 'p.........'},
    {},
    {name: 'IF', wave: 'x23.56789x', data: ['JAL','I2','T1','T2','T3','I6','I7']},
    {name: 'ID', wave: 'xx2.34567x', data: ['JAL','I2','T1','T2','T3','I6']},
    {name: 'EX', wave: 'xxx.23456x', data: ['JAL','NOP','T1','T2','T3']},
    {name: 'MEM', wave: 'xxxx.2345x', data: ['JAL','NOP','T1','T2']},
    {name: 'WB', wave: 'xxxxx.234x', data: ['JAL','NOP','T1']},
    {},
    {name: 'jal_id', wave: '0.10......'},
    {name: 'if_id_flush', wave: '0.10......'},
    {name: 'pc_sel', wave: '0.3.0.....', data: ['BR']},
    {},
    {name: 'Note', wave: 'x.=.......', data: ['FLUSH']}
  ],
  config: { hscale: 2 },
  head: {
    text: 'JAL Instruction (1-cycle penalty)',
    tick: 0
  }
}
```

**说明：**
- Cycle 2: JAL 在 ID 阶段解析目标地址
- Cycle 3: 冲刷 IF/ID（I2），从目标 T1 取指
- PC+4 写入 rd（返回地址）

---

## 6. JALR 指令（2 周期惩罚）

```wavedrom
{
  signal: [
    {name: 'clk', wave: 'p..........'},
    {},
    {name: 'IF', wave: 'x234..789x.', data: ['JALR','I2','I3','T1','T2','T3']},
    {name: 'ID', wave: 'xx23..4567.', data: ['JALR','I2','I3','T1','T2']},
    {name: 'EX', wave: 'xxx2..3456.', data: ['JALR','NOP','NOP','T1']},
    {name: 'MEM', wave: 'xxxx..2345.', data: ['JALR','NOP','NOP']},
    {name: 'WB', wave: 'xxxxx..234.', data: ['JALR','NOP']},
    {},
    {name: 'jalr_ex', wave: '0..10.....'},
    {name: 'if_id_flush', wave: '0..10.....'},
    {name: 'id_ex_flush', wave: '0..10.....'},
    {name: 'pc_sel', wave: '0..3.0....', data: ['JR']},
    {},
    {name: 'Note', wave: 'x..==.....', data: ['CALC','FLUSH']}
  ],
  config: { hscale: 2 },
  head: {
    text: 'JALR Instruction (2-cycle penalty)',
    tick: 0
  }
}
```

**说明：**
- Cycle 3: JALR 在 EX 阶段计算目标地址（rs1 + imm）
- Cycle 4-5: 冲刷 IF/ID 和 ID/EX（I2, I3）
- Cycle 6: 从计算的目标地址取指

---

## 7. 连续 Load 指令（无冒险）

```wavedrom
{
  signal: [
    {name: 'clk', wave: 'p.........'},
    {},
    {name: 'IF', wave: 'x23456789x', data: ['LW1','LW2','LW3','ADD','I5','I6','I7']},
    {name: 'ID', wave: 'xx2345678x', data: ['LW1','LW2','LW3','ADD','I5','I6']},
    {name: 'EX', wave: 'xxx234567x', data: ['LW1','LW2','LW3','ADD','I5']},
    {name: 'MEM', wave: 'xxxx23456x', data: ['LW1','LW2','LW3','ADD']},
    {name: 'WB', wave: 'xxxxx2345x', data: ['LW1','LW2','LW3']},
    {},
    {name: 'dmem_addr', wave: 'x...234...', data: ['A1','A2','A3']},
    {name: 'dmem_rdata', wave: 'x....234..', data: ['D1','D2','D3']},
    {},
    {name: 'Note', wave: 'x........x', data: []}
  ],
  config: { hscale: 2 },
  head: {
    text: 'Consecutive Loads (no hazard)',
    tick: 0
  }
}
```

**说明：**
- 连续的 Load 指令，目标寄存器不同
- 无数据冒险，流水线满载运行
- 每个 Load 在 MEM 阶段访问数据存储器

---

## 8. Store 指令时序

```wavedrom
{
  signal: [
    {name: 'clk', wave: 'p.........'},
    {},
    {name: 'IF', wave: 'x23456789x', data: ['ADD','SW','I3','I4','I5','I6','I7']},
    {name: 'ID', wave: 'xx2345678x', data: ['ADD','SW','I3','I4','I5','I6']},
    {name: 'EX', wave: 'xxx234567x', data: ['ADD','SW','I3','I4','I5']},
    {name: 'MEM', wave: 'xxxx23456x', data: ['ADD','SW','I3','I4']},
    {name: 'WB', wave: 'xxxxx2345x', data: ['ADD','SW','I3']},
    {},
    {name: 'fwd_b', wave: 'xxx.2.0...', data: ['10']},
    {name: 'dmem_addr', wave: 'x...x2....', data: ['A1']},
    {name: 'dmem_wdata', wave: 'x...x2....', data: ['D1']},
    {name: 'dmem_wen', wave: '0...10....'},
    {},
    {name: 'Note', wave: 'x...=.....', data: ['FWD']}
  ],
  config: { hscale: 2 },
  head: {
    text: 'Store with Forwarding',
    tick: 0
  }
}
```

**说明：**
- Cycle 4: SW 在 EX 阶段需要 ADD 的结果作为存储数据
- 通过 fwd_b 前递 ADD 的结果
- Cycle 5: 在 MEM 阶段写入数据存储器

---

## 9. 复杂冒险场景（Load-Use + 前递）

```wavedrom
{
  signal: [
    {name: 'clk', wave: 'p...........'},
    {},
    {name: 'IF', wave: 'x234.567.89x', data: ['LW','ADD','SUB','AND','OR','XOR']},
    {name: 'ID', wave: 'xx23.456.78x', data: ['LW','ADD','SUB','AND','OR']},
    {name: 'EX', wave: 'xxx2.345.67x', data: ['LW','NOP','ADD','SUB','AND']},
    {name: 'MEM', wave: 'xxxx.234.56x', data: ['LW','NOP','ADD','SUB']},
    {name: 'WB', wave: 'xxxxx.23.45x', data: ['LW','NOP','ADD']},
    {},
    {name: 'pc_stall', wave: '0...10......'},
    {name: 'id_ex_flush', wave: '0...10......'},
    {name: 'fwd_a', wave: 'xxx..2.0....', data: ['10']},
    {},
    {name: 'Note', wave: 'x...==......', data: ['STALL','FWD']}
  ],
  config: { hscale: 2 },
  head: {
    text: 'Load-Use Stall + Forwarding',
    tick: 0
  }
}
```

**说明：**
- Cycle 3: 检测 LW-ADD 冒险，停顿
- Cycle 4: 插入 bubble
- Cycle 5: ADD 使用前递的 LW 结果
- Cycle 6: SUB 使用前递的 ADD 结果（无停顿）

---

## 10. CSR 读写时序

```wavedrom
{
  signal: [
    {name: 'clk', wave: 'p.........'},
    {},
    {name: 'IF', wave: 'x23456789x', data: ['CSRRW','ADD','I3','I4','I5','I6','I7']},
    {name: 'ID', wave: 'xx2345678x', data: ['CSRRW','ADD','I3','I4','I5','I6']},
    {name: 'EX', wave: 'xxx234567x', data: ['CSRRW','ADD','I3','I4','I5']},
    {name: 'MEM', wave: 'xxxx23456x', data: ['CSRRW','ADD','I3','I4']},
    {name: 'WB', wave: 'xxxxx2345x', data: ['CSRRW','ADD','I3']},
    {},
    {name: 'csr_op', wave: 'x...2.0...', data: ['RW']},
    {name: 'csr_rdata', wave: 'x...2.....', data: ['OLD']},
    {name: 'csr_wdata', wave: 'x...2.....', data: ['NEW']},
    {name: 'wb_sel', wave: 'x...3.0...', data: ['CSR']},
    {},
    {name: 'Note', wave: 'x...=.....', data: ['CSR']}
  ],
  config: { hscale: 2 },
  head: {
    text: 'CSR Read/Write',
    tick: 0
  }
}
```

**说明：**
- Cycle 4: CSRRW 在 MEM 阶段读写 CSR
- 旧值通过 wb_sel=CSR 写回寄存器堆
- 新值同时写入 CSR

---

## 使用说明

### 在线查看
1. 访问 https://wavedrom.com/editor.html
2. 复制上面任意一个 JSON 代码块
3. 粘贴到编辑器查看波形

### 本地查看（需要 Node.js）
```bash
npm install -g wavedrom-cli
wavedrom-cli -i timing.json -s timing.svg
```

### 集成到文档
```html
<script src="https://wavedrom.com/skins/default.js" type="text/javascript"></script>
<script src="https://wavedrom.com/wavedrom.min.js" type="text/javascript"></script>
<script type="WaveDrom">
{ signal: [...] }
</script>
```

---

## 信号说明

| 信号 | 说明 |
|------|------|
| `IF/ID/EX/MEM/WB` | 各流水线阶段当前执行的指令 |
| `pc_stall` | PC 寄存器停顿信号 |
| `if_id_flush` | IF/ID 寄存器冲刷信号 |
| `id_ex_flush` | ID/EX 寄存器冲刷信号 |
| `branch_taken` | 分支判断结果 |
| `fwd_a/fwd_b` | 前递选择信号（00=无，01=MEM/WB，10=EX/MEM） |
| `pc_sel` | PC 源选择（0=PC+4，1=分支，2=JALR，3=trap） |

---

## 性能分析

| 场景 | CPI | 说明 |
|------|-----|------|
| 理想流水线 | 1.0 | 无冒险 |
| Load-Use | 2.0 | 1 周期停顿 |
| 分支误预测 | 3.0 | 2 周期惩罚 |
| JAL | 2.0 | 1 周期惩罚 |
| JALR | 3.0 | 2 周期惩罚 |
| 数据前递 | 1.0 | 无停顿 |

**典型程序 CPI ≈ 1.2-1.3**（假设 10% load-use，15% 分支，50% taken）
