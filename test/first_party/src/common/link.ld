OUTPUT_ARCH( "riscv" )
ENTRY(_start)

__STACK_SIZE = 0x2000;

MEMORY
{
  /* Match the default configuration in config.json.in, which is roughly based on Spike. */
  /* MMIO peripherals. */
  if_clint (wa) : org = 0x2000000, len = 768k
  if_htif (wa)  : org = 0x20c0000, len = 512k

  /* Main RAM. */
  if_ram (wxa) : org = 0x80000000, len = 512m
}

SECTIONS
{
  /* Go to the start of memory, otherwise GNU ld (but not lld) will
  try to start allocating at 0. */
  . = ORIGIN(if_ram);

  /* Stack first so in theory we get stack overflow detection. */
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

  /* MMIO devices. PMA must make this uncacheable (doesn't
     matter in Sail because there are no caches). */
  .bss.mmio.htif : { *(.bss.mmio.htif) } >if_htif
}
