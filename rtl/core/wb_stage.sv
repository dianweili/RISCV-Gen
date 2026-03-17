// wb_stage.sv — Write-Back stage
// Selects write-back data source

`include "riscv_pkg.sv"

module wb_stage
  import riscv_pkg::*;
(
  input  logic [31:0] alu_result,
  input  logic [31:0] load_data,
  input  logic [31:0] pc_plus4,
  input  logic [31:0] csr_rdata,
  input  wb_sel_e     wb_sel,

  output logic [31:0] wb_data
);

  always_comb begin
    unique case (wb_sel)
      WB_ALU:  wb_data = alu_result;
      WB_MEM:  wb_data = load_data;
      WB_PC4:  wb_data = pc_plus4;
      WB_CSR:  wb_data = csr_rdata;
      default: wb_data = alu_result;
    endcase
  end

endmodule
