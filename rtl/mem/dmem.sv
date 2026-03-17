// dmem.sv — Data memory (behavioral model)
// Single-port synchronous read/write with byte enables

module dmem #(
  parameter DEPTH = 4096  // 16KB (4K words)
)(
  input  logic        clk,
  input  logic [31:0] addr,
  input  logic [31:0] wdata,
  input  logic [3:0]  wen,   // byte write enable
  output logic [31:0] rdata
);

  logic [31:0] mem [0:DEPTH-1];

  // Word-aligned address
  logic [$clog2(DEPTH)-1:0] word_addr;
  assign word_addr = addr[$clog2(DEPTH)+1:2];

  // Synchronous write with byte enables
  always_ff @(posedge clk) begin
    if (wen[0]) mem[word_addr][7:0]   <= wdata[7:0];
    if (wen[1]) mem[word_addr][15:8]  <= wdata[15:8];
    if (wen[2]) mem[word_addr][23:16] <= wdata[23:16];
    if (wen[3]) mem[word_addr][31:24] <= wdata[31:24];
  end

  // Synchronous read
  always_ff @(posedge clk) begin
    rdata <= mem[word_addr];
  end

  // Initialize to zero
  initial begin
    for (int i = 0; i < DEPTH; i++)
      mem[i] = 32'h0;
  end

endmodule
