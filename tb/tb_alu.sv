// tb_alu.sv — ALU unit test
// Tests all 11 ALU operations

`include "riscv_pkg.sv"

module tb_alu;

  import riscv_pkg::*;

  logic [31:0] a, b, result;
  alu_op_e     op;

  alu dut (
    .a      (a),
    .b      (b),
    .op     (op),
    .result (result)
  );

  initial begin
    $display("=== ALU Unit Test ===");

    // ADD
    a = 32'd10; b = 32'd20; op = ALU_ADD;
    #1; assert(result == 32'd30) else $error("ADD failed");
    $display("ADD: %0d + %0d = %0d", a, b, result);

    // SUB
    a = 32'd50; b = 32'd20; op = ALU_SUB;
    #1; assert(result == 32'd30) else $error("SUB failed");
    $display("SUB: %0d - %0d = %0d", a, b, result);

    // AND
    a = 32'hF0F0; b = 32'hFF00; op = ALU_AND;
    #1; assert(result == 32'hF000) else $error("AND failed");
    $display("AND: 0x%h & 0x%h = 0x%h", a, b, result);

    // OR
    a = 32'hF0F0; b = 32'h0F0F; op = ALU_OR;
    #1; assert(result == 32'hFFFF) else $error("OR failed");
    $display("OR: 0x%h | 0x%h = 0x%h", a, b, result);

    // XOR
    a = 32'hFFFF; b = 32'hF0F0; op = ALU_XOR;
    #1; assert(result == 32'h0F0F) else $error("XOR failed");
    $display("XOR: 0x%h ^ 0x%h = 0x%h", a, b, result);

    // SLL
    a = 32'd1; b = 32'd4; op = ALU_SLL;
    #1; assert(result == 32'd16) else $error("SLL failed");
    $display("SLL: %0d << %0d = %0d", a, b, result);

    // SRL
    a = 32'd16; b = 32'd2; op = ALU_SRL;
    #1; assert(result == 32'd4) else $error("SRL failed");
    $display("SRL: %0d >> %0d = %0d", a, b, result);

    // SRA
    a = 32'hFFFF_FFF0; b = 32'd2; op = ALU_SRA;
    #1; assert(result == 32'hFFFF_FFFC) else $error("SRA failed");
    $display("SRA: 0x%h >>> %0d = 0x%h", a, b, result);

    // SLT
    a = -32'd10; b = 32'd5; op = ALU_SLT;
    #1; assert(result == 32'd1) else $error("SLT failed");
    $display("SLT: %0d < %0d = %0d", $signed(a), $signed(b), result);

    // SLTU
    a = 32'd5; b = 32'd10; op = ALU_SLTU;
    #1; assert(result == 32'd1) else $error("SLTU failed");
    $display("SLTU: %0d < %0d = %0d", a, b, result);

    // PASS_B
    a = 32'hDEAD; b = 32'hBEEF; op = ALU_PASS_B;
    #1; assert(result == 32'hBEEF) else $error("PASS_B failed");
    $display("PASS_B: b = 0x%h", result);

    $display("=== All ALU tests passed ===");
    $finish;
  end

endmodule
