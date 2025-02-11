// This test is WIP.

// // Verify that an access fault caused by making a PTE
// // inaccessible (via PMP in this case) and then having
// // the hardware update it works as expected.
// $[test]
// function test_pte_update_access_fault() -> unit = {
//     // This test relies on hardware PTE update.
//     assert(plat_enable_dirty_update());

//     // Create a page table.


//     // Write a PTE to memory.

//     let pte_address = plat_ram_base();
//     let pte_value = ...;
//     X(1) = pte_address;
//     X(2) = pte_value;

//     assert(execute(STORE(zeros(), 0b0010, 0b0001, WORD, false, false)) == RETIRE_SUCCESS);

//     // Set satp.
//     write_CSR(0x180, ...);

//     // Read from the mapped page to get it into the TLB.

//     // Set up PMAs to prevent access to the PTE.

//     // Magically switch to supervisor mode.
//     cur_privilege = Supervisor;

//     // Try to store to the mapped page. This *should* try to update the PTE and cause an access fault.


// }
