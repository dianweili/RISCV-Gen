/* Linker script for RISC-V tests */

OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
  IMEM (rx)  : ORIGIN = 0x00000000, LENGTH = 16K
  DMEM (rw)  : ORIGIN = 0x00010000, LENGTH = 16K
}

SECTIONS
{
  .text : {
    *(.text)
    *(.text.*)
  } > IMEM

  .data : {
    *(.data)
    *(.data.*)
    *(.rodata)
    *(.rodata.*)
  } > DMEM

  .bss : {
    *(.bss)
    *(.bss.*)
    *(COMMON)
  } > DMEM

  /DISCARD/ : {
    *(.comment)
    *(.eh_frame)
  }
}
