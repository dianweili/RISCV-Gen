// riscv_top.sv — Top-level RISC-V RV32I 5-stage pipeline processor
// Integrates all pipeline stages, hazard/forward units, and memories

`include "riscv_pkg.sv"
`include "pipeline_pkg.sv"

module riscv_top
  import riscv_pkg::*;
  import pipeline_pkg::*;
#(
  parameter IMEM_DEPTH = 4096,
  parameter DMEM_DEPTH = 4096,
  parameter IMEM_INIT_FILE = ""
)(
  input  logic clk,
  input  logic rst_n
);

  // =====================================================================
  // Pipeline registers
  // =====================================================================
  if_id_t  if_id_reg, if_id_next;
  id_ex_t  id_ex_reg, id_ex_next;
  ex_mem_t ex_mem_reg, ex_mem_next;
  mem_wb_t mem_wb_reg, mem_wb_next;

  // =====================================================================
  // IF stage signals
  // =====================================================================
  logic [31:0] if_pc, if_inst;
  logic [31:0] imem_addr, imem_rdata;
  pc_sel_e     pc_sel;
  logic [31:0] branch_target, jalr_target, trap_target;

  // =====================================================================
  // ID stage signals
  // =====================================================================
  logic [4:0]  id_rs1_addr, id_rs2_addr, id_rd_addr;
  logic [31:0] id_rs1_data, id_rs2_data, id_imm;
  alu_op_e     id_alu_op;
  srca_sel_e   id_srca_sel;
  srcb_sel_e   id_srcb_sel;
  wb_sel_e     id_wb_sel;
  logic        id_reg_wen, id_mem_ren, id_mem_wen;
  mem_width_e  id_mem_width;
  pc_sel_e     id_pc_sel_hint;
  csr_op_e     id_csr_op;
  logic [11:0] id_csr_addr;
  logic        id_jal;

  // =====================================================================
  // EX stage signals
  // =====================================================================
  logic [31:0] ex_alu_result, ex_rs2_data_fwd;
  logic        ex_branch_taken, ex_jalr;
  logic [1:0]  fwd_a, fwd_b;

  // =====================================================================
  // MEM stage signals
  // =====================================================================
  logic [31:0] mem_load_data;
  logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;
  logic [3:0]  dmem_wen_byte;

  // =====================================================================
  // WB stage signals
  // =====================================================================
  logic [31:0] wb_data;

  // =====================================================================
  // Hazard control signals
  // =====================================================================
  logic pc_stall, if_id_stall, id_ex_stall;
  logic if_id_flush, id_ex_flush;

  // =====================================================================
  // CSR signals
  // =====================================================================
  logic [31:0] csr_rdata, csr_wdata;
  logic [31:0] mtvec_out, mepc_out;
  logic        trap_en, mret_en;
  logic [31:0] trap_pc, trap_cause, trap_val;

  // =====================================================================
  // Register file
  // =====================================================================
  regfile u_regfile (
    .clk      (clk),
    .rs1_addr (id_rs1_addr),
    .rs1_data (id_rs1_data),
    .rs2_addr (id_rs2_addr),
    .rs2_data (id_rs2_data),
    .rd_addr  (mem_wb_reg.rd_addr),
    .rd_data  (wb_data),
    .wen      (mem_wb_reg.reg_wen && mem_wb_reg.valid)
  );

  // =====================================================================
  // Instruction memory
  // =====================================================================
  imem #(
    .DEPTH     (IMEM_DEPTH),
    .INIT_FILE (IMEM_INIT_FILE)
  ) u_imem (
    .clk   (clk),
    .addr  (imem_addr),
    .rdata (imem_rdata)
  );

  // =====================================================================
  // Data memory
  // =====================================================================
  dmem #(
    .DEPTH (DMEM_DEPTH)
  ) u_dmem (
    .clk   (clk),
    .addr  (dmem_addr),
    .wdata (dmem_wdata),
    .wen   (dmem_wen_byte),
    .rdata (dmem_rdata)
  );

  // =====================================================================
  // IF stage
  // =====================================================================
  if_stage u_if_stage (
    .clk           (clk),
    .rst_n         (rst_n),
    .pc_stall      (pc_stall),
    .pc_sel        (pc_sel),
    .branch_target (branch_target),
    .jalr_target   (jalr_target),
    .trap_target   (trap_target),
    .imem_addr     (imem_addr),
    .imem_rdata    (imem_rdata),
    .pc_out        (if_pc),
    .inst_out      (if_inst)
  );

  // =====================================================================
  // ID stage
  // =====================================================================
  id_stage u_id_stage (
    .clk          (clk),
    .inst         (if_id_reg.inst),
    .pc           (if_id_reg.pc),
    .rs1_addr     (id_rs1_addr),
    .rs2_addr     (id_rs2_addr),
    .rs1_data     (id_rs1_data),
    .rs2_data     (id_rs2_data),
    .imm          (id_imm),
    .rd_addr      (id_rd_addr),
    .alu_op       (id_alu_op),
    .srca_sel     (id_srca_sel),
    .srcb_sel     (id_srcb_sel),
    .wb_sel       (id_wb_sel),
    .reg_wen      (id_reg_wen),
    .mem_ren      (id_mem_ren),
    .mem_wen      (id_mem_wen),
    .mem_width    (id_mem_width),
    .pc_sel_hint  (id_pc_sel_hint),
    .csr_op       (id_csr_op),
    .csr_addr     (id_csr_addr),
    .jal_id       (id_jal)
  );

  // =====================================================================
  // EX stage
  // =====================================================================
  ex_stage u_ex_stage (
    .pc                 (id_ex_reg.pc),
    .pc_plus4           (id_ex_reg.pc_plus4),
    .rs1_data           (id_ex_reg.rs1_data),
    .rs2_data           (id_ex_reg.rs2_data),
    .imm                (id_ex_reg.imm),
    .alu_op             (id_ex_reg.alu_op),
    .srca_sel           (id_ex_reg.srca_sel),
    .srcb_sel           (id_ex_reg.srcb_sel),
    .funct3             (id_ex_reg.funct3),
    .opcode             (id_ex_reg.opcode),
    .fwd_a              (fwd_a),
    .fwd_b              (fwd_b),
    .ex_mem_alu_result  (ex_mem_reg.alu_result),
    .mem_wb_wb_data     (wb_data),
    .alu_result         (ex_alu_result),
    .rs2_data_fwd       (ex_rs2_data_fwd),
    .branch_target      (branch_target),
    .jalr_target        (jalr_target),
    .branch_taken       (ex_branch_taken),
    .jalr_ex            (ex_jalr)
  );

  // =====================================================================
  // MEM stage
  // =====================================================================
  mem_stage u_mem_stage (
    .alu_result   (ex_mem_reg.alu_result),
    .rs2_data     (ex_mem_reg.rs2_data),
    .mem_ren      (ex_mem_reg.mem_ren),
    .mem_wen      (ex_mem_reg.mem_wen && ex_mem_reg.valid),
    .mem_width    (ex_mem_reg.mem_width),
    .dmem_addr    (dmem_addr),
    .dmem_wdata   (dmem_wdata),
    .dmem_wen_byte(dmem_wen_byte),
    .dmem_rdata   (dmem_rdata),
    .load_data    (mem_load_data)
  );

  // =====================================================================
  // WB stage
  // =====================================================================
  wb_stage u_wb_stage (
    .alu_result (mem_wb_reg.alu_result),
    .load_data  (mem_wb_reg.load_data),
    .pc_plus4   (mem_wb_reg.pc_plus4),
    .csr_rdata  (mem_wb_reg.csr_rdata),
    .wb_sel     (mem_wb_reg.wb_sel),
    .wb_data    (wb_data)
  );

  // =====================================================================
  // Hazard unit
  // =====================================================================
  hazard_unit u_hazard_unit (
    .id_ex_mem_ren  (id_ex_reg.mem_ren),
    .id_ex_rd       (id_ex_reg.rd_addr),
    .if_id_rs1      (id_rs1_addr),
    .if_id_rs2      (id_rs2_addr),
    .branch_taken   (ex_branch_taken),
    .jal_id         (id_jal),
    .jalr_ex        (ex_jalr),
    .pc_stall       (pc_stall),
    .if_id_stall    (if_id_stall),
    .id_ex_stall    (id_ex_stall),
    .if_id_flush    (if_id_flush),
    .id_ex_flush    (id_ex_flush)
  );

  // =====================================================================
  // Forward unit
  // =====================================================================
  forward_unit u_forward_unit (
    .id_ex_rs1      (id_ex_reg.rs1_addr),
    .id_ex_rs2      (id_ex_reg.rs2_addr),
    .ex_mem_rd      (ex_mem_reg.rd_addr),
    .ex_mem_reg_wen (ex_mem_reg.reg_wen && ex_mem_reg.valid),
    .mem_wb_rd      (mem_wb_reg.rd_addr),
    .mem_wb_reg_wen (mem_wb_reg.reg_wen && mem_wb_reg.valid),
    .fwd_a          (fwd_a),
    .fwd_b          (fwd_b)
  );

  // =====================================================================
  // CSR register file
  // =====================================================================
  assign csr_wdata = id_ex_reg.rs1_data;  // CSR write data from rs1

  csr_regfile u_csr_regfile (
    .clk       (clk),
    .rst_n     (rst_n),
    .csr_addr  (ex_mem_reg.csr_addr),
    .csr_wdata (csr_wdata),
    .csr_op    (ex_mem_reg.csr_op),
    .rs1_addr  (id_ex_reg.rs1_addr),
    .csr_rdata (csr_rdata),
    .trap_en   (trap_en),
    .trap_pc   (trap_pc),
    .trap_cause(trap_cause),
    .trap_val  (trap_val),
    .mret_en   (mret_en),
    .mtvec_out (mtvec_out),
    .mepc_out  (mepc_out)
  );

  // Trap handling (simplified - no trap detection in this version)
  assign trap_en     = 1'b0;
  assign trap_pc     = 32'h0;
  assign trap_cause  = 32'h0;
  assign trap_val    = 32'h0;
  assign mret_en     = 1'b0;
  assign trap_target = mtvec_out;

  // =====================================================================
  // PC selection logic
  // =====================================================================
  always_comb begin
    if (ex_branch_taken)
      pc_sel = PC_BRANCH;
    else if (ex_jalr)
      pc_sel = PC_JALR;
    else if (id_jal && !if_id_flush)
      pc_sel = id_pc_sel_hint;
    else if (trap_en)
      pc_sel = PC_TRAP;
    else
      pc_sel = PC_PLUS4;
  end

  // =====================================================================
  // Pipeline register updates
  // =====================================================================

  // IF/ID register
  always_comb begin
    if_id_next.pc    = if_pc;
    if_id_next.inst  = if_inst;
    if_id_next.valid = 1'b1;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      if_id_reg <= if_id_bubble();
    else if (if_id_flush)
      if_id_reg <= if_id_bubble();
    else if (!if_id_stall)
      if_id_reg <= if_id_next;
  end

  // ID/EX register
  always_comb begin
    id_ex_next.pc        = if_id_reg.pc;
    id_ex_next.pc_plus4  = if_id_reg.pc + 32'd4;
    id_ex_next.rs1_data  = id_rs1_data;
    id_ex_next.rs2_data  = id_rs2_data;
    id_ex_next.imm       = id_imm;
    id_ex_next.rs1_addr  = id_rs1_addr;
    id_ex_next.rs2_addr  = id_rs2_addr;
    id_ex_next.rd_addr   = id_rd_addr;
    id_ex_next.alu_op    = id_alu_op;
    id_ex_next.srca_sel  = id_srca_sel;
    id_ex_next.srcb_sel  = id_srcb_sel;
    id_ex_next.wb_sel    = id_wb_sel;
    id_ex_next.reg_wen   = id_reg_wen;
    id_ex_next.mem_ren   = id_mem_ren;
    id_ex_next.mem_wen   = id_mem_wen;
    id_ex_next.mem_width = id_mem_width;
    id_ex_next.pc_sel    = id_pc_sel_hint;
    id_ex_next.csr_op    = id_csr_op;
    id_ex_next.csr_addr  = id_csr_addr;
    id_ex_next.funct3    = if_id_reg.inst[14:12];
    id_ex_next.opcode    = if_id_reg.inst[6:0];
    id_ex_next.valid     = if_id_reg.valid;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      id_ex_reg <= id_ex_bubble();
    else if (id_ex_flush)
      id_ex_reg <= id_ex_bubble();
    else
      id_ex_reg <= id_ex_next;
  end

  // EX/MEM register
  always_comb begin
    ex_mem_next.alu_result = ex_alu_result;
    ex_mem_next.rs2_data   = ex_rs2_data_fwd;
    ex_mem_next.pc_plus4   = id_ex_reg.pc_plus4;
    ex_mem_next.rd_addr    = id_ex_reg.rd_addr;
    ex_mem_next.wb_sel     = id_ex_reg.wb_sel;
    ex_mem_next.reg_wen    = id_ex_reg.reg_wen;
    ex_mem_next.mem_ren    = id_ex_reg.mem_ren;
    ex_mem_next.mem_wen    = id_ex_reg.mem_wen;
    ex_mem_next.mem_width  = id_ex_reg.mem_width;
    ex_mem_next.csr_op     = id_ex_reg.csr_op;
    ex_mem_next.csr_addr   = id_ex_reg.csr_addr;
    ex_mem_next.valid      = id_ex_reg.valid;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      ex_mem_reg <= ex_mem_bubble();
    else
      ex_mem_reg <= ex_mem_next;
  end

  // MEM/WB register
  always_comb begin
    mem_wb_next.alu_result = ex_mem_reg.alu_result;
    mem_wb_next.load_data  = mem_load_data;
    mem_wb_next.pc_plus4   = ex_mem_reg.pc_plus4;
    mem_wb_next.csr_rdata  = csr_rdata;
    mem_wb_next.rd_addr    = ex_mem_reg.rd_addr;
    mem_wb_next.wb_sel     = ex_mem_reg.wb_sel;
    mem_wb_next.reg_wen    = ex_mem_reg.reg_wen;
    mem_wb_next.valid      = ex_mem_reg.valid;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      mem_wb_reg <= mem_wb_bubble();
    else
      mem_wb_reg <= mem_wb_next;
  end

endmodule
