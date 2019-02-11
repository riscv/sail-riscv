A guide to reading the specification
------------------------------------

The model is written in the Sail language.  Although specifications in
Sail are quite readable as pseudocode, it would help to have the [Sail
manual](https://github.com/rems-project/sail/blob/sail2/manual.pdf) handy.

The model contains the following Sail modules in the `model` directory:

- `prelude.sail` contains useful Sail library functions.  This file
  should be referred to as needed.  The lowest level memory access
  primitives are defined in `prelude_mem.sail`, and are implemented
  by the various Sail backends.

- `riscv_xlen.sail` contains the `XLEN` definition for the model.  It
  can be set for either RV32 or RV64.

- `riscv_types.sail` contains some basic RISC-V definitions.  This
  file should be read first, since it provides basic definitions that
  are used throughout the specification, such as privilege
  levels, registers and register access, interrupt and exception
  definitions and numbering, and types used to define memory accesses.

- `riscv_sys_regs.sail` describes the privileged architectural state,
  viz. M-mode and S-mode CSRs, and contains helpers to interpret their
  content, such as WLRL and WARL fields.  `riscv_sys_control.sail`
  describes interrupt and exception delegation and dispatch, and the
  handling of privilege transitions.

  Since WLRL and WARL fields are intended to capture platform-specific
  functionality, future versions of the model might separate their
  handling functions out into a separate platform-defined file.  The
  current implementation of these functions usually implement the same
  behavior as the Spike emulator.

- `riscv_platform.sail` contains platform-specific functionality for
  the model.  It contains the physical memory map, the local interrupt
  controller, and the MMIO interfaces to the clock, timer and terminal
  devices.  Sail `extern` definitions are used to connect externally
  provided (i.e. external to the Sail model) platform functionality,
  such as those provided by the platform support in the C and OCaml
  emulators.  This file also contains the externally selectable
  options for platform behavior, such as the handling of misaligned
  memory accesses, the handling of PTE dirty-bit updates during
  address translation, etc.  These platform options can be specified
  via command line switches in the C and OCaml emulators.

- `riscv_mem.sail` contains the functions that convert accesses to
  physical addresses into accesses to physical memory, or MMIO
  accesses to the devices provided by the platform, or into the
  appropriate access fault.  This file also contains definitions that
  are used in the weak memory concurrency model.

- `riscv_vmem.sail` describes the S-mode address translation.  It
  contains the definitions and processing of the page-table entries
  and their various permission and status bits, the specification of
  page-table walks, and the selection of the address translation mode.

- Files matching `riscv_insts_*.sail` capture the instruction
  definitions and their assembly language formats.  Each file contains
  the instructions for an extension, with `riscv_insts_base.sail` containing
  the base integer instruction set.  Each instruction is represented
  as a variant clause of the `ast` type, and its execution semantics
  are represented as a clause of the `execute` function. `mapping`
  clauses specify the encoding and decoding of each instruction to and
  from assembly language formats.

- `riscv_step.sail` implements the top-level fetch and execute loop.
  The `fetch` is done in 16-bit granules to handle RVC instructions.
  The `step` function performs the instruction fetch, handles any
  fetch errors, dispatches the execution of each instruction, and
  checks for any pending interrupts that may need to be handled.  A
  `loop` function implements the execute loop, and uses the same HTIF
  (host-target interface) mechanism as the Spike emulator to detect
  termination of execution.

- `riscv_analysis.sail` is used in the formal operational RVWMO memory
  model.

Note that the files above are listed in dependency order, i.e. files
earlier in the order do not depend on later files.
