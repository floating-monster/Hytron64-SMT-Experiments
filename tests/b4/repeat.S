#ifndef CASE
#define CASE 0
#endif
#define ROUNDS 1024
.option norvc
.option norelax
.section .text.ctx0,"ax",@progbits
.globl _start
_start:
  csrw mie, zero
  csrci mstatus, 8
  la t0, fail
  csrw mtvec, t0
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
  li t3, 17+ROUNDS
#elif CASE == 1
  li t3, 17+25*ROUNDS
#elif CASE == 2
  li t3, ROUNDS-1
#endif
  beq t2, t3, 1f
  j fail
1:
  la t3, done0
  li t4, 1
  fence rw, rw
  sw t4, 0(t3)
2: j 2b

.section .text.ctx1,"ax",@progbits
.globl context1
context1:
  csrw mie, zero
  csrci mstatus, 8
  la t0, fail
  csrw mtvec, t0
  li s0, ROUNDS
#if CASE == 0 || CASE == 1
  li t2, 123
#elif CASE == 2
  li t2, 0x7fffffffffffffff
#endif
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
  li t3, 123+3*ROUNDS
#elif CASE == 1
  li t3, 123-5*ROUNDS
#elif CASE == 2
  li t3, 0x80000000000003ff
#endif
  beq t2, t3, 3f
  j fail
3:
  la t3, done0
4:
  lw t4, 0(t3)
  beqz t4, 4b
  fence rw, rw
  j software_done
.org 0x300
.globl software_done
software_done:
  nop
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
5: j 5b
.section .data,"aw",@progbits
.balign 8
done0: .word 0
.section .tohost,"aw",@progbits
.balign 64
.globl tohost
tohost: .dword 0
.globl fromhost
fromhost: .dword 0
