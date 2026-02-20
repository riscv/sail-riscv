OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
  RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 16M
}

SECTIONS
{
  .text : {
    *(.text.start*)
    *(.text*)
  } > RAM

  .rodata : {
    *(.rodata*)
    *(.srodata*)
  } > RAM

  .data : {
    *(.data*)
    *(.sdata*)
  } > RAM

  .bss : {
    __bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(COMMON)
    __bss_end = .;
  } > RAM

  /* HTIF tohost (Sail uses this to detect end of test) */
  .tohost : ALIGN(8) {
    PROVIDE(tohost = .);
    QUAD(0);
    PROVIDE(fromhost = .);
    QUAD(0);
  } > RAM

  /* simple stack at top of RAM */
  PROVIDE(_stack_top = ORIGIN(RAM) + LENGTH(RAM));
}