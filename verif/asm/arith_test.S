# arith_test.S — Comprehensive arithmetic test
# Tests: ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND

.section .text
.globl _start

_start:
    # ADD/SUB tests
    li   x1, 100
    li   x2, 50
    add  x3, x1, x2    # x3 = 150
    sub  x4, x1, x2    # x4 = 50

    # Shift tests
    li   x5, 1
    slli x6, x5, 4     # x6 = 16
    srli x7, x6, 2     # x7 = 4

    # Arithmetic shift right (sign extend)
    li   x8, 0xFFFFFF00
    srai x9, x8, 4     # x9 = 0xFFFFFFF0

    # Set less than (signed)
    li   x10, -10
    li   x11, 5
    slt  x12, x10, x11 # x12 = 1 (-10 < 5)

    # Set less than unsigned
    li   x13, 5
    li   x14, 10
    sltu x15, x13, x14 # x15 = 1 (5 < 10)

    # Logical operations
    li   x16, 0xAAAA
    li   x17, 0x5555
    xor  x18, x16, x17 # x18 = 0xFFFF
    or   x19, x16, x17 # x19 = 0xFFFF
    and  x20, x16, x17 # x20 = 0x0000

    # Verify key results
    li   x21, 150
    bne  x3, x21, fail

    li   x21, 16
    bne  x6, x21, fail

    li   x21, 1
    bne  x12, x21, fail

    li   x21, 0xFFFF
    bne  x18, x21, fail

    # All tests passed
    li   x22, 0xDEADBEEF
    li   x23, 0x100
    sw   x22, 0(x23)
    j    end

fail:
    li   x22, 0xBADBAD
    li   x23, 0x100
    sw   x22, 0(x23)

end:
    j end

.section .data
