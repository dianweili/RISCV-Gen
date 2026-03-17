// id_stage.sv — Instruction Decode stage
// Decodes instruction, generates control signals, reads register file

`include "riscv_pkg.sv"
`include "pipeline_pkg.sv"

module id_stage
  import riscv_pkg::*;
  import pipeline_pkg::*;
(
  input  logic        clk,
  input  logic [31:0] inst,
  input  logic [31:0] pc,

  // Register file interface
  output logic [4:0]  rs1_addr,
  output logic [4:0]  rs2_addr,
  input  logic [31:0] rs1_data,
  input  logic [31:0] rs2_data,

  // Decoded outputs
  output logic [31:0] imm,
  output logic [4:0]  rd_addr,
  output alu_op_e     alu_op,
  output srca_sel_e   srca_sel,
  output srcb_sel_e   srcb_sel,
  output wb_sel_e     wb_sel,
  output logic        reg_wen,
  output logic        mem_ren,
  output logic        mem_wen,
  output mem_width_e  mem_width,
  output pc_sel_e     pc_sel_hint,  // hint for JAL (resolved in ID)
  output csr_op_e     csr_op,
  output logic [11:0] csr_addr,
  output logic        jal_id        // JAL detected in ID
);

  logic [6:0] opcode;
  logic [2:0] funct3;
  logic [6:0] funct7;

  assign opcode = inst[6:0];
  assign funct3 = inst[14:12];
  assign funct7 = inst[31:25];
  assign rd_addr  = inst[11:7];
  assign rs1_addr = inst[19:15];
  assign rs2_addr = inst[24:20];
  assign csr_addr = inst[31:20];

  // -----------------------------------------------------------------------
  // Immediate generation
  // -----------------------------------------------------------------------
  always_comb begin
    unique case (opcode)
      OP_LUI, OP_AUIPC:
        imm = {inst[31:12], 12'h0};  // U-type
      OP_JAL:
        imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};  // J-type
      OP_JALR, OP_LOAD, OP_IMM:
        imm = {{20{inst[31]}}, inst[31:20]};  // I-type
      OP_BRANCH:
        imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};  // B-type
      OP_STORE:
        imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};  // S-type
      default:
        imm = 32'h0;
    endcase
  end

  // -----------------------------------------------------------------------
  // Control signal generation
  // -----------------------------------------------------------------------
  always_comb begin
    // Defaults
    alu_op      = ALU_ADD;
    srca_sel    = SRCA_RS1;
    srcb_sel    = SRCB_RS2;
    wb_sel      = WB_ALU;
    reg_wen     = 1'b0;
    mem_ren     = 1'b0;
    mem_wen     = 1'b0;
    mem_width   = MEM_WORD;
    pc_sel_hint = PC_PLUS4;
    csr_op      = CSR_NONE;
    jal_id      = 1'b0;

    unique case (opcode)
      OP_LUI: begin
        alu_op   = ALU_PASS_B;
        srcb_sel = SRCB_IMM;
        wb_sel   = WB_ALU;
        reg_wen  = 1'b1;
      end

      OP_AUIPC: begin
        alu_op   = ALU_ADD;
        srca_sel = SRCA_PC;
        srcb_sel = SRCB_IMM;
        wb_sel   = WB_ALU;
        reg_wen  = 1'b1;
      end

      OP_JAL: begin
        alu_op      = ALU_ADD;
        srca_sel    = SRCA_PC;
        srcb_sel    = SRCB_IMM;
        wb_sel      = WB_PC4;
        reg_wen     = 1'b1;
        pc_sel_hint = PC_BRANCH;  // JAL resolved in ID
        jal_id      = 1'b1;
      end

      OP_JALR: begin
        alu_op   = ALU_ADD;
        srca_sel = SRCA_RS1;
        srcb_sel = SRCB_IMM;
        wb_sel   = WB_PC4;
        reg_wen  = 1'b1;
        // JALR resolved in EX, pc_sel set there
      end

      OP_BRANCH: begin
        alu_op   = ALU_ADD;
        srca_sel = SRCA_PC;
        srcb_sel = SRCB_IMM;
        // Branch resolved in EX
      end

      OP_LOAD: begin
        alu_op   = ALU_ADD;
        srca_sel = SRCA_RS1;
        srcb_sel = SRCB_IMM;
        wb_sel   = WB_MEM;
        reg_wen  = 1'b1;
        mem_ren  = 1'b1;
        unique case (funct3)
          F3_LB:  mem_width = MEM_BYTE;
          F3_LH:  mem_width = MEM_HALF;
          F3_LW:  mem_width = MEM_WORD;
          F3_LBU: mem_width = MEM_BYTEU;
          F3_LHU: mem_width = MEM_HALFU;
          default: mem_width = MEM_WORD;
        endcase
      end

      OP_STORE: begin
        alu_op   = ALU_ADD;
        srca_sel = SRCA_RS1;
        srcb_sel = SRCB_IMM;
        mem_wen  = 1'b1;
        unique case (funct3)
          F3_SB: mem_width = MEM_BYTE;
          F3_SH: mem_width = MEM_HALF;
          F3_SW: mem_width = MEM_WORD;
          default: mem_width = MEM_WORD;
        endcase
      end

      OP_IMM: begin
        srca_sel = SRCA_RS1;
        srcb_sel = SRCB_IMM;
        wb_sel   = WB_ALU;
        reg_wen  = 1'b1;
        unique case (funct3)
          F3_ADD_SUB: alu_op = ALU_ADD;
          F3_SLL:     alu_op = ALU_SLL;
          F3_SLT:     alu_op = ALU_SLT;
          F3_SLTU:    alu_op = ALU_SLTU;
          F3_XOR:     alu_op = ALU_XOR;
          F3_SRL_SRA: alu_op = (funct7[5]) ? ALU_SRA : ALU_SRL;
          F3_OR:      alu_op = ALU_OR;
          F3_AND:     alu_op = ALU_AND;
          default:    alu_op = ALU_ADD;
        endcase
      end

      OP_REG: begin
        srca_sel = SRCA_RS1;
        srcb_sel = SRCB_RS2;
        wb_sel   = WB_ALU;
        reg_wen  = 1'b1;
        unique case (funct3)
          F3_ADD_SUB: alu_op = (funct7[5]) ? ALU_SUB : ALU_ADD;
          F3_SLL:     alu_op = ALU_SLL;
          F3_SLT:     alu_op = ALU_SLT;
          F3_SLTU:    alu_op = ALU_SLTU;
          F3_XOR:     alu_op = ALU_XOR;
          F3_SRL_SRA: alu_op = (funct7[5]) ? ALU_SRA : ALU_SRL;
          F3_OR:      alu_op = ALU_OR;
          F3_AND:     alu_op = ALU_AND;
          default:    alu_op = ALU_ADD;
        endcase
      end

      OP_SYSTEM: begin
        // CSR instructions
        if (funct3 != 3'b000) begin
          wb_sel = WB_CSR;
          reg_wen = 1'b1;
          unique case (funct3)
            F3_CSRRW:  csr_op = CSR_RW;
            F3_CSRRS:  csr_op = CSR_RS;
            F3_CSRRC:  csr_op = CSR_RC;
            F3_CSRRWI: csr_op = CSR_RWI;
            F3_CSRRSI: csr_op = CSR_RSI;
            F3_CSRRCI: csr_op = CSR_RCI;
            default:   csr_op = CSR_NONE;
          endcase
        end
        // ECALL/EBREAK/MRET handled in EX stage
      end

      default: begin
        // NOP or illegal instruction
      end
    endcase
  end

endmodule
