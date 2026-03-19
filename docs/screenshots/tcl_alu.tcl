gtkwave::addSignalsFromList {
  tb_alu.op
  tb_alu.a
  tb_alu.b
  tb_alu.result
}
gtkwave::setWindowStartTime 0
gtkwave::setWindowEndTime 1200
gtkwave::setZoomFactor -3
gtkwave::hardcopy /project/RISCV-Gen/docs/screenshots/alu.png png
exit
