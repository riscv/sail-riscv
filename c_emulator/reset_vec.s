# riscv64-unknown-elf-as reset_vec.s -o reset_vec.o && riscv64-unknown-elf-objdump -d reset_vec.o

# Disable RVC otherwise unimp will be 16 bit.
.option norvc
.attribute arch, "rv32i_zicsr"

1:
    auipc  t0, 0                    # Store current PC in t0
    addi   a1, t0, (16*4)           # Add address of DTB and store in a1.

    csrr   a0, mhartid              # Load hart ID into a0

    lw     t1, (14*4)(t0)           # Load the lower word of the entry point into t1

    not    t2, zero                 # Zero the top word on RV64. This is because
    srli   t2, t2, 16               # it will be sign extended on that platform
    srli   t2, t2, 16               # so might be 0xFFFFFFFF.
    and    t1, t1, t2

    lw     t2, (15*4)(t0)           # Load the upper word of the entry point into t2
    slli   t2, t2, 16
    slli   t2, t2, 16

    or     t1, t1, t2               # OR in the top word (on RV64).
    jr     t1                       # Jump to t1 (the entry address).
    unimp                           # Will cause an illegal instruction exception.
2:
    .8byte -1                       # Placeholder for the entry point value.
3:
