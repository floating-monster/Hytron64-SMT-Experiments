OUTPUT_ARCH(riscv)
ENTRY(_start)
SECTIONS
{
  . = 0x80000000;
  .text : { *(.text.init) *(.text .text.*) }
  .rodata : { *(.rodata .rodata.*) }
  . = ALIGN(64);
  .htif : {
    tohost = .;
    QUAD(0);
    . = ALIGN(64);
    fromhost = .;
    QUAD(0);
  }
  .data : { *(.data .data.*) }
  .bss : { *(.bss .bss.*) *(COMMON) }
}
