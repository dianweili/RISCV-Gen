// forward_unit.sv — Data forwarding selection logic
// Generates forwarding mux selects for EX stage operands

module forward_unit (
  // ID/EX register source addresses
  input  logic [4:0]  id_ex_rs1,
  input  logic [4:0]  id_ex_rs2,
  // EX/MEM destination (one stage ahead)
  input  logic [4:0]  ex_mem_rd,
  input  logic        ex_mem_reg_wen,
  // MEM/WB destination (two stages ahead)
  input  logic [4:0]  mem_wb_rd,
  input  logic        mem_wb_reg_wen,
  // Forward select outputs
  // 00 = no forward (use register file)
  // 01 = forward from MEM/WB
  // 10 = forward from EX/MEM
  output logic [1:0]  fwd_a,
  output logic [1:0]  fwd_b
);

  // Forward A (rs1)
  always_comb begin
    if (ex_mem_reg_wen && (ex_mem_rd != 5'h0) && (ex_mem_rd == id_ex_rs1))
      fwd_a = 2'b10;  // EX/MEM forward
    else if (mem_wb_reg_wen && (mem_wb_rd != 5'h0) && (mem_wb_rd == id_ex_rs1))
      fwd_a = 2'b01;  // MEM/WB forward
    else
      fwd_a = 2'b00;  // No forward
  end

  // Forward B (rs2)
  always_comb begin
    if (ex_mem_reg_wen && (ex_mem_rd != 5'h0) && (ex_mem_rd == id_ex_rs2))
      fwd_b = 2'b10;  // EX/MEM forward
    else if (mem_wb_reg_wen && (mem_wb_rd != 5'h0) && (mem_wb_rd == id_ex_rs2))
      fwd_b = 2'b01;  // MEM/WB forward
    else
      fwd_b = 2'b00;  // No forward
  end

endmodule
