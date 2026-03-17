// pipeline_pkg.sv — Pipeline register struct definitions
// RISC-V RV32I 5-Stage Pipeline Processor

`ifndef PIPELINE_PKG_SV
`define PIPELINE_PKG_SV

`include "riscv_pkg.sv"

package pipeline_pkg;

  import riscv_pkg::*;

  // -----------------------------------------------------------------------
  // IF/ID pipeline register
  // -----------------------------------------------------------------------
  typedef struct packed {
    logic [31:0] pc;
    logic [31:0] inst;
    logic        valid;   // 0 = bubble
  } if_id_t;

  // -----------------------------------------------------------------------
  // ID/EX pipeline register
  // -----------------------------------------------------------------------
  typedef struct packed {
    logic [31:0]  pc;
    logic [31:0]  pc_plus4;
    logic [31:0]  rs1_data;
    logic [31:0]  rs2_data;
    logic [31:0]  imm;
    logic [4:0]   rs1_addr;
    logic [4:0]   rs2_addr;
    logic [4:0]   rd_addr;
    alu_op_e      alu_op;
    srca_sel_e    srca_sel;
    srcb_sel_e    srcb_sel;
    wb_sel_e      wb_sel;
    logic         reg_wen;
    logic         mem_ren;
    logic         mem_wen;
    mem_width_e   mem_width;
    pc_sel_e      pc_sel;
    csr_op_e      csr_op;
    logic [11:0]  csr_addr;
    logic         valid;
  } id_ex_t;

  // -----------------------------------------------------------------------
  // EX/MEM pipeline register
  // -----------------------------------------------------------------------
  typedef struct packed {
    logic [31:0]  alu_result;
    logic [31:0]  rs2_data;
    logic [31:0]  pc_plus4;
    logic [4:0]   rd_addr;
    wb_sel_e      wb_sel;
    logic         reg_wen;
    logic         mem_ren;
    logic         mem_wen;
    mem_width_e   mem_width;
    csr_op_e      csr_op;
    logic [11:0]  csr_addr;
    logic         valid;
  } ex_mem_t;

  // -----------------------------------------------------------------------
  // MEM/WB pipeline register
  // -----------------------------------------------------------------------
  typedef struct packed {
    logic [31:0]  alu_result;
    logic [31:0]  load_data;
    logic [31:0]  pc_plus4;
    logic [31:0]  csr_rdata;
    logic [4:0]   rd_addr;
    wb_sel_e      wb_sel;
    logic         reg_wen;
    logic         valid;
  } mem_wb_t;

  // -----------------------------------------------------------------------
  // Zero/bubble initializers
  // -----------------------------------------------------------------------
  function automatic if_id_t if_id_bubble();
    if_id_t b;
    b.pc    = 32'h0;
    b.inst  = 32'h0000_0013; // NOP (ADDI x0, x0, 0)
    b.valid = 1'b0;
    return b;
  endfunction

  function automatic id_ex_t id_ex_bubble();
    id_ex_t b;
    b.pc       = 32'h0;
    b.pc_plus4 = 32'h0;
    b.rs1_data = 32'h0;
    b.rs2_data = 32'h0;
    b.imm      = 32'h0;
    b.rs1_addr = 5'h0;
    b.rs2_addr = 5'h0;
    b.rd_addr  = 5'h0;
    b.alu_op   = ALU_ADD;
    b.srca_sel = SRCA_RS1;
    b.srcb_sel = SRCB_RS2;
    b.wb_sel   = WB_ALU;
    b.reg_wen  = 1'b0;
    b.mem_ren  = 1'b0;
    b.mem_wen  = 1'b0;
    b.mem_width= MEM_WORD;
    b.pc_sel   = PC_PLUS4;
    b.csr_op   = CSR_NONE;
    b.csr_addr = 12'h0;
    b.valid    = 1'b0;
    return b;
  endfunction

  function automatic ex_mem_t ex_mem_bubble();
    ex_mem_t b;
    b.alu_result = 32'h0;
    b.rs2_data   = 32'h0;
    b.pc_plus4   = 32'h0;
    b.rd_addr    = 5'h0;
    b.wb_sel     = WB_ALU;
    b.reg_wen    = 1'b0;
    b.mem_ren    = 1'b0;
    b.mem_wen    = 1'b0;
    b.mem_width  = MEM_WORD;
    b.csr_op     = CSR_NONE;
    b.csr_addr   = 12'h0;
    b.valid      = 1'b0;
    return b;
  endfunction

  function automatic mem_wb_t mem_wb_bubble();
    mem_wb_t b;
    b.alu_result = 32'h0;
    b.load_data  = 32'h0;
    b.pc_plus4   = 32'h0;
    b.csr_rdata  = 32'h0;
    b.rd_addr    = 5'h0;
    b.wb_sel     = WB_ALU;
    b.reg_wen    = 1'b0;
    b.valid      = 1'b0;
    return b;
  endfunction

endpackage

`endif // PIPELINE_PKG_SV
