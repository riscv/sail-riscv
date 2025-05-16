/*
TEST NAME: test_endianness
TEST DESCRIPTION:
            1. This test verifies MBE,SBE and UBE functionality along with MPRV in mstatus and status.
            2. This test verified the correct working of big endianness support with signed and unsigned numbers.
            3. This test verified the big endianness support for MMIO addresses (MSIP, MTIME, MTIMECMP, htif).
*/

#include "common/encoding.h"
.global main
.option norvc

#define Umode                       0x0000
#define Smode                       0x0800
//Test values
#define TEST_DATA                   0x12345678
#define TEST_DATA_B                 0x00000078
#define TEST_DATA_HW                0x00005678
#define TEST_DATA_W                 0x12345678
#define TEST_DATA_DW                0x1234567812345678

//After storing in big endian format, data will be 0x78563412, so required data will be
#define TEST_DATA_BE_B              0x00000012
#define TEST_DATA_BE_HW             0x00001234
#define TEST_DATA_BE_W              0x12345678
#define TEST_DATA_BE_DW             0x1234567812345678

//signed
#define TEST_SIGN_DATA              0xFF345678
#define TEST_SIGN_DATA_B            0x00000078
#define TEST_SIGN_DATA_HW           0x00005678
#define TEST_SIGN_DATA_W            0xFF345678
#define TEST_SIGN_DATA_W_64         0xFFFFFFFFFF345678

//After storing in big endian format, data will be 0x785634FF, so required data will be
#define TEST_SIGN_DATA_BE_B         0xFFFFFFFF
#define TEST_SIGN_DATA_BE_HW        0xFFFFFF34
#define TEST_SIGN_DATA_BE_W         0xFF345678

#define TEST_SIGN_DATA_BE_B_64      0xFFFFFFFFFFFFFFFF
#define TEST_SIGN_DATA_BE_HW_64     0xFFFFFFFFFFFFFF34
#define TEST_SIGN_DATA_BE_W_64      0xFFFFFFFFFF345678

#define TEST_SIGN_DATA_BE_B_UNSGN   0x000000FF
#define TEST_SIGN_DATA_BE_HW_UNSGN  0x0000FF34

//Internal values for MBE, SBE, UBE for macros.
#define MBE 0x1
#define SBE 0x2
#define UBE 0x3

//BASE ADDRESSES for MMIOs.
#define RVMODEL_MTIME_BASE			0x0200bff8
#define RVMODEL_MTIME_BASE_HI		0x0200bffc
#define RVMODEL_MTIMECMP_BASE		0x02004000
#define RVMODEL_MTIMECMP_BASE_HI	0x02004004
#define HTIF_TOHOST                 0x00000000A0000000



//Function to go to M to requested Mode.
.macro GOTO_LOWER_MODE LOWER_MODE
    li t2, 0x80                                                     // MPP field mask
    csrrc t3, mstatus, t2                                           // Clear MPP bits
    li t2, \LOWER_MODE                                              // Set MPP to required mode.
    csrrs zero, mstatus, t2                                         // Update mstatus

    // Set mepc to the instruction after mret
    auipc t0, 0                                                     // Get current PC
    addi t0, t0, 0x10                                               // Compute address of instruction after mret
    csrw mepc, t0                                                   // Set mepc

    // Return from M-mode to S-mode
    mret                                                            // Switch to requested mode.
.endm

//Function to go to M to requested Mode.
.macro GO_S_TO_U_MODE
    li t2, 0x100                                                    // SPP field mask - U mode
    csrrc t3, sstatus, t2                                           // Clear SPP bits

    // Set mepc to the instruction after mret
    auipc t0, 0                                                     // Get current PC
    addi t0, t0, 0x10                                               // Compute address of instruction after mret
    csrw sepc, t0                                                   // Set mepc

    // Return from M-mode to S-mode
    sret                                                            // Switch to requested mode.
.endm

.macro RVTEST_GOTO_MMODE
    ecall
.endm

.macro SET_MBE_SBE_UBE _SET _BIT _FAILURE_LBL
    .if __riscv_xlen == 32
        .if \_BIT == 0x1                                                                //check whether MBE, SBE or UBE request
            li t0, MSTATUSH_MBE
        .elseif \_BIT == 0x2
            li t0, MSTATUSH_SBE
        .elseif \_BIT == 0x3
            li t0, MSTATUS_UBE
            .if \_SET == 1                                                              //Handle UBE case here.
                csrs mstatus, t0
                csrr t1, mstatus                                                        //read back to make sure it has written the correct value.
                and t1, t1, t0                                                          //extract only the value of interest.
                beqz t1, \_FAILURE_LBL                                                           //if not set, jump to failure.
            .else
                csrc mstatus, t0
                csrr t1, mstatus                                                        //read back to make sure it has written the correct value.
                and t1, t1, t0                                                          //extract only the value of interest.
                bnez t1, \_FAILURE_LBL                                                            //if set, jump to failure.
            .endif
        .endif
        .if (\_SET == 1) & ((\_BIT == 1) | (\_BIT == 2))                                //Handle the MBE, SBE case only.
            csrs mstatush, t0
            csrr t1, mstatush                                                           //read back to make sure it has written the correct value.
            and t1, t1, t0                                                              //extract only the value of interest.
            beqz t1, \_FAILURE_LBL                                                               //if not set, jump to failure.
        .elseif (\_SET == 0) & ((\_BIT == 1) | (\_BIT == 2))
            csrc mstatush, t0
            csrr t1, mstatush                                                           //read back to make sure it has written the correct value.
            and t1, t1, t0                                                              //extract only the value of interest.
            bnez t1, \_FAILURE_LBL                                                               //if set, jump to failure.
        .endif
    .else
        .if \_BIT == 0x1                                                                //check whether MBE, SBE or UBE request
            li t0, MSTATUS_MBE
        .elseif \_BIT == 0x2
            li t0, MSTATUS_SBE
        .elseif \_BIT == 0x3
            li t0, MSTATUS_UBE
        .endif
        .if \_SET == 1
            csrs mstatus, t0
            csrr t1, mstatus                                                            //read back to make sure it has written the correct value.
            and t1, t1, t0                                                              //extract only the value of interest.
            beqz t1, \_FAILURE_LBL                                                               //if not set, jump to failure.
        .else
            csrc mstatus, t0
            csrr t1, mstatus                                                            //read back to make sure it has written the correct value.
            and t1, t1, t0                                                              //extract only the value of interest.
            bnez t1, \_FAILURE_LBL                                                               //if set, jump to failure.
        .endif
    .endif
.endm

.macro SET_SSTATUS_UBE _SET _FAILURE_LBL
    li t0, SSTATUS_UBE
    .if \_SET == 1
        csrs sstatus, t0
        csrr t1, sstatus                                                                //read back to make sure it has written the correct value.
        and t1, t1, t0                                                                  //extract only the value of interest.
        beqz t1, \_FAILURE_LBL                                                                   //if not set, jump to failure.
    .else
        csrc sstatus, t0
        csrr t1, sstatus                                                                //read back to make sure it has written the correct value.
        and t1, t1, t0                                                                  //extract only the value of interest.
        bnez t1, \_FAILURE_LBL                                                                   //if set, jump to failure.
    .endif
.endm

.macro TEST_BASIC_INSTRS _IS_ENABLED _FAILURE_LBL
    li t0, TEST_DATA
    la t1, rvtest_data

    .if \_IS_ENABLED
        li t2, TEST_DATA_BE_B
        li t3, TEST_DATA_BE_HW
        li t4, TEST_DATA_BE_W

        //Stores
        sb t0, 0(t1)
        sh t0, 4(t1)
        sw t0, 8(t1)

        lb t0, 8(t1)                                                            //Load a byte from where a complete word is stored
        bne t0, t2, \_FAILURE_LBL
        lh t0, 8(t1)
        bne t0, t3, \_FAILURE_LBL
        lw t0, 8(t1)
        bne t0, t4, \_FAILURE_LBL

        lbu t0, 8(t1)                                                            //Load a unsigned byte from where a complete word is stored
        bne t0, t2, \_FAILURE_LBL
        lhu t0, 8(t1)
        bne t0, t3, \_FAILURE_LBL


        //Verification of signed loads
        li t0, TEST_SIGN_DATA
        la t1, rvtest_data1

        li t2, TEST_SIGN_DATA_BE_B
        li t3, TEST_SIGN_DATA_BE_HW
        li t4, TEST_SIGN_DATA_BE_W

        //Stores
        sb t0, 0(t1)
        sh t0, 4(t1)
        sw t0, 8(t1)

        lb t0, 8(t1)                                                            //Load a byte from where a complete word is stored
        .if __riscv_xlen == 64
            li t2, TEST_SIGN_DATA_BE_B_64
        .endif
        bne t0, t2, \_FAILURE_LBL
        lh t0, 8(t1)
        .if __riscv_xlen == 64
            li t3, TEST_SIGN_DATA_BE_HW_64
        .endif
        bne t0, t3, \_FAILURE_LBL
        lw t0, 8(t1)
        .if __riscv_xlen == 64
            li t4, TEST_SIGN_DATA_BE_W_64
        .endif
        bne t0, t4, \_FAILURE_LBL

        li t2, TEST_SIGN_DATA_BE_B_UNSGN
        li t3, TEST_SIGN_DATA_BE_HW_UNSGN

        lbu t0, 8(t1)                                                            //Load a unsigned byte from where a complete word is stored
        bne t0, t2, \_FAILURE_LBL
        lhu t0, 8(t1)
        bne t0, t3, \_FAILURE_LBL

    .else

        li t0, TEST_DATA
        la t1, rvtest_data

        li t2, TEST_DATA_B
        li t3, TEST_DATA_HW
        li t4, TEST_DATA_W

        //Stores
        sb t0, 0(t1)
        sh t0, 4(t1)
        sw t0, 8(t1)

        lb t0, 8(t1)                                                            //Load a byte from where a complete word is stored
        bne t0, t2, \_FAILURE_LBL
        lh t0, 8(t1)
        bne t0, t3, \_FAILURE_LBL
        lw t0, 8(t1)
        bne t0, t4, \_FAILURE_LBL

        lbu t0, 8(t1)                                                            //Load a unsigned byte from where a complete word is stored
        bne t0, t2, \_FAILURE_LBL
        lhu t0, 8(t1)
        bne t0, t3, \_FAILURE_LBL

        //Verification of signed loads
        li t0, TEST_SIGN_DATA
        la t1, rvtest_data1

        li t2, TEST_SIGN_DATA_B
        li t3, TEST_SIGN_DATA_HW
        li t4, TEST_SIGN_DATA_W

        //Stores
        sb t0, 0(t1)
        sh t0, 4(t1)
        sw t0, 8(t1)

        lb t0, 8(t1)                                                            //Load a byte from where a complete word is stored
        bne t0, t2, \_FAILURE_LBL
        lh t0, 8(t1)
        bne t0, t3, \_FAILURE_LBL
        lw t0, 8(t1)
        .if __riscv_xlen == 64
            li t4, TEST_SIGN_DATA_W_64
        .endif
        bne t0, t4, \_FAILURE_LBL

        lbu t0, 8(t1)                                                            //Load a unsigned byte from where a complete word is stored
        bne t0, t2, \_FAILURE_LBL
        lhu t0, 8(t1)
        bne t0, t3, \_FAILURE_LBL

    .endif
.endm

.macro TEST_MMIO _IS_ENABLED _FAILURE_LBL
    li t1, TEST_DATA_W
    li t3, TEST_DATA_BE_W
    li t5, 0x0

    .if \_IS_ENABLED
        //Checkpoint 1: MTIMECMP
        li t0, RVMODEL_MTIMECMP_BASE
        li t1, TEST_DATA_W
        sw t1, 0(t0)
        .if __riscv_xlen == 64
            li t1, TEST_DATA_DW
            li t4, TEST_DATA_BE_DW
            sd t1, 0(t0)
            ld t2, 0(t0)
            bne t4, t2, \_FAILURE_LBL
        .endif
        lw t2, 0(t0)
        bne t3, t2, \_FAILURE_LBL
        .if __riscv_xlen == 32
            lw t2, 4(t0)
            bne t5, t2, \_FAILURE_LBL
        .endif

        //Checkpoint 2: HTIF TOHOST
        li t0, HTIF_TOHOST
        li t1, TEST_DATA_W
        sw t1, 0(t0)
        .if __riscv_xlen == 64
            li t1, TEST_DATA_DW
            li t4, TEST_DATA_BE_DW
            sd t1, 0(t0)
            ld t2, 0(t0)
            bne t4, t2, \_FAILURE_LBL
        .endif
        lw t2, 0(t0)
        bne t3, t2, \_FAILURE_LBL

    .else
        li t1, TEST_DATA_W
        li t3, TEST_DATA_W
        //Checkpoint 1: MTIMECMP
        li t0, RVMODEL_MTIMECMP_BASE
        li t1, TEST_DATA_W
        sw t1, 0(t0)
        .if __riscv_xlen == 64
            li t1, TEST_DATA_DW
            li t4, TEST_DATA_DW
            sd t1, 0(t0)
            ld t2, 0(t0)
            bne t4, t2, \_FAILURE_LBL
        .endif
        lw t2, 0(t0)
        bne t3, t2, \_FAILURE_LBL
        .if __riscv_xlen == 32
            lw t2, 4(t0)
            bne t5, t2, \_FAILURE_LBL
        .endif

        //Checkpoint 2: HTIF TOHOST
        li t0, HTIF_TOHOST
        li t1, TEST_DATA_W
        sw t1, 0(t0)
        .if __riscv_xlen == 64
            li t1, TEST_DATA_DW
            li t4, TEST_DATA_DW
            sd t1, 0(t0)
            ld t2, 0(t0)
            bne t4, t2, \_FAILURE_LBL
        .endif
        lw t2, 0(t0)
        bne t3, t2, \_FAILURE_LBL

    .endif
.endm
main:
    # This is a very simple self-checking test for endianness conversion cases.
    # Save return address in temporary register we're not using.
    mv t6, ra

    # We will use a custom trap handler for this test.
    la t0, custom_trap_handler
    csrw mtvec, t0
    j TEST_MMODE_MBE

jump_to_failure:
    j fail

/*Checkpoint 1: Verify the functionality of MSTATUSH MBE bit*/
TEST_MMODE_MBE:
    SET_MBE_SBE_UBE 1 MBE jump_to_failure                                                   //enable MBE
    TEST_BASIC_INSTRS 1 jump_to_failure
    TEST_MMIO 1 jump_to_failure
    SET_MBE_SBE_UBE 0 MBE jump_to_failure                                                   //disable MBE
    TEST_BASIC_INSTRS 0 jump_to_failure
    TEST_MMIO 0 jump_to_failure
    RVTEST_GOTO_MMODE

/*Checkpoint 2: Verify the functionality of MSTATUSH SBE bit*/
TEST_SMODE_SBE:
    SET_MBE_SBE_UBE 1 SBE jump_to_failure                                                    //enable SBE
    GOTO_LOWER_MODE Smode
    TEST_BASIC_INSTRS 1 jump_to_failure
    TEST_MMIO 1 jump_to_failure

    RVTEST_GOTO_MMODE

    SET_MBE_SBE_UBE 0 SBE jump_to_failure                                                    //disable SBE
    GOTO_LOWER_MODE Smode
    TEST_BASIC_INSTRS 0 jump_to_failure
    TEST_MMIO 0 jump_to_failure

    RVTEST_GOTO_MMODE

/*Checkpoint 3: Verify the functionality of MSTATUS UBE bit*/
TEST_UMODE_UBE:
    SET_MBE_SBE_UBE 1 UBE jump_to_failure                                                    //enable UBE
    GOTO_LOWER_MODE Umode
    TEST_BASIC_INSTRS 1 jump_to_failure
    TEST_MMIO 1 jump_to_failure

    RVTEST_GOTO_MMODE

    SET_MBE_SBE_UBE 0 UBE jump_to_failure                                                    //disable UBE
    GOTO_LOWER_MODE Umode
    TEST_BASIC_INSTRS 0 jump_to_failure
    TEST_MMIO 0 jump_to_failure

    RVTEST_GOTO_MMODE

// The following verifies the test case in which the sstatus[UBE] is set, then user mode big endianness is enabled.
/*Checkpoint 4: Verify the functionality of MSTATUS UBE bit*/
TEST_SMODE_UBE:
    GOTO_LOWER_MODE Smode                                                       //GO to S mode.
    SET_SSTATUS_UBE 1 fail                                                      //enable UBE
    GO_S_TO_U_MODE                                                              //GO to U mode.
    TEST_BASIC_INSTRS 1 fail
    TEST_MMIO 1 fail

    RVTEST_GOTO_MMODE

    GOTO_LOWER_MODE Smode                                                       //GO to S mode.
    SET_SSTATUS_UBE 0 fail                                                      //enable UBE
    GO_S_TO_U_MODE                                                              //GO to U mode.
    TEST_BASIC_INSTRS 0 fail
    TEST_MMIO 0 fail

    RVTEST_GOTO_MMODE

//This verifies the mprv test case.
/*Checkpoint 5: Verify the functionality of MSTATUS SBE bit with MPRV*/
TEST_SMODE_SBE_MPRV_CASE:
    SET_MBE_SBE_UBE 1 SBE fail                                                   //enable SBE
    // Enable MPRV (restore normal M-mode accesses)
    csrr t0, mstatus        # Read mstatus
    li t1, (1 << 17)        # MPRV bit (bit 17)
    li t2, (1 << 11)        # Set MPP=01 (S-mode) to simulate S-mode memory accesses
    or t0, t0, t1           # Enable MPRV
    or t0, t0, t2           # Set MPP=01 (S-mode)
    csrw mstatus, t0        # Write back to mstatus
    TEST_BASIC_INSTRS 1 fail
    TEST_MMIO 1 fail

    # Disable MPRV (restore normal M-mode accesses)
    csrr t0, mstatus        # Read mstatus
    li t1, ~(1 << 17)       # Mask to clear MPRV bit
    and t0, t0, t1          # Clear MPRV
    csrw mstatus, t0        # Write back mstatus
    SET_MBE_SBE_UBE 0 SBE fail                                                  //disable SBE
    # Enable MPRV (restore normal M-mode accesses)
    csrr t0, mstatus        # Read mstatus
    li t1, (1 << 17)        # MPRV bit (bit 17)
    li t2, (1 << 11)        # Set MPP=01 (S-mode) to simulate S-mode memory accesses
    or t0, t0, t1           # Enable MPRV
    or t0, t0, t2           # Set MPP=01 (S-mode)
    csrw mstatus, t0        # Write back to mstatus
    TEST_BASIC_INSTRS 0 fail
    TEST_MMIO 0 fail

    # Disable MPRV (restore normal M-mode accesses)
    csrr t0, mstatus        # Read mstatus
    li t1, ~(1 << 17)       # Mask to clear MPRV bit
    and t0, t0, t1          # Clear MPRV
    csrw mstatus, t0        # Write back mstatus

//This verifies the mprv test case.
/*Checkpoint 6: Verify the functionality of MSTATUS SBE bit with MPRV*/
TEST_UMODE_UBE_MPRV_CASE:
    SET_MBE_SBE_UBE 1 UBE fail                                                  //enable UBE
    # Enable MPRV (restore normal M-mode accesses)
    csrr t0, mstatus        # Read mstatus
    li t1, (1 << 17)        # MPRV bit (bit 17)
    li t2, ~(3 << 11)       # Mask to clear MPP field (bits 12:11)
    and t0, t0, t2          # Clear MPP bits in t0
    or  t0, t0, t1          # Set MPRV bit in t0
    csrw mstatus, t0        # Write back to mstatus
    TEST_BASIC_INSTRS 1 fail
    TEST_MMIO 1 fail

    # Disable MPRV (restore normal M-mode accesses)
    csrr t0, mstatus        # Read mstatus
    li t1, ~(1 << 17)       # Mask to clear MPRV bit
    and t0, t0, t1          # Clear MPRV
    csrw mstatus, t0        # Write back mstatus
    SET_MBE_SBE_UBE 0 UBE fail                                                  //disable UBE
    # Enable MPRV (restore normal M-mode accesses)
    csrr t0, mstatus        # Read mstatus
    li t1, (1 << 17)        # MPRV bit (bit 17)
    li t2, ~(3 << 11)       # Mask to clear MPP field (bits 12:11)
    and t0, t0, t2          # Clear MPP bits in t0
    or  t0, t0, t1          # Set MPRV bit in t0
    csrw mstatus, t0        # Write back to mstatus
    TEST_BASIC_INSTRS 0 fail
    TEST_MMIO 0 fail

    # Disable MPRV (restore normal M-mode accesses)
    csrr t0, mstatus        # Read mstatus
    li t1, ~(1 << 17)       # Mask to clear MPRV bit
    and t0, t0, t1          # Clear MPRV
    csrw mstatus, t0        # Write back mstatus

pass:
    jal DISABLE_ENDIANESS
    li a0, 0
    mv ra, t6
    ret
fail:
    #disable endianness to exit the code cleanly...
    jal DISABLE_ENDIANESS
    li a0, 1
    mv ra, t6
    ret

DISABLE_ENDIANESS:
    RVTEST_GOTO_MMODE
    SET_MBE_SBE_UBE 0 MBE fail                                                   //disable MBE

    ret

.align 4
rvtest_data:
.word 0x00000000
.word 0x00000000
.word 0x00000000

.align 4
rvtest_data1:
.word 0x00000000
.word 0x00000000
.word 0x00000000


//We don't expect any traps in this test, so let's keep it minimal.
custom_trap_handler:
    # Set mstatus.MPP = 11 (M-mode) to return to M-mode
    csrr t0, mstatus        # Read mstatus
    li t1, ~(3 << 11)       # Mask to clear MPP bits
    and t0, t0, t1          # Clear MPP field
    li t1, (3 << 11)        # Set MPP = 11 (M-mode)
    or t0, t0, t1           # Apply new MPP value
    csrw mstatus, t0        # Write back mstatus

    # Set mepc to the instruction after ecall (to resume execution in M-mode)
    csrr t0, mepc           # Read the saved PC (where ecall was issued)
    addi t0, t0, 4          # Move to next instruction (skip ecall)
    csrw mepc, t0           # Set updated mepc

    mret                    # Return to M-mode
