gtkwave::addSignalsFromList {
  tb_riscv_top.clk
  tb_riscv_top.rst_n
  tb_riscv_top.dut.imem_addr
  tb_riscv_top.dut.ex_alu_result
  tb_riscv_top.dut.ex_branch_taken
  tb_riscv_top.dut.wb_data
  tb_riscv_top.dut.dmem_addr
  tb_riscv_top.dut.dmem_wen_byte
  tb_riscv_top.dut.dmem_wdata
}
gtkwave::setWindowStartTime 0
gtkwave::setWindowEndTime 250
gtkwave::setZoomFactor -1
gtkwave::hardcopy /project/RISCV-Gen/docs/screenshots/boot_test.png png
exit
