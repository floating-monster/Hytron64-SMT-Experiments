OUTPUT_ARCH(riscv)
ENTRY(_start)
SECTIONS {
  . = 0x80000000;
  .text.hart0 : { *(.text.hart0) }
  . = 0x80001000;
  .text.hart1 : { *(.text.hart1) }
  . = 0x80002000;
  .text.common : { *(.text.common) }
  . = 0x80003000;
  .data : { *(.data*) }
  .tohost : { *(.tohost) }
  /DISCARD/ : { *(.comment) *(.riscv.attributes) }
}
ASSERT(start0 == 0x80000100, "start0 PC mismatch")
ASSERT(start1 == 0x80001100, "start1 PC mismatch")
ASSERT(pair0 == 0x80000200, "pair0 PC mismatch")
ASSERT(pair1 == 0x80001200, "pair1 PC mismatch")
ASSERT(done_marker0 == 0x80000300, "done0 PC mismatch")
ASSERT(done_marker1 == 0x80001300, "done1 PC mismatch")
ASSERT(joined0 == 0x80000380, "join PC mismatch")
