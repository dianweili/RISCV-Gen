gtkwave::addSignalsFromList {
  tb_regfile.clk
  tb_regfile.wen
  tb_regfile.rd_addr
  tb_regfile.rd_data
  tb_regfile.rs1_addr
  tb_regfile.rs1_data
  tb_regfile.rs2_addr
  tb_regfile.rs2_data
}
gtkwave::setWindowStartTime 0
gtkwave::setWindowEndTime 600
gtkwave::setZoomFactor -3
gtkwave::hardcopy /project/RISCV-Gen/docs/screenshots/regfile.png png
exit
