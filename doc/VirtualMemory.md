# Notes on the implementation of virtual memory

[vmem_types.sail](../model/core/vmem_types.sail) contains type
definitions for the core types used in the virtual memory
specification. The primary vmem specification code is in
[vmem.sail](../model/sys/vmem.sail).
[vmem_pte.sail](../model/sys/vmem_pte.sail) describes page
table entries, processing them for validity and permissions checks,
and their updates. [vmem_ptw.sail](../model/sys/vmem_ptw.sail)
describes page table walk exceptions.

[vmem_tlb.sail](../model/sys/vmem_tlb.sail) implements a
simple TLB (Translation Look-Aside Buffer). Although TLBs are not
specified by RISC-V architecture, it is useful to model at least a
minimal TLB so that we can demonstrate and test `SFENCE.VMA`
functionality (without TLBs, `SFENCE.VMA` is a no-op and there's
nothing to test).

TLBs are also useful for simulation speed. Without a TLB, every Fetch
and Load/Store/AMO in virtual memory mode requires a full page table
walk. Speed matters mostly for large simulations (e.g., Linux-boot
can speed up from tens of minutes to a few minutes).

The main code in [vmem.sail](../model/sys/vmem.sail) is
structured and commented to make it easy to ignore/skip TLB-related
parts.

The external execution code for instruction fetch, load, store and AMO
invoke `translateAddr()` and receive a result of `TR_Result` type.
`translateAddr()`, in turn, invokes `translate_vs_stage()` and
`translate_g_stage()` for 2-stage address translation, which in turn
call `translate_stage()`. `translate_stage()` contains Step 1 of the
Virtual Address Translation Process (VATP) algorithm specified in the
manual, and calls `translate()`, which in turn calls
`translate_TLB_miss()` and `translate_TLB_hit()` to handle the TLB.
The latter two functions contain the remaining steps of the VATP.
`pt_walk()` implements the page-table walk, and invokes `mem_read()`
and `mem_write_value()` (from [mem.sail](../model/sys/mem.sail)) to
read and write PTEs (Page Table Entries) from physical memory.

The `satp`, `hgatp` and `vsatp` registers live in
[vmem.sail](../model/sys/vmem.sail) and are accessed by the general
`readCSR()` and `writeCSR()` functions.
