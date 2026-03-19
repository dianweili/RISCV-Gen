// ex_stage.sv — Execute stage
// Performs ALU operations, branch resolution, data forwarding

`include "riscv_pkg.sv"

module ex_stage
  import riscv_pkg::*;
(
  input  logic [31:0] pc,
  input  logic [31:0] pc_plus4,
  input  logic [31:0] rs1_data,
  input  logic [31:0] rs2_data,
  input  logic [31:0] imm,
  input  alu_op_e     alu_op,
  input  srca_sel_e   srca_sel,
  input  srcb_sel_e   srcb_sel,
  input  logic [2:0]  funct3,
  input  logic [6:0]  opcode,

  // Forwarding inputs
  input  logic [1:0]  fwd_a,
  input  logic [1:0]  fwd_b,
  input  logic [31:0] ex_mem_alu_result,
  input  logic [31:0] mem_wb_wb_data,

  // Outputs
  output logic [31:0] alu_result,
  output logic [31:0] rs2_data_fwd,  // forwarded rs2 for store
  output logic [31:0] branch_target,
  output logic [31:0] jalr_target,
  output logic        branch_taken,
  output logic        jalr_ex
);

  logic [31:0] alu_a, alu_b;
  logic [31:0] rs1_fwd, rs2_fwd;
  logic [31:0] jalr_sum;

  // -----------------------------------------------------------------------
  // Data forwarding muxes
  // -----------------------------------------------------------------------
  always_comb begin
    unique case (fwd_a)
      2'b00:   rs1_fwd = rs1_data;
      2'b01:   rs1_fwd = mem_wb_wb_data;
      2'b10:   rs1_fwd = ex_mem_alu_result;
      default: rs1_fwd = rs1_data;
    endcase
  end

  always_comb begin
    unique case (fwd_b)
      2'b00:   rs2_fwd = rs2_data;
      2'b01:   rs2_fwd = mem_wb_wb_data;
      2'b10:   rs2_fwd = ex_mem_alu_result;
      default: rs2_fwd = rs2_data;
    endcase
  end

  assign rs2_data_fwd = rs2_fwd;

  // -----------------------------------------------------------------------
  // ALU source selection
  // -----------------------------------------------------------------------
  always_comb begin
    unique case (srca_sel)
      SRCA_RS1:  alu_a = rs1_fwd;
      SRCA_PC:   alu_a = pc;
      SRCA_ZERO: alu_a = 32'h0;
      default:   alu_a = rs1_fwd;
    endcase
  end

  always_comb begin
    unique case (srcb_sel)
      SRCB_RS2: alu_b = rs2_fwd;
      SRCB_IMM: alu_b = imm;
      default:  alu_b = rs2_fwd;
    endcase
  end

  // -----------------------------------------------------------------------
  // ALU instantiation
  // -----------------------------------------------------------------------
  alu u_alu (
    .a      (alu_a),
    .b      (alu_b),
    .op     (alu_op),
    .result (alu_result)
  );

  // -----------------------------------------------------------------------
  // Branch resolution
  // -----------------------------------------------------------------------
  logic branch_cond;

  branch_comp u_branch_comp (
    .rs1    (rs1_fwd),
    .rs2    (rs2_fwd),
    .funct3 (funct3),
    .taken  (branch_cond)
  );

  assign branch_taken  = (opcode == OP_BRANCH) && branch_cond;
  assign branch_target = pc + imm;

  // -----------------------------------------------------------------------
  // JALR resolution
  // -----------------------------------------------------------------------
  assign jalr_ex     = (opcode == OP_JALR);
  assign jalr_sum    = rs1_fwd + imm;
  assign jalr_target = {jalr_sum[31:1], 1'b0};  // clear LSB

endmodule
