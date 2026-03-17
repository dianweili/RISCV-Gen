// tb_regfile.sv — Register file unit test
// Tests read/write operations and x0 hardwiring

module tb_regfile;

  logic        clk;
  logic [4:0]  rs1_addr, rs2_addr, rd_addr;
  logic [31:0] rs1_data, rs2_data, rd_data;
  logic        wen;

  regfile dut (
    .clk      (clk),
    .rs1_addr (rs1_addr),
    .rs1_data (rs1_data),
    .rs2_addr (rs2_addr),
    .rs2_data (rs2_data),
    .rd_addr  (rd_addr),
    .rd_data  (rd_data),
    .wen      (wen)
  );

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $display("=== Register File Unit Test ===");

    wen = 0;
    @(posedge clk);

    // Write to x1
    rd_addr = 5'd1; rd_data = 32'hDEAD_BEEF; wen = 1;
    @(posedge clk);
    wen = 0;

    // Read from x1
    rs1_addr = 5'd1;
    #1;
    assert(rs1_data == 32'hDEAD_BEEF) else $error("Read x1 failed");
    $display("x1 = 0x%h (expected 0xDEADBEEF)", rs1_data);

    // Write to x0 (should be ignored)
    rd_addr = 5'd0; rd_data = 32'hBAD_BAD; wen = 1;
    @(posedge clk);
    wen = 0;

    // Read from x0 (should always be 0)
    rs1_addr = 5'd0;
    #1;
    assert(rs1_data == 32'h0) else $error("x0 not hardwired to 0");
    $display("x0 = 0x%h (expected 0x00000000)", rs1_data);

    // Write to x31
    rd_addr = 5'd31; rd_data = 32'h1234_5678; wen = 1;
    @(posedge clk);
    wen = 0;

    // Dual read
    rs1_addr = 5'd1; rs2_addr = 5'd31;
    #1;
    assert(rs1_data == 32'hDEAD_BEEF) else $error("Dual read rs1 failed");
    assert(rs2_data == 32'h1234_5678) else $error("Dual read rs2 failed");
    $display("x1 = 0x%h, x31 = 0x%h", rs1_data, rs2_data);

    $display("=== All register file tests passed ===");
    $finish;
  end

endmodule
