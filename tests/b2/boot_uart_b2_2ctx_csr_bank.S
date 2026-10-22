# HYTRON64 research artifact; English comment/whitespace normalization only.
#ifndef BENCH_HARTS
#error "Build with -DBENCH_HARTS=1 or 2"
#endif

#if BENCH_HARTS != 1 && BENCH_HARTS != 2
#error "BENCH_HARTS must be 1 or 2"
#endif

.equ SHARED_BASE, 0x81000000
.equ READY_OFF,   0
.equ INIT_OFF,    64
.equ GO_OFF,      128
.equ DONE_OFF,    192
.equ SUM0_OFF,    256
.equ SUM1_OFF,    320

.equ INIT_MAGIC,  0x4232494e
.equ READY_MAGIC, 0x42325244
.equ GO_MAGIC,    0x4232474f
.equ DONE_MAGIC,  0x4232444e

.equ TOTAL_ITERS, 200000
.equ HALF_ITERS,  100000
.equ UART_BASE,   0x10020000

.section .text.init,"ax"
.globl _start
_start:
    la      t0, trap
    csrw    mtvec, t0

hart0:
    # Context 0 mscratch value
    li      t0, 0x43533030
    csrw    mscratch, t0
#if BENCH_HARTS == 1
    li      a0, 1
    li      a1, TOTAL_ITERS

    csrr    s0, mcycle
    jal     ra, work_sum
    csrr    t0, mscratch
    li      t1, 0x43533030
    bne     t0, t1, bench_fail
    csrr    s1, mcycle

    sub     s3, s1, s0
    mv      s4, a0
#else
    li      s5, SHARED_BASE

    # Place inter-context communication variables on separate cache lines.
    sw      zero, READY_OFF(s5)
    sw      zero, INIT_OFF(s5)
    sw      zero, GO_OFF(s5)
    sw      zero, DONE_OFF(s5)
    sd      zero, SUM0_OFF(s5)
    sd      zero, SUM1_OFF(s5)
    fence   rw, rw

    li      t0, INIT_MAGIC
    sw      t0, INIT_OFF(s5)
    fence   rw, rw

wait_worker_ready:
    lw      t0, READY_OFF(s5)
    li      t1, READY_MAGIC
    bne     t0, t1, wait_worker_ready
    fence   rw, rw

    li      a0, 1
    li      a1, HALF_ITERS

    # For the two-hart case, measure from release to completion acknowledgment.
    csrr    s0, mcycle
    li      t0, GO_MAGIC
    sw      t0, GO_OFF(s5)
    fence   rw, rw

    jal     ra, work_sum
    csrr    t0, mscratch
    li      t1, 0x43533030
    bne     t0, t1, bench_fail
    sd      a0, SUM0_OFF(s5)
    fence   rw, rw

wait_worker_done:
    lw      t0, DONE_OFF(s5)
    li      t1, DONE_MAGIC
    bne     t0, t1, wait_worker_done
    fence   rw, rw

    csrr    s1, mcycle
    sub     s3, s1, s0

    ld      t0, SUM0_OFF(s5)
    ld      t1, SUM1_OFF(s5)
    add     s4, t0, t1
#endif

    # Check the common expected checksum.
    li      t0, 20000100000
    bne     s4, t0, bench_fail

    jal     ra, uart_init

    la      a0, result_prefix
    jal     ra, uart_print
    mv      a0, s3
    jal     ra, uart_hex64

    la      a0, checksum_label
    jal     ra, uart_print
    mv      a0, s4
    jal     ra, uart_hex64

    la      a0, newline
    jal     ra, uart_print
    jal     ra, uart_drain

    la      t0, tohost
    li      t1, 1
    sd      t1, 0(t0)
hart0_park:
    j       hart0_park

#if BENCH_HARTS == 2
    .section .ctx1,"ax"
    .globl ctx1_start
ctx1_start:
    # Context 1 mscratch value
    li      t0, 0x43533131
    csrw    mscratch, t0
    li      s5, SHARED_BASE

wait_init:
    lw      t0, INIT_OFF(s5)
    li      t1, INIT_MAGIC
    bne     t0, t1, wait_init
    fence   rw, rw

    li      t0, READY_MAGIC
    sw      t0, READY_OFF(s5)
    fence   rw, rw

wait_go:
    lw      t0, GO_OFF(s5)
    li      t1, GO_MAGIC
    bne     t0, t1, wait_go
    fence   rw, rw

    li      a0, 100001
    li      a1, HALF_ITERS
    jal     ra, work_sum

    csrr    t0, mscratch
    li      t1, 0x43533131
    bne     t0, t1, bench_fail

    sd      a0, SUM1_OFF(s5)
    fence   rw, rw
    li      t0, DONE_MAGIC
    sw      t0, DONE_OFF(s5)
    fence   rw, rw
ctx1_done_park:
    j       ctx1_done_park
#endif

    .section .text,"ax"
hart_park:
    wfi
    j       hart_park

# a0 = first value; a1 = iteration count; returns the accumulated value in a0.
work_sum:
    mv      t0, a0
    mv      t1, a1
    li      t2, 0
work_sum_loop:
    add     t2, t2, t0
    addi    t0, t0, 1
    addi    t1, t1, -1
    bnez    t1, work_sum_loop
    mv      a0, t2
    ret

bench_fail:
    jal     ra, uart_init
    la      a0, fail_message
    jal     ra, uart_print
    jal     ra, uart_drain
    la      t0, tohost
    li      t1, 3
    sd      t1, 0(t0)
    j       hart0_park

uart_init:
    li      t0, UART_BASE
    li      t1, 4339
    sw      t1, 24(t0)
    li      t1, 1
    sw      t1, 8(t0)
    ret

uart_print:
    mv      s6, ra
    mv      t2, a0
uart_print_next:
    lbu     a0, 0(t2)
    beqz    a0, uart_print_done
    jal     ra, uart_putc
    addi    t2, t2, 1
    j       uart_print_next
uart_print_done:
    mv      ra, s6
    ret

uart_hex64:
    mv      s6, ra
    mv      t6, a0
    li      t2, 16
uart_hex64_next:
    srli    t0, t6, 60
    slli    t6, t6, 4
    li      t1, 10
    bltu    t0, t1, uart_hex64_digit
    addi    t0, t0, 55
    j       uart_hex64_send
uart_hex64_digit:
    addi    t0, t0, 48
uart_hex64_send:
    mv      a0, t0
    jal     ra, uart_putc
    addi    t2, t2, -1
    bnez    t2, uart_hex64_next
    mv      ra, s6
    ret

uart_putc:
    li      t0, UART_BASE
uart_putc_wait:
    lw      t1, 0(t0)
    bltz    t1, uart_putc_wait
    sw      a0, 0(t0)
    ret

uart_drain:
    li      t0, UART_BASE
uart_drain_wait:
    lw      t1, 0(t0)
    bltz    t1, uart_drain_wait
    li      t2, 100000
uart_drain_delay:
    addi    t2, t2, -1
    bnez    t2, uart_drain_delay
    ret

trap:
    j       trap

.section .rodata,"a"
#if BENCH_HARTS == 1
result_prefix:
    .asciz  "HYTRON64-B2 HARTS=1 CYCLES=0x"
#else
result_prefix:
    .asciz  "HYTRON64-B2 HARTS=2 CYCLES=0x"
#endif
checksum_label:
    .asciz  " CHECKSUM=0x"
newline:
    .asciz  "\r\n"
fail_message:
    .asciz  "HYTRON64-B2 CHECKSUM FAIL\r\n"
