// alu.sv — 32-bit ALU
// Supports: ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU, PASS_B

`include "riscv_pkg.sv"

module alu
  import riscv_pkg::*;
(
  input  logic [31:0] a,
  input  logic [31:0] b,
  input  alu_op_e     op,
  output logic [31:0] result
);

  always_comb begin
    unique case (op)
      ALU_ADD:    result = a + b;
      ALU_SUB:    result = a - b;
      ALU_AND:    result = a & b;
      ALU_OR:     result = a | b;
      ALU_XOR:    result = a ^ b;
      ALU_SLL:    result = a << b[4:0];
      ALU_SRL:    result = a >> b[4:0];
      ALU_SRA:    result = $signed(a) >>> b[4:0];
      ALU_SLT:    result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
      ALU_SLTU:   result = (a < b)                   ? 32'd1 : 32'd0;
      ALU_PASS_B: result = b;
      default:    result = 32'h0;
    endcase
  end

endmodule
