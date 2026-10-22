#ifndef CASE
#define CASE 0
#endif
#define ROUNDS 1024
.option norvc
.option norelax
.section .text.hart0,"ax",@progbits
.globl _start
_start:
  csrr t6, mhartid
  beqz t6, init0
  j context1
init0:
  csrw mie, zero
  csrci mstatus, 8
  la t0, fail
  csrw mtvec, t0
  li a0, 0x02000000
  sw zero, 0(a0)
  li a1, 1
  sw a1, 4(a0)
  fence rw, rw
  li s0, ROUNDS
#if CASE == 0
  li t2, 17
#elif CASE == 1
  li t2, 17
  li t0, 25
#elif CASE == 2
  li t2, -1
#else
#error Unsupported_CASE
#endif
  la a2, ready1
1:
  lw a1, 0(a2)
  beqz a1, 1b
  fence rw, rw
  la a0, go
  j start0
.org 0x100
.globl start0
start0:
  nop
  li a1, 1
  fence rw, rw
  sw a1, 0(a0)
  fence rw, rw
  j pair0
.org 0x200
.globl pair0
pair0:
#if CASE == 1
  add t2, t2, t0
#else
  addi t2, t2, 1
#endif
  addi s0, s0, -1
  bnez s0, pair0
#if CASE == 0
  li t3, 1041
#elif CASE == 1
  li t3, 25617
#elif CASE == 2
  li t3, 1023
#endif
  beq t2, t3, 2f
  j fail
2:
  j done_marker0
.org 0x300
.globl done_marker0
done_marker0:
  nop
  la a0, done0
  li a1, 1
  fence rw, rw
  sw a1, 0(a0)
  fence rw, rw
  la a0, done1
3:
  lw a1, 0(a0)
  beqz a1, 3b
  fence rw, rw
  j joined0
.org 0x380
.globl joined0
joined0:
  nop
  li a1, 1
  j exit

.section .text.hart1,"ax",@progbits
.globl context1
context1:
  csrw mie, zero
  csrci mstatus, 8
  la t0, fail
  csrw mtvec, t0
  li a0, 0x02000004
  sw zero, 0(a0)
  fence rw, rw
  li s0, ROUNDS
#if CASE == 0 || CASE == 1
  li t2, 123
#elif CASE == 2
  li t2, 0x7fffffffffffffff
#endif
  la a0, ready1
  li a1, 1
  fence rw, rw
  sw a1, 0(a0)
  fence rw, rw
  la a0, go
4:
  lw a1, 0(a0)
  beqz a1, 4b
  fence rw, rw
  j start1
.org 0x100
.globl start1
start1:
  nop
  j pair1
.org 0x200
.globl pair1
pair1:
#if CASE == 0
  addi t2, t2, 3
#elif CASE == 1
  addi t2, t2, -5
#elif CASE == 2
  addi t2, t2, 1
#endif
  addi s0, s0, -1
  bnez s0, pair1
#if CASE == 0
  li t3, 3195
#elif CASE == 1
  li t3, -4997
#elif CASE == 2
  li t3, 0x80000000000003ff
#endif
  beq t2, t3, 5f
  j fail
5:
  j done_marker1
.org 0x300
.globl done_marker1
done_marker1:
  nop
  la a0, done1
  li a1, 1
  fence rw, rw
  sw a1, 0(a0)
  fence rw, rw
6: j 6b

.section .text.common,"ax",@progbits
.balign 4
fail:
  csrw mie, zero
  csrci mstatus, 8
  csrr a1, mhartid
  slli a1, a1, 1
  addi a1, a1, 3
exit:
  la a0, tohost
  fence rw, rw
  sd a1, 0(a0)
7: j 7b
.section .data,"aw",@progbits
.balign 64
ready1: .word 0
.balign 64
go: .word 0
.balign 64
done0: .word 0
.balign 64
done1: .word 0
.section .tohost,"aw",@progbits
.balign 64
.globl tohost
tohost: .dword 0
.globl fromhost
fromhost: .dword 0
