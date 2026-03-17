# branch_test.S — Branch instruction test
# Tests: BEQ, BNE, BLT, BGE, BLTU, BGEU

.section .text
.globl _start

_start:
    # BEQ test
    li   x1, 10
    li   x2, 10
    beq  x1, x2, beq_pass
    j    fail
beq_pass:

    # BNE test
    li   x1, 10
    li   x2, 20
    bne  x1, x2, bne_pass
    j    fail
bne_pass:

    # BLT test (signed)
    li   x1, -5
    li   x2, 10
    blt  x1, x2, blt_pass
    j    fail
blt_pass:

    # BGE test (signed)
    li   x1, 10
    li   x2, -5
    bge  x1, x2, bge_pass
    j    fail
bge_pass:

    # BLTU test (unsigned)
    li   x1, 5
    li   x2, 10
    bltu x1, x2, bltu_pass
    j    fail
bltu_pass:

    # BGEU test (unsigned)
    li   x1, 10
    li   x2, 5
    bgeu x1, x2, bgeu_pass
    j    fail
bgeu_pass:

    # All tests passed
    li   x11, 0xDEADBEEF
    li   x12, 0x100
    sw   x11, 0(x12)
    j    end

fail:
    li   x11, 0xBADBAD
    li   x12, 0x100
    sw   x11, 0(x12)

end:
    j end

.section .data
