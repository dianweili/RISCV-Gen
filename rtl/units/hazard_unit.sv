// hazard_unit.sv — Pipeline stall and flush control
// Handles load-use stalls and branch/jump flushes

module hazard_unit (
  // Load-use hazard detection
  input  logic        id_ex_mem_ren,    // ID/EX stage is a load
  input  logic [4:0]  id_ex_rd,         // ID/EX destination register
  input  logic [4:0]  if_id_rs1,        // IF/ID source register 1
  input  logic [4:0]  if_id_rs2,        // IF/ID source register 2

  // Branch/jump flush control
  input  logic        branch_taken,     // Branch resolved as taken (EX stage)
  input  logic        jal_id,           // JAL decoded in ID stage
  input  logic        jalr_ex,          // JALR resolved in EX stage

  // Stall outputs
  output logic        pc_stall,         // Stall PC register
  output logic        if_id_stall,      // Stall IF/ID register
  output logic        id_ex_stall,      // Stall ID/EX register (unused, kept for completeness)

  // Flush outputs
  output logic        if_id_flush,      // Flush IF/ID register (insert bubble)
  output logic        id_ex_flush       // Flush ID/EX register (insert bubble)
);

  logic load_use_stall;

  // Load-use hazard: stall one cycle when load result needed next cycle
  assign load_use_stall = id_ex_mem_ren &&
                          (id_ex_rd != 5'h0) &&
                          ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2));

  // Stall signals
  assign pc_stall    = load_use_stall;
  assign if_id_stall = load_use_stall;
  assign id_ex_stall = 1'b0;  // Not needed with current scheme

  // Flush signals
  // JAL resolved in ID: flush IF/ID (1-cycle penalty)
  // Branch taken or JALR resolved in EX: flush IF/ID and ID/EX (2-cycle penalty)
  assign if_id_flush = (branch_taken || jalr_ex) || (jal_id && !load_use_stall);
  assign id_ex_flush = (branch_taken || jalr_ex) || load_use_stall;

endmodule
