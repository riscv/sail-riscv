The following is a list of ISA features that are currently captured in
the Sail specification.

- The RV32I and RV64I primary base ISAs.

- The M (multiply/divide), A (atomic), and C (compressed) Standard
  Extensions.

- The Zicsr Control and Status Register Standard Extension.

- The N Standard Extension for User-Level Interrupts.

- The Base Counters and Timers.

- The Machine-Level and Supervisor-Level ISAs for RV32 and RV64.

- Physical Memory Protection (PMP)

For the status of the RVWMO memory consistency model, please see [the
RMEM project](https://github.com/rems-project/rmem).

The Sail specification is parameterized over the following
platform-specific options:

- handling of misaligned data accesses with or without M-mode traps.

- updating of the PTE dirty bit with or without architectural
  exceptions.

- the contents of the `mtval` register on an illegal instruction
  exception.

The following is a list of ISA features that are specified in the
prose ISA specification but that are not yet implemented in the Sail
specification.

- The RV32E and RV64E subsets of the primary base RV32I and RV64I
  integer ISAs.

- The RV128 primary base ISA.

- The F (single-precision) and D (double-precision) Floating-Point
  Standard Extensions.

- An explicit and complete definition of the HINT instructions.  As
  currently implemented, some of them are implicitly implemented as
  NOPs.

- Specification and implementation of Endianness Control.

- A complete implementation of all hardware performance counters.
  These are used to count platform-specific events, and hence
  platform-dependent.

- A specification of the Physical Memory Attributes (PMAs) for the
  physical memory map.

- The Hypervisor Extension.
