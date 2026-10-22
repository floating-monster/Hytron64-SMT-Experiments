#ifndef CASE
#define CASE 0
#endif
/* No C runtime or stack. Both contexts use x5/x6/x7 with different values. */
.option norvc
.option norelax
.section .text.ctx0,"ax",@progbits
.globl _start
_start:
  csrw mie, zero
  csrci mstatus, 8
  la t0, fail
  csrw mtvec, t0
#if CASE == 0
  li t0, 17
  li t1, 25
#elif CASE == 1
  li t0, 100
  li t1, 99
#elif CASE == 2
  li t0, 123
  li t1, 456
#elif CASE == 3
  li t0, -1
  li t1, 1
#else
#error Unsupported_CASE
#endif
  li t2, 77
  j pair0
.org 0x200
.globl pair0
pair0:
#if CASE == 0
  add t2, t0, t1
#elif CASE == 1
  addi t2, t0, -7
#elif CASE == 2
  addi t2, zero, -1
#elif CASE == 3
  add t2, t0, t1
#endif
#if CASE == 0
  li t3, 42
#elif CASE == 1
  li t3, 93
#elif CASE == 2
  li t3, -1
#elif CASE == 3
  li t3, 0
#endif
  beq t2, t3, 7f
  j fail
7:
  beqz zero, 8f
  j fail
8:
  la t3, done0
  li t4, 1
  fence rw, rw
  sw t4, 0(t3)
1: j 1b

.section .text.ctx1,"ax",@progbits
.globl context1
context1:
  csrw mie, zero
  csrci mstatus, 8
  la t0, fail
  csrw mtvec, t0
#if CASE == 0
  li t0, 123
  li t1, 500
#elif CASE == 1
  li t0, 200
  li t1, 34
#elif CASE == 2
  li t0, 333
  li t1, 444
#elif CASE == 3
  li t0, 0x7fffffffffffffff
  li t1, 55
#endif
  li t2, 88
  j pair1
.org 0x200
.globl pair1
pair1:
#if CASE == 0
  addi t2, t0, -5
#elif CASE == 1
  add t2, t0, t1
#elif CASE == 2
  add zero, t0, t1
#elif CASE == 3
  addi t2, t0, 1
#endif
#if CASE == 0
  li t3, 118
#elif CASE == 1
  li t3, 234
#elif CASE == 2
  li t3, 88
#elif CASE == 3
  li t3, 0x8000000000000000
#endif
  beq t2, t3, 7f
  j fail
7:
  beqz zero, 8f
  j fail
8:
  la t3, done0
2:
  lw t4, 0(t3)
  beqz t4, 2b
  fence rw, rw
  li a1, 1
  j exit

.section .text.common,"ax",@progbits
.balign 4
fail:
  csrw mie, zero
  csrci mstatus, 8
  li a1, 3
exit:
  la a0, tohost
  fence rw, rw
  sd a1, 0(a0)
3: j 3b
.section .data,"aw",@progbits
.balign 8
done0: .word 0
.section .tohost,"aw",@progbits
.balign 64
.globl tohost
tohost: .dword 0
.globl fromhost
fromhost: .dword 0
