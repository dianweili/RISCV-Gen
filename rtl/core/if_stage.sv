// if_stage.sv — Instruction Fetch stage
// Fetches instruction from imem, manages PC register

`include "riscv_pkg.sv"

module if_stage
  import riscv_pkg::*;
(
  input  logic        clk,
  input  logic        rst_n,

  // PC control
  input  logic        pc_stall,
  input  pc_sel_e     pc_sel,
  input  logic [31:0] branch_target,
  input  logic [31:0] jalr_target,
  input  logic [31:0] trap_target,

  // Instruction memory interface
  output logic [31:0] imem_addr,
  input  logic [31:0] imem_rdata,

  // Outputs to IF/ID register
  output logic [31:0] pc_out,
  output logic [31:0] inst_out
);

  logic [31:0] pc_reg;
  logic [31:0] pc_next;

  // PC selection mux
  always_comb begin
    unique case (pc_sel)
      PC_PLUS4:  pc_next = pc_reg + 32'd4;
      PC_BRANCH: pc_next = branch_target;
      PC_JALR:   pc_next = jalr_target;
      PC_TRAP:   pc_next = trap_target;
      default:   pc_next = pc_reg + 32'd4;
    endcase
  end

  // PC register
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      pc_reg <= RESET_PC;
    else if (!pc_stall)
      pc_reg <= pc_next;
  end

  // Instruction memory access
  assign imem_addr = pc_reg;
  assign inst_out  = imem_rdata;
  assign pc_out    = pc_reg;

endmodule
