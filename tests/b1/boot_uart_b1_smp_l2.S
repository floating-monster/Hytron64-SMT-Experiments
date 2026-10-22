# HYTRON64 research artifact; English comment/whitespace normalization only.
.section .text.init,"ax"
.globl _start
_start:
    csrr    s0, mhartid
    beqz    s0, hart0
    j       hart1

# The two harts exchange values in order within one 64-byte cache line.
# 0x81000000 is the DRAM address used by the preceding memory test.
hart0:
    li      t0, 0x81000000
    sd      zero, 0(t0)        # READY
    sd      zero, 8(t0)        # hart1 payload
    sd      zero, 16(t0)       # hart 1 completion flag
    sd      zero, 24(t0)       # hart0 ACK
    sd      zero, 32(t0)       # hart 1 response
    sd      zero, 40(t0)       # round-trip completion flag
    fence   rw, rw

    li      t1, 0x13579bdf
    sw      t1, 0(t0)          # release hart 1
    fence   rw, rw

wait_hart1_done:
    lw      t1, 16(t0)
    li      t2, 0x2468ace1
    bne     t1, t2, wait_hart1_done

    ld      t1, 8(t0)
    li      t2, 0x55aa33cc
    bne     t1, t2, fail

    li      t1, 0x31415926
    sw      t1, 24(t0)         # acknowledge hart 1
    fence   rw, rw

wait_roundtrip_done:
    lw      t1, 40(t0)
    li      t2, 0x10293847
    bne     t1, t2, wait_roundtrip_done

    ld      t1, 32(t0)
    li      t2, 0x5aa5c33c
    bne     t1, t2, fail

pass:
    la      a0, pass_message
    jal     ra, uart_print
    j       success_exit

fail:
    la      a0, fail_message
    jal     ra, uart_print
    j       failure_exit

# Hart 1 waits for hart 0, then writes the shared cache line.
# It writes the second value after observing the acknowledgment.
hart1:
    li      t0, 0x81000000
wait_start:
    lw      t1, 0(t0)
    li      t2, 0x13579bdf
    bne     t1, t2, wait_start

    li      t1, 0x55aa33cc
    sd      t1, 8(t0)
    fence   rw, rw
    li      t1, 0x2468ace1
    sw      t1, 16(t0)
    fence   rw, rw

wait_ack:
    lw      t1, 24(t0)
    li      t2, 0x31415926
    bne     t1, t2, wait_ack

    li      t1, 0x5aa5c33c
    sd      t1, 32(t0)
    fence   rw, rw
    li      t1, 0x10293847
    sw      t1, 40(t0)
    fence   rw, rw

hart1_park:
    wfi
    j       hart1_park

# Only hart 0 writes the UART.
uart_print:
    li      t0, 0x10020000
    li      t1, 4339
    sw      t1, 24(t0)
    li      t1, 1
    sw      t1, 8(t0)
uart_next:
    lbu     t3, 0(a0)
    beqz    t3, uart_drain
uart_wait_tx:
    lw      t4, 0(t0)
    bltz    t4, uart_wait_tx
    sw      t3, 0(t0)
    addi    a0, a0, 1
    j       uart_next
uart_drain:
    lw      t4, 0(t0)
    bltz    t4, uart_drain
    li      t5, 100000
uart_drain_delay:
    addi    t5, t5, -1
    bnez    t5, uart_drain_delay
    ret

success_exit:
    la      t0, tohost
    li      t1, 1
    sd      t1, 0(t0)
hart0_park:
    j       hart0_park

failure_exit:
    la      t0, tohost
    li      t1, 3
    sd      t1, 0(t0)
    j       hart0_park

.balign 4
pass_message:
    .asciz "HYTRON64-B1 SMP L2 ROUNDTRIP PASS\r\n"
fail_message:
    .asciz "HYTRON64-B1 SMP L2 ROUNDTRIP FAIL\r\n"
