# boot_test.S — Basic boot and arithmetic test
# Tests: ADDI, ADD, SUB, AND, OR, XOR

.section .text
.globl _start

_start:
    # Initialize registers
    li x1, 10          # x1 = 10
    li x2, 20          # x2 = 20

    # Arithmetic tests
    add  x3, x1, x2    # x3 = 30
    sub  x4, x2, x1    # x4 = 10
    addi x5, x1, 5     # x5 = 15

    # Logical tests
    li   x6, 0xF0F0
    li   x7, 0xFF00
    and  x8, x6, x7    # x8 = 0xF000
    or   x9, x6, x7    # x9 = 0xFFF0
    xor  x10, x6, x7   # x10 = 0x0FF0

    # Write PASS signature
    li   x11, 0xDEADBEEF
    li   x12, 0x100
    sw   x11, 0(x12)

    # Infinite loop
_end:
    j _end

.section .data
