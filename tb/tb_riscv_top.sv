// tb_riscv_top.sv — Top-level SystemVerilog testbench
// Drives clock/reset, loads hex program, monitors execution

`include "riscv_pkg.sv"

module tb_riscv_top;

  import riscv_pkg::*;

  // -----------------------------------------------------------------------
  // Parameters
  // -----------------------------------------------------------------------
  parameter CLK_PERIOD = 10;  // 100 MHz for simulation
  parameter MAX_CYCLES = 100000;
  parameter PASS_ADDR  = 32'h0000_0100;  // address to write PASS signature
  parameter PASS_VALUE = 32'hDEAD_BEEF;

  // -----------------------------------------------------------------------
  // DUT signals
  // -----------------------------------------------------------------------
  logic clk, rst_n;

  // -----------------------------------------------------------------------
  // DUT instantiation
  // -----------------------------------------------------------------------
  riscv_top #(
    .IMEM_DEPTH (4096),
    .DMEM_DEPTH (4096)
  ) dut (
    .clk   (clk),
    .rst_n (rst_n)
  );

  // Hex file parameter (override from command line: +hex=<file>)
  string HEX_FILE;
  initial begin
    #1;  // ensure imem default init completes first
    if ($value$plusargs("hex=%s", HEX_FILE))
      $readmemh(HEX_FILE, dut.u_imem.mem);
  end

  // -----------------------------------------------------------------------
  // Clock generation
  // -----------------------------------------------------------------------
  initial clk = 0;
  always #(CLK_PERIOD/2) clk = ~clk;

  // -----------------------------------------------------------------------
  // Reset sequence
  // -----------------------------------------------------------------------
  initial begin
    rst_n = 0;
    repeat(5) @(posedge clk);
    @(negedge clk);
    rst_n = 1;
  end

  // -----------------------------------------------------------------------
  // Simulation control
  // -----------------------------------------------------------------------
  int cycle_count;
  logic test_pass, test_fail;

  initial begin
    cycle_count = 0;
    test_pass   = 0;
    test_fail   = 0;

    // Wait for reset
    @(posedge rst_n);

    // Run until pass/fail or timeout
    fork
      begin : monitor
        forever begin
          @(posedge clk);
          cycle_count++;

          // Check for PASS signature in data memory
          if (dut.u_dmem.mem[PASS_ADDR >> 2] == PASS_VALUE) begin
            $display("[PASS] Test passed at cycle %0d", cycle_count);
            test_pass = 1;
            disable monitor;
          end

          // Timeout
          if (cycle_count >= MAX_CYCLES) begin
            $display("[FAIL] Timeout after %0d cycles", MAX_CYCLES);
            test_fail = 1;
            disable monitor;
          end
        end
      end
    join

    // Dump final register state
    $display("--- Register File Dump ---");
    for (int i = 0; i < 32; i++) begin
      if (dut.u_regfile.regs[i] != 0)
        $display("  x%0d = 0x%08h", i, dut.u_regfile.regs[i]);
    end

    $finish;
  end

  // -----------------------------------------------------------------------
  // Waveform dump
  // -----------------------------------------------------------------------
  initial begin
    $dumpfile("sim_riscv.vcd");
    $dumpvars(0, tb_riscv_top);
  end

endmodule
