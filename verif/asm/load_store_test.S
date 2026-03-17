# load_store_test.S — Load/Store instruction test
# Tests: LB, LH, LW, LBU, LHU, SB, SH, SW

.section .text
.globl _start

_start:
    # Store word
    li   x1, 0x12345678
    li   x2, 0x200
    sw   x1, 0(x2)

    # Load word
    lw   x3, 0(x2)
    bne  x1, x3, fail

    # Store halfword
    li   x4, 0xABCD
    sh   x4, 4(x2)

    # Load halfword (sign-extended)
    lh   x5, 4(x2)
    li   x6, 0xFFFFABCD
    bne  x5, x6, fail

    # Load halfword unsigned
    lhu  x7, 4(x2)
    li   x8, 0x0000ABCD
    bne  x7, x8, fail

    # Store byte
    li   x9, 0xEF
    sb   x9, 8(x2)

    # Load byte (sign-extended)
    lb   x10, 8(x2)
    li   x11, 0xFFFFFFEF
    bne  x10, x11, fail

    # Load byte unsigned
    lbu  x12, 8(x2)
    li   x13, 0x000000EF
    bne  x12, x13, fail

    # All tests passed
    li   x14, 0xDEADBEEF
    li   x15, 0x100
    sw   x14, 0(x15)
    j    end

fail:
    li   x14, 0xBADBAD
    li   x15, 0x100
    sw   x14, 0(x15)

end:
    j end

.section .data
