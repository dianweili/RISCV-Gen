// mem_stage.sv — Memory Access stage
// Handles data memory read/write with byte/halfword alignment

`include "riscv_pkg.sv"

module mem_stage
  import riscv_pkg::*;
(
  input  logic [31:0]  alu_result,
  input  logic [31:0]  rs2_data,
  input  logic         mem_ren,
  input  logic         mem_wen,
  input  mem_width_e   mem_width,

  // Data memory interface
  output logic [31:0]  dmem_addr,
  output logic [31:0]  dmem_wdata,
  output logic [3:0]   dmem_wen_byte,
  input  logic [31:0]  dmem_rdata,

  // Output
  output logic [31:0]  load_data
);

  logic [1:0] byte_offset;
  assign byte_offset = alu_result[1:0];
  assign dmem_addr   = {alu_result[31:2], 2'b00};  // word-aligned address

  // -----------------------------------------------------------------------
  // Store data alignment and byte enable
  // -----------------------------------------------------------------------
  always_comb begin
    dmem_wdata    = 32'h0;
    dmem_wen_byte = 4'b0000;

    if (mem_wen) begin
      unique case (mem_width)
        MEM_BYTE: begin
          unique case (byte_offset)
            2'b00: begin dmem_wdata = {24'h0, rs2_data[7:0]};       dmem_wen_byte = 4'b0001; end
            2'b01: begin dmem_wdata = {16'h0, rs2_data[7:0], 8'h0}; dmem_wen_byte = 4'b0010; end
            2'b10: begin dmem_wdata = {8'h0, rs2_data[7:0], 16'h0}; dmem_wen_byte = 4'b0100; end
            2'b11: begin dmem_wdata = {rs2_data[7:0], 24'h0};       dmem_wen_byte = 4'b1000; end
          endcase
        end

        MEM_HALF: begin
          unique case (byte_offset[1])
            1'b0: begin dmem_wdata = {16'h0, rs2_data[15:0]};       dmem_wen_byte = 4'b0011; end
            1'b1: begin dmem_wdata = {rs2_data[15:0], 16'h0};       dmem_wen_byte = 4'b1100; end
          endcase
        end

        MEM_WORD: begin
          dmem_wdata    = rs2_data;
          dmem_wen_byte = 4'b1111;
        end

        default: begin
          dmem_wdata    = 32'h0;
          dmem_wen_byte = 4'b0000;
        end
      endcase
    end
  end

  // -----------------------------------------------------------------------
  // Load data alignment and sign extension
  // -----------------------------------------------------------------------
  always_comb begin
    load_data = 32'h0;

    if (mem_ren) begin
      unique case (mem_width)
        MEM_BYTE: begin
          unique case (byte_offset)
            2'b00: load_data = {{24{dmem_rdata[7]}},  dmem_rdata[7:0]};
            2'b01: load_data = {{24{dmem_rdata[15]}}, dmem_rdata[15:8]};
            2'b10: load_data = {{24{dmem_rdata[23]}}, dmem_rdata[23:16]};
            2'b11: load_data = {{24{dmem_rdata[31]}}, dmem_rdata[31:24]};
          endcase
        end

        MEM_BYTEU: begin
          unique case (byte_offset)
            2'b00: load_data = {24'h0, dmem_rdata[7:0]};
            2'b01: load_data = {24'h0, dmem_rdata[15:8]};
            2'b10: load_data = {24'h0, dmem_rdata[23:16]};
            2'b11: load_data = {24'h0, dmem_rdata[31:24]};
          endcase
        end

        MEM_HALF: begin
          unique case (byte_offset[1])
            1'b0: load_data = {{16{dmem_rdata[15]}}, dmem_rdata[15:0]};
            1'b1: load_data = {{16{dmem_rdata[31]}}, dmem_rdata[31:16]};
          endcase
        end

        MEM_HALFU: begin
          unique case (byte_offset[1])
            1'b0: load_data = {16'h0, dmem_rdata[15:0]};
            1'b1: load_data = {16'h0, dmem_rdata[31:16]};
          endcase
        end

        MEM_WORD: begin
          load_data = dmem_rdata;
        end

        default: load_data = 32'h0;
      endcase
    end
  end

endmodule
