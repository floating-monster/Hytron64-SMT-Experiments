OUTPUT_ARCH(riscv)
ENTRY(_start)
SECTIONS {
  . = 0x80000000;
  .text.ctx0 : { *(.text.ctx0) }
  . = 0x80001000;
  .text.ctx1 : { *(.text.ctx1) }
  . = 0x80002000;
  .text.common : { *(.text.common) }
  . = 0x80003000;
  .data : { *(.data*) }
  .tohost : { *(.tohost) }
  /DISCARD/ : { *(.comment) *(.riscv.attributes) }
}
ASSERT(pair0 == 0x80000200, "pair0 PC mismatch")
ASSERT(pair1 == 0x80001200, "pair1 PC mismatch")
ASSERT(software_done == 0x80001300, "software_done PC mismatch")
