# hazard_test.S — Data hazard and forwarding test
# Tests load-use stalls and EX/MEM forwarding

.section .text
.globl _start

_start:
    # Test 1: RAW hazard with forwarding (EX->EX)
    li   x1, 10
    addi x2, x1, 5     # x2 = 15 (forward from x1)
    addi x3, x2, 3     # x3 = 18 (forward from x2)

    # Test 2: Load-use hazard (requires stall)
    li   x4, 0x200
    sw   x3, 0(x4)
    lw   x5, 0(x4)     # x5 = 18
    addi x6, x5, 2     # x6 = 20 (stall 1 cycle, then forward)

    # Test 3: Multiple forwarding paths
    add  x7, x6, x3    # x7 = 20 + 18 = 38
    sub  x8, x7, x2    # x8 = 38 - 15 = 23
    and  x9, x8, x7    # x9 = 23 & 38

    # Verify results
    li   x10, 18
    bne  x3, x10, fail

    li   x10, 20
    bne  x6, x10, fail

    li   x10, 38
    bne  x7, x10, fail

    li   x10, 23
    bne  x8, x10, fail

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
