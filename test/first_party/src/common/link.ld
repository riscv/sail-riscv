OUTPUT_ARCH( "riscv" )
ENTRY(_start)

__STACK_SIZE = 0x2000;

MEMORY
{
  /* Main RAM. Chosen for compatibility with SPIKE's default options. */
  if_ram (wxa) : org = 0x80000000, len = 512m
  /* MMIO peripherals. */
  if_mmio (wa) : org = 0xa0000000, len = 512k
}

SECTIONS
{
  /* MMIO devices. PMA must make this uncacheable (doesn't
     matter in Sail because there are no caches). */
  .bss.mmio : { *(.bss.mmio) } >if_mmio

  /* Stack first so in theory we get stack overlow detection. */
  .stack ALIGN(16) (NOLOAD) : {
    _stack_end = .;
    . += __STACK_SIZE;
    . = ALIGN(16);
    _stack = .;
  } >if_ram

  /* This just needs to point somewhere vaguely in the middle of all the code. */
  __global_pointer$ = .;

  /* Program code. */
  .text : { *(.text) } >if_ram

  /* Compile-time global variables */
  .data : { *(.data) } >if_ram

  /* Read-only compile-time global variables */
  .rodata : { *(.rodata) } >if_ram

  /* Uninitialized global variables */
  .bss (NOLOAD) : { *(.bss) } >if_ram
  .sbss : {
    *(.sbss .sbss.* .gnu.linkonce.sb.*)
    *(.scommon)
  } >if_ram

  /* Thread-local data */
  .tdata : { *(.tdata) } >if_ram
  .tbss : { *(.tbss) } >if_ram
}
