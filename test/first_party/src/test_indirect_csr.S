.global main
main:
    # Self-checking test for the indirect CSR access framework
    # (Smcsrind / Sscsrind): miselect/siselect.
    #
    # This test exercises only what the framework provides on its own,
    # without any extension (such as the AIA) registering an implemented
    # indirect select. It checks that:
    #   - miselect is writable and reads back the written value,
    #   - siselect is writable and reads back the written value.
    #
    # Note: mireg/sireg are deliberately not accessed here. Without an
    # extension registering an implemented select, no select value is
    # implemented, so accessing mireg/sireg would raise an illegal
    # instruction. The AIA (commit that adds Smaia/Ssaia) adds a test
    # that exercises mireg/sireg via the iprio array selects.

    # CSR addresses.
    .set CSR_MISELECT, 0x350
    .set CSR_SISELECT, 0x150

    # An arbitrary select value to write and read back.
    .set SELECT_VALUE, 0x30

    # Save return address in a temporary we do not otherwise use.
    mv t6, ra

    # ---------------------------------------------------------------
    # Machine level: miselect is writable and reads back.
    # ---------------------------------------------------------------
    li t0, SELECT_VALUE
    csrw CSR_MISELECT, t0
    csrr t1, CSR_MISELECT
    bne t0, t1, fail

    # A second value, to confirm it is not stuck.
    li t0, 0x3F
    csrw CSR_MISELECT, t0
    csrr t1, CSR_MISELECT
    bne t0, t1, fail

    # ---------------------------------------------------------------
    # Supervisor level: siselect is writable and reads back (accessed
    # from M-mode, which is always permitted; the stateen gating only
    # affects lower privileges).
    # ---------------------------------------------------------------
    li t0, SELECT_VALUE
    csrw CSR_SISELECT, t0
    csrr t1, CSR_SISELECT
    bne t0, t1, fail

    li t0, 0x3F
    csrw CSR_SISELECT, t0
    csrr t1, CSR_SISELECT
    bne t0, t1, fail

pass:
    li a0, 0
    mv ra, t6
    ret
fail:
    li a0, 1
    mv ra, t6
    ret
