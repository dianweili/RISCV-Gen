// csr_regfile.sv — CSR register file with minimal trap support
// Implements: mstatus, mtvec, mepc, mcause, mtval, misa, mhartid

`include "riscv_pkg.sv"

module csr_regfile
  import riscv_pkg::*;
(
  input  logic        clk,
  input  logic        rst_n,

  // CSR read/write interface (from EX/MEM stage)
  input  logic [11:0] csr_addr,
  input  logic [31:0] csr_wdata,
  input  csr_op_e     csr_op,
  input  logic [4:0]  rs1_addr,    // for CSRRWI/CSRRSI/CSRRCI zimm field
  output logic [31:0] csr_rdata,

  // Trap interface
  input  logic        trap_en,
  input  logic [31:0] trap_pc,
  input  logic [31:0] trap_cause,
  input  logic [31:0] trap_val,

  // MRET interface
  input  logic        mret_en,

  // Trap vector output
  output logic [31:0] mtvec_out,
  output logic [31:0] mepc_out
);

  // -----------------------------------------------------------------------
  // CSR storage
  // -----------------------------------------------------------------------
  logic [31:0] mstatus;   // 0x300
  logic [31:0] misa;      // 0x301 (read-only)
  logic [31:0] mtvec;     // 0x305
  logic [31:0] mepc;      // 0x341
  logic [31:0] mcause;    // 0x342
  logic [31:0] mtval;     // 0x343

  // misa: RV32I
  localparam logic [31:0] MISA_VAL = 32'h4000_0100; // MXL=01 (32-bit), I extension

  // -----------------------------------------------------------------------
  // CSR read (combinational)
  // -----------------------------------------------------------------------
  always_comb begin
    unique case (csr_addr)
      CSR_MSTATUS: csr_rdata = mstatus;
      CSR_MISA:    csr_rdata = MISA_VAL;
      CSR_MTVEC:   csr_rdata = mtvec;
      CSR_MEPC:    csr_rdata = mepc;
      CSR_MCAUSE:  csr_rdata = mcause;
      CSR_MTVAL:   csr_rdata = mtval;
      CSR_MHARTID: csr_rdata = 32'h0;
      default:     csr_rdata = 32'h0;
    endcase
  end

  // -----------------------------------------------------------------------
  // Write data computation
  // -----------------------------------------------------------------------
  logic [31:0] wr_data;
  logic [31:0] zimm;
  logic        do_write;

  assign zimm = {27'h0, rs1_addr};  // zero-extended immediate for *I variants

  always_comb begin
    do_write = 1'b0;
    wr_data  = 32'h0;
    unique case (csr_op)
      CSR_RW:  begin wr_data = csr_wdata;              do_write = 1'b1; end
      CSR_RS:  begin wr_data = csr_rdata | csr_wdata;  do_write = (csr_wdata != 32'h0); end
      CSR_RC:  begin wr_data = csr_rdata & ~csr_wdata; do_write = (csr_wdata != 32'h0); end
      CSR_RWI: begin wr_data = zimm;                   do_write = 1'b1; end
      CSR_RSI: begin wr_data = csr_rdata | zimm;       do_write = (zimm != 32'h0); end
      CSR_RCI: begin wr_data = csr_rdata & ~zimm;      do_write = (zimm != 32'h0); end
      default: begin wr_data = 32'h0;                  do_write = 1'b0; end
    endcase
  end

  // -----------------------------------------------------------------------
  // CSR write (synchronous)
  // -----------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mstatus <= 32'h0000_1800; // MPP=11 (M-mode)
      mtvec   <= 32'h0;
      mepc    <= 32'h0;
      mcause  <= 32'h0;
      mtval   <= 32'h0;
    end else begin
      // Trap takes priority over normal CSR write
      if (trap_en) begin
        mepc    <= {trap_pc[31:2], 2'b00};  // align to 4 bytes
        mcause  <= trap_cause;
        mtval   <= trap_val;
        // Save MIE to MPIE, clear MIE, set MPP=11
        mstatus <= {mstatus[31:13], 2'b11, mstatus[10:8], mstatus[3], mstatus[6:4], 1'b0, mstatus[2:0]};
      end else if (mret_en) begin
        // Restore MIE from MPIE, set MPIE=1, set MPP=0
        mstatus <= {mstatus[31:13], 2'b00, mstatus[10:8], 1'b1, mstatus[6:4], mstatus[7], mstatus[2:0]};
      end else if (do_write) begin
        unique case (csr_addr)
          CSR_MSTATUS: mstatus <= wr_data;
          CSR_MTVEC:   mtvec   <= {wr_data[31:2], 2'b00}; // force base alignment
          CSR_MEPC:    mepc    <= {wr_data[31:2], 2'b00};
          CSR_MCAUSE:  mcause  <= wr_data;
          CSR_MTVAL:   mtval   <= wr_data;
          default: ;
        endcase
      end
    end
  end

  assign mtvec_out = mtvec;
  assign mepc_out  = mepc;

endmodule
