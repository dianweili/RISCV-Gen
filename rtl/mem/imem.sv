// imem.sv — Instruction memory (behavioral model)
// Single-port synchronous read, initialized from hex file

module imem #(
  parameter DEPTH = 4096,  // 16KB (4K words)
  parameter INIT_FILE = ""
)(
  input  logic        clk,
  input  logic [31:0] addr,
  output logic [31:0] rdata
);

  logic [31:0] mem [0:DEPTH-1];

  // Word-aligned address
  logic [$clog2(DEPTH)-1:0] word_addr;
  assign word_addr = addr[$clog2(DEPTH)+1:2];

  // Synchronous read
  always_ff @(posedge clk) begin
    rdata <= mem[word_addr];
  end

  // Initialize from hex file
  initial begin
    if (INIT_FILE != "") begin
      $readmemh(INIT_FILE, mem);
    end else begin
      for (int i = 0; i < DEPTH; i++)
        mem[i] = 32'h0000_0013;  // NOP
    end
  end

endmodule
