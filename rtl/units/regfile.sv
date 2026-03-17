// regfile.sv — 32×32 register file
// 2 asynchronous read ports, 1 synchronous write port
// x0 is hardwired to zero

module regfile (
  input  logic        clk,
  // Read port A
  input  logic [4:0]  rs1_addr,
  output logic [31:0] rs1_data,
  // Read port B
  input  logic [4:0]  rs2_addr,
  output logic [31:0] rs2_data,
  // Write port
  input  logic [4:0]  rd_addr,
  input  logic [31:0] rd_data,
  input  logic        wen
);

  logic [31:0] regs [0:31];

  // Synchronous write; x0 is never written
  always_ff @(posedge clk) begin
    if (wen && rd_addr != 5'h0)
      regs[rd_addr] <= rd_data;
  end

  // Asynchronous read; x0 always returns 0
  assign rs1_data = (rs1_addr == 5'h0) ? 32'h0 : regs[rs1_addr];
  assign rs2_data = (rs2_addr == 5'h0) ? 32'h0 : regs[rs2_addr];

  // Initialize all registers to 0 for simulation
  initial begin
    for (int i = 0; i < 32; i++)
      regs[i] = 32'h0;
  end

endmodule
