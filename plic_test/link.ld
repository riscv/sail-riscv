OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
  RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 0x80000000
}

SECTIONS
{
  . = ORIGIN(RAM);

  .text : {
    KEEP(*(.text.init))
    *(.text .text.*)
  } > RAM

  .rodata : {
    *(.rodata .rodata.*)
  } > RAM

  .data : {
    *(.data .data.*)
  } > RAM

  .sdata : {
    PROVIDE(__global_pointer$ = . + 0x800);
    *(.sdata .sdata.*)
    *(.srodata .srodata.*)
  } > RAM

  .bss (NOLOAD) : {
    __bss_start = .;
    *(.sbss .sbss.*)
    *(.bss .bss.*)
    *(COMMON)
    __bss_end = .;
  } > RAM

  /* HTIF symbols (emulator scans 'tohost' symbol) */
  . = ALIGN(8);
  .tohost : { KEEP(*(.tohost)) } > RAM
  .fromhost : { KEEP(*(.fromhost)) } > RAM

  /* simple stack */
  . = ALIGN(16);
  .stack (NOLOAD) : {
    . = . + 0x4000;          /* 16KB */
    PROVIDE(stack_top = .);
  } > RAM
}
