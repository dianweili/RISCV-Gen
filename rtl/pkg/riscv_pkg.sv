// riscv_pkg.sv — ISA constants, opcodes, and control signal enumerations
// RISC-V RV32I 5-Stage Pipeline Processor

`ifndef RISCV_PKG_SV
`define RISCV_PKG_SV

package riscv_pkg;

  // -----------------------------------------------------------------------
  // Opcode definitions (bits [6:0])
  // -----------------------------------------------------------------------
  localparam logic [6:0] OP_LUI    = 7'b0110111;
  localparam logic [6:0] OP_AUIPC  = 7'b0010111;
  localparam logic [6:0] OP_JAL    = 7'b1101111;
  localparam logic [6:0] OP_JALR   = 7'b1100111;
  localparam logic [6:0] OP_BRANCH = 7'b1100011;
  localparam logic [6:0] OP_LOAD   = 7'b0000011;
  localparam logic [6:0] OP_STORE  = 7'b0100011;
  localparam logic [6:0] OP_IMM    = 7'b0010011;
  localparam logic [6:0] OP_REG    = 7'b0110011;
  localparam logic [6:0] OP_FENCE  = 7'b0001111;
  localparam logic [6:0] OP_SYSTEM = 7'b1110011;

  // -----------------------------------------------------------------------
  // funct3 encodings
  // -----------------------------------------------------------------------
  // Branch
  localparam logic [2:0] F3_BEQ  = 3'b000;
  localparam logic [2:0] F3_BNE  = 3'b001;
  localparam logic [2:0] F3_BLT  = 3'b100;
  localparam logic [2:0] F3_BGE  = 3'b101;
  localparam logic [2:0] F3_BLTU = 3'b110;
  localparam logic [2:0] F3_BGEU = 3'b111;

  // Load/Store
  localparam logic [2:0] F3_LB  = 3'b000;
  localparam logic [2:0] F3_LH  = 3'b001;
  localparam logic [2:0] F3_LW  = 3'b010;
  localparam logic [2:0] F3_LBU = 3'b100;
  localparam logic [2:0] F3_LHU = 3'b101;
  localparam logic [2:0] F3_SB  = 3'b000;
  localparam logic [2:0] F3_SH  = 3'b001;
  localparam logic [2:0] F3_SW  = 3'b010;

  // ALU / immediate
  localparam logic [2:0] F3_ADD_SUB = 3'b000;
  localparam logic [2:0] F3_SLL     = 3'b001;
  localparam logic [2:0] F3_SLT     = 3'b010;
  localparam logic [2:0] F3_SLTU    = 3'b011;
  localparam logic [2:0] F3_XOR     = 3'b100;
  localparam logic [2:0] F3_SRL_SRA = 3'b101;
  localparam logic [2:0] F3_OR      = 3'b110;
  localparam logic [2:0] F3_AND     = 3'b111;

  // CSR
  localparam logic [2:0] F3_CSRRW  = 3'b001;
  localparam logic [2:0] F3_CSRRS  = 3'b010;
  localparam logic [2:0] F3_CSRRC  = 3'b011;
  localparam logic [2:0] F3_CSRRWI = 3'b101;
  localparam logic [2:0] F3_CSRRSI = 3'b110;
  localparam logic [2:0] F3_CSRRCI = 3'b111;

  // funct7
  localparam logic [6:0] F7_NORMAL = 7'b0000000;
  localparam logic [6:0] F7_ALT    = 7'b0100000;  // SUB, SRA

  // -----------------------------------------------------------------------
  // ALU operation encoding (4-bit)
  // -----------------------------------------------------------------------
  typedef enum logic [3:0] {
    ALU_ADD    = 4'b0000,
    ALU_SUB    = 4'b0001,
    ALU_AND    = 4'b0010,
    ALU_OR     = 4'b0011,
    ALU_XOR    = 4'b0100,
    ALU_SLL    = 4'b0101,
    ALU_SRL    = 4'b0110,
    ALU_SRA    = 4'b0111,
    ALU_SLT    = 4'b1000,
    ALU_SLTU   = 4'b1001,
    ALU_PASS_B = 4'b1010
  } alu_op_e;

  // -----------------------------------------------------------------------
  // Write-back source select (2-bit)
  // -----------------------------------------------------------------------
  typedef enum logic [1:0] {
    WB_ALU  = 2'b00,
    WB_MEM  = 2'b01,
    WB_PC4  = 2'b10,
    WB_CSR  = 2'b11
  } wb_sel_e;

  // -----------------------------------------------------------------------
  // ALU source A select
  // -----------------------------------------------------------------------
  typedef enum logic [1:0] {
    SRCA_RS1  = 2'b00,
    SRCA_PC   = 2'b01,
    SRCA_ZERO = 2'b10
  } srca_sel_e;

  // -----------------------------------------------------------------------
  // ALU source B select
  // -----------------------------------------------------------------------
  typedef enum logic [0:0] {
    SRCB_RS2 = 1'b0,
    SRCB_IMM = 1'b1
  } srcb_sel_e;

  // -----------------------------------------------------------------------
  // Memory access width
  // -----------------------------------------------------------------------
  typedef enum logic [2:0] {
    MEM_BYTE  = 3'b000,
    MEM_HALF  = 3'b001,
    MEM_WORD  = 3'b010,
    MEM_BYTEU = 3'b100,
    MEM_HALFU = 3'b101
  } mem_width_e;

  // -----------------------------------------------------------------------
  // PC source select
  // -----------------------------------------------------------------------
  typedef enum logic [1:0] {
    PC_PLUS4  = 2'b00,
    PC_BRANCH = 2'b01,
    PC_JALR   = 2'b10,
    PC_TRAP   = 2'b11
  } pc_sel_e;

  // -----------------------------------------------------------------------
  // CSR operation
  // -----------------------------------------------------------------------
  typedef enum logic [2:0] {
    CSR_NONE  = 3'b000,
    CSR_RW    = 3'b001,
    CSR_RS    = 3'b010,
    CSR_RC    = 3'b011,
    CSR_RWI   = 3'b101,
    CSR_RSI   = 3'b110,
    CSR_RCI   = 3'b111
  } csr_op_e;

  // -----------------------------------------------------------------------
  // CSR addresses
  // -----------------------------------------------------------------------
  localparam logic [11:0] CSR_MSTATUS = 12'h300;
  localparam logic [11:0] CSR_MTVEC   = 12'h305;
  localparam logic [11:0] CSR_MEPC    = 12'h341;
  localparam logic [11:0] CSR_MCAUSE  = 12'h342;
  localparam logic [11:0] CSR_MTVAL   = 12'h343;
  localparam logic [11:0] CSR_MISA    = 12'h301;
  localparam logic [11:0] CSR_MHARTID = 12'hF14;

  // -----------------------------------------------------------------------
  // Exception / interrupt cause codes
  // -----------------------------------------------------------------------
  localparam logic [31:0] CAUSE_ILLEGAL_INST  = 32'd2;
  localparam logic [31:0] CAUSE_BREAKPOINT    = 32'd3;
  localparam logic [31:0] CAUSE_LOAD_MISALIGN = 32'd4;
  localparam logic [31:0] CAUSE_STORE_MISALIGN= 32'd6;
  localparam logic [31:0] CAUSE_ECALL_M       = 32'd11;

  // -----------------------------------------------------------------------
  // Misc constants
  // -----------------------------------------------------------------------
  localparam logic [31:0] RESET_PC = 32'h0000_0000;
  localparam int          XLEN     = 32;
  localparam int          REG_NUM  = 32;

endpackage

`endif // RISCV_PKG_SV
