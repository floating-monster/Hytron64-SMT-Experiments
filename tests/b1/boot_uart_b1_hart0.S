# HYTRON64 research artifact; English comment/whitespace normalization only.
.section .text.init,"ax"
.globl _start
_start:
    la      t0, trap
    csrw    mtvec, t0
    csrr    t0, mhartid
    bnez    t0, secondary_park
    li      a0, 0x08000000
    jal     ra, mem_test
    bnez    a0, mem_fail
    li      a0, 0x81000000
    jal     ra, mem_test
    bnez    a0, mem_fail
    li      t0, 0x10020000
    li      t1, 4339
    sw      t1, 24(t0)
    li      t1, 1
    sw      t1, 8(t0)
    la      t2, message
next:
    lbu     t3, 0(t2)
    beqz    t3, done
wait_tx:
    lw      t4, 0(t0)
    bltz    t4, wait_tx
    sw      t3, 0(t0)
    addi    t2, t2, 1
    j       next
done:
    lw      t4, 0(t0)
    bltz    t4, done
    li      t5, 100000
drain:
    addi    t5, t5, -1
    bnez    t5, drain
    la      t0, tohost
    li      t1, 1
    sd      t1, 0(t0)
halt:
    j       halt
secondary_park:
    wfi
    j       secondary_park
.balign 4
trap:
    j       trap
mem_test:
    mv      t0, a0
    li      t1, 512
    li      t2, 0x55aa33ccaa55cc33
mem_write:
    xor     t3, t0, t2
    sd      t3, 0(t0)
    addi    t0, t0, 8
    addi    t1, t1, -1
    bnez    t1, mem_write
    fence   rw, rw
    mv      t0, a0
    li      t1, 512
mem_read:
    xor     t3, t0, t2
    ld      t4, 0(t0)
    bne     t3, t4, mem_bad
    addi    t0, t0, 8
    addi    t1, t1, -1
    bnez    t1, mem_read
    li      a0, 0
    ret
mem_bad:
    li      a0, 1
    ret
mem_fail:
    la      t0, tohost
    li      t1, 3
    sd      t1, 0(t0)
    j       halt
.section .rodata,"a"
message:
    .asciz "HYTRON64-010L UART MEM PASS\r\n"
