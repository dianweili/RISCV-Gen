// branch_comp.sv — Branch condition evaluator
// Evaluates BEQ, BNE, BLT, BGE, BLTU, BGEU based on funct3

`include "riscv_pkg.sv"

module branch_comp
  import riscv_pkg::*;
(
  input  logic [31:0] rs1,
  input  logic [31:0] rs2,
  input  logic [2:0]  funct3,
  output logic        taken
);

  always_comb begin
    unique case (funct3)
      F3_BEQ:  taken = (rs1 == rs2);
      F3_BNE:  taken = (rs1 != rs2);
      F3_BLT:  taken = ($signed(rs1) < $signed(rs2));
      F3_BGE:  taken = ($signed(rs1) >= $signed(rs2));
      F3_BLTU: taken = (rs1 < rs2);
      F3_BGEU: taken = (rs1 >= rs2);
      default: taken = 1'b0;
    endcase
  end

endmodule
