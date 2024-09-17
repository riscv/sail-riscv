RISCV Sail Model
================

This repository contains a formal specification of the RISC-V architecture, written in
[Sail](https://github.com/rems-project/sail).   It has been adopted by the RISC-V Foundation.  As of 2021-08-24, the repo has been moved from <https://github.com/rems-project/sail-riscv> to <https://github.com/riscv/sail-riscv>.

The model specifies
assembly language formats of the instructions, the corresponding
encoders and decoders, and the instruction semantics.
The current status of its
coverage of the prose RISC-V specification is summarized
[here](doc/Status.md).
A [reading guide](doc/ReadingGuide.md) to the model is provided in the
[doc/](doc/) subdirectory, along with a guide on [how to
extend](doc/ExtendingGuide.md) the model.


Latex or AsciiDoc definitions can be generated from the model that are suitable
for inclusion in reference documentation.  Drafts of the RISC-V
[unprivileged](https://github.com/rems-project/riscv-isa-manual/blob/sail/release/riscv-spec-sail-draft.pdf)
and [privileged](https://github.com/rems-project/riscv-isa-manual/blob/sail/release/riscv-privileged-sail-draft.pdf)
specifications that include the Sail formal definitions are available
in the sail branch of this [risc-v-isa-manual repository](https://github.com/rems-project/riscv-isa-manual/tree/sail).
The process to perform this inclusion is explained [here](https://github.com/rems-project/riscv-isa-manual/blob/sail/README.SAIL).
There is also the newer [Sail AsciiDoctor documentation support for RISC-V](https://github.com/Alasdair/asciidoctor-sail/blob/master/doc/built/sail_to_asciidoc.pdf).

This is one of [several formal models](https://github.com/riscv/ISA_Formal_Spec_Public_Review/blob/master/comparison_table.md) that were compared within the 2019
[RISC-V ISA Formal Spec Public Review](https://github.com/riscv/ISA_Formal_Spec_Public_Review).


What is Sail?
-------------

[Sail](https://github.com/rems-project/sail) is a language for describing the instruction-set architecture
(ISA) semantics of processors: the architectural specification of the behaviour of machine instructions. Sail is an
engineer-friendly language, much like earlier vendor pseudocode, but more precisely defined and with tooling to support a wide range of use-cases.
<p>

Given a Sail specification, the tool can type-check it, generate documentation snippets (in LaTeX or AsciiDoc), generate executable emulators, show specification coverage, generate versions of the ISA for relaxed memory model tools, support automated instruction-sequence test generation, generate  theorem-prover definitions for
interactive proof (in Isabelle, HOL4, and Coq), support proof about binary code (in Islaris), and (in progress) generate a reference ISA model in SystemVerilog that can be used for formal hardware verification.
<p>

  <img width="800" src="https://www.cl.cam.ac.uk/~pes20/sail/overview-sail.png?">
<p>

Sail is being used for multiple ISA descriptions, including
essentially complete versions of the sequential behaviour of Arm-A
(automatically derived from the authoritative Arm-internal
specification, and released under a BSD Clear licence with Arm's
permission), RISC-V, CHERI-RISC-V, CHERIoT, MIPS, and CHERI-MIPS; all these are complete
enough to boot various operating systems.  There are also Sail models
for smaller fragments of IBM POWER and x86, including a version of the ACL2 x86 model automatically translated from that.



Example RISC-V instruction specifications
----------------------------------

These are verbatim excerpts from the model file containing the base instructions, [riscv_insts_base.sail](https://github.com/riscv/sail-riscv/blob/master/model/riscv_insts_base.sail), with a few comments added.

### ITYPE (or ADDI)
~~~~~
/* the assembly abstract syntax tree (AST) clause for the ITYPE instructions */

union clause ast = ITYPE : (bits(12), regidx, regidx, iop)

/* the encode/decode mapping between AST elements and 32-bit words */

mapping encdec_iop : iop <-> bits(3) = {
  RISCV_ADDI  <-> 0b000,
  RISCV_SLTI  <-> 0b010,
  RISCV_SLTIU <-> 0b011,
  RISCV_ANDI  <-> 0b111,
  RISCV_ORI   <-> 0b110,
  RISCV_XORI  <-> 0b100
}

mapping clause encdec = ITYPE(imm, rs1, rd, op) <-> imm @ rs1 @ encdec_iop(op) @ rd @ 0b0010011

/* the execution semantics for the ITYPE instructions */

function clause execute (ITYPE (imm, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let immext : xlenbits = sign_extend(imm);
  let result : xlenbits = match op {
    RISCV_ADDI  => rs1_val + immext,
    RISCV_SLTI  => zero_extend(bool_to_bits(rs1_val <_s immext)),
    RISCV_SLTIU => zero_extend(bool_to_bits(rs1_val <_u immext)),
    RISCV_ANDI  => rs1_val & immext,
    RISCV_ORI   => rs1_val | immext,
    RISCV_XORI  => rs1_val ^ immext
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

/* the assembly/disassembly mapping between AST elements and strings */

mapping itype_mnemonic : iop <-> string = {
  RISCV_ADDI  <-> "addi",
  RISCV_SLTI  <-> "slti",
  RISCV_SLTIU <-> "sltiu",
  RISCV_XORI  <-> "xori",
  RISCV_ORI   <-> "ori",
  RISCV_ANDI  <-> "andi"
}

mapping clause assembly = ITYPE(imm, rs1, rd, op)
                      <-> itype_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_signed_12(imm)
~~~~~~

### SRET

~~~~~
union clause ast = SRET : unit

mapping clause encdec = SRET() <-> 0b0001000 @ 0b00010 @ 0b00000 @ 0b000 @ 0b00000 @ 0b1110011

function clause execute SRET() = {
  let sret_illegal : bool = match cur_privilege {
    User       => true,
    Supervisor => not(extensionEnabled(Ext_S)) | mstatus[TSR] == 0b1,
    Machine    => not(extensionEnabled(Ext_S))
  };
  if   sret_illegal
  then { handle_illegal(); RETIRE_FAIL }
  else if not(ext_check_xret_priv (Supervisor))
  then { ext_fail_xret_priv(); RETIRE_FAIL }
  else {
    set_next_pc(exception_handler(cur_privilege, CTL_SRET(), PC));
    RETIRE_SUCCESS
  }
}

mapping clause assembly = SRET() <-> "sret"
~~~~~


Sequential execution
----------

The model builds a C emulator that can execute RISC-V ELF
files, and both emulators provide platform support sufficient to boot
Linux, FreeBSD and seL4. The C emulator can be linked against the Spike emulator for execution with per-instruction tandem-verification.

The C emulator, for the Linux boot, currently runs at approximately
300 KIPS on an Intel i7-7700 (when detailed per-instruction tracing
is disabled), and there are many opportunities for future optimisation
(the Sail MIPS model runs at approximately 1 MIPS). This enables one to
boot Linux in about 4 minutes, and FreeBSD in about 2 minutes. Memory
usage for the C emulator when booting Linux is approximately 140MB.

The files in the C emulator directory implements ELF loading and the
platform devices, defines the physical memory map, and usees command-line
options to select implementation-specific ISA choices.


### Use for specification coverage measurement in testing

The Sail-generated C emulator can measure specification branch
coverage of any executed tests, displaying the results as per-file
tables and as html-annotated versions of the model source.


### Use as test oracle in tandem verification

For tandem verification of random instruction streams, the tools support the
protocols used in [TestRIG](https://github.com/CTSRD-CHERI/TestRIG) to
directly inject instructions into the C emulator and produce trace
information in RVFI format.  This has been used for cross testing
against spike and the [RVBS](https://github.com/CTSRD-CHERI/RVBS)
specification written in Bluespec SystemVerilog.

The C emulator can also be directly linked to Spike, which provides
tandem-verification on ELF binaries (including OS boots).  This is
often useful in debugging OS boot issues in the model when the boot is
known working on Spike.  It is also useful to detect platform-specific
implementation choices in Spike that are not mandated by the ISA
specification.


Concurrent execution
--------------------

The ISA model is integrated with the operational model of the RISC-V
relaxed memory model, RVWMO (as described in an appendix of the [RISC-V
user-level specification](https://github.com/riscv/riscv-isa-manual/releases/tag/draft-20181227-c6741cb)), which is one of the reference models used
in the development of the RISC-V concurrency architecture; this is
part of the [RMEM](http://www.cl.cam.ac.uk/users/pes20/rmem) tool.
It is also integrated with the RISC-V axiomatic concurrency model
 as part of the [isla-axiomatic](https://isla-axiomatic.cl.cam.ac.uk/) tool.

### Concurrent testing


As part of the University of Cambridge/ INRIA concurrency architecture work, those groups produced and
released a library of approximately 7000 [litmus
tests](https://github.com/litmus-tests/litmus-tests-riscv).  The
operational and axiomatic RISC-V concurrency models are in sync for
these tests, and they moreover agree with the corresponding ARM
architected behaviour for the tests in common.

Those tests have also been run on RISC-V hardware, on a SiFive RISC-V
FU540 multicore proto board (Freedom Unleashed), kindly on loan from
Imperas. To date, only sequentially consistent behaviour was observed there.

Generating theorem-prover definitions
--------------------------------------

Sail aims to support the generation of idiomatic theorem prover
definitions across multiple tools. At present it supports Isabelle,
HOL4 and Coq, and the `prover_snapshots` directory provides snapshots of the generated theorem prover
definitions.

These theorem-prover translations can target multiple monads for
different purposes. The first is a state monad with nondeterminism and
exceptions, suitable for reasoning in a sequential setting, assuming
that effectful expressions are executed without interruptions and with
exclusive access to the state.

For reasoning about concurrency, where instructions execute
out-of-order, speculatively, and non-atomically, there is a free
monad over an effect datatype of memory actions. This monad is also
used as part of the aforementioned concurrency support via the RMEM
tool.


The files under `handwritten_support` provide library definitions for
Coq, Isabelle and HOL4.


Directory Structure
-------------------

```
sail-riscv
- model                   // Sail specification modules
- generated_definitions   // files generated by Sail, in RV32 and RV64 subdirectories
  -  c
  -  lem
  -  isabelle
  -  coq
  -  hol4
  -  latex
- prover_snapshots        // snapshots of generated theorem prover definitions
- handwritten_support     // prover support files
- c_emulator              // supporting platform files for C emulator
- doc                     // documentation, including a reading guide
- test                    // test files
  - riscv-tests           // snapshot of tests from the riscv/riscv-tests github repo
- os-boot                 // information and sample files for booting OS images
```

Getting started
---------------

### Building the model

Install [Sail](https://github.com/rems-project/sail/) [using opam](https://github.com/rems-project/sail/blob/sail2/INSTALL.md) then:

```
$ make
```

will build the C simulator in `c_emulator/riscv_sim_RV64`.

If you get an error message saying `sail: unknown option '--require-version'.` it's because your Sail compiler is too old. You need version 0.18 or later.

One can build either the RV32 or the RV64 model by specifying
`ARCH=RV32` or `ARCH=RV64` on the `make` line, and using the matching
target suffix.  RV64 is built by default, but the RV32 model can be
built using:

```
$ ARCH=RV32 make
```

which creates the C simulator in `c_emulator/riscv_sim_RV32`.

The Makefile targets `riscv_isa_build`, `riscv_coq_build`, and
`riscv_hol_build` invoke the respective prover to process the
definitions and produce the Isabelle model in
`generated_definitions/isabelle/RV64/Riscv.thy`, the Coq model in
`generated_definitions/coq/RV64/riscv.v`, or the HOL4 model in
`generated_definitions/hol4/RV64/riscvScript.sml` respectively.
We have tested Isabelle 2018, Coq 8.8.1, and HOL4
Kananaskis-12.  When building these targets, please make sure the
corresponding prover libraries in the Sail directory
(`$SAIL_DIR/lib/$prover`) are up-to-date and built, e.g. by running
`make` in those directories.

### Executing test binaries

The C simulator can be used to execute small test binaries.

```
$ ./c_emulator/riscv_sim_<arch> <elf-file>
```

A suite of RV32 and RV64 test programs derived from the
[`riscv-tests`](https://github.com/riscv/riscv-tests) test-suite is
included under [test/riscv-tests/](test/riscv-tests/).  The test-suite
can be run using `test/run_tests.sh`.

### Configuring platform options

Some information on additional configuration options for each
simulator is available from `./c_emulator/riscv_sim_<arch> -h`.

Some useful options are: configuring whether misaligned accesses trap
(`--enable-misaligned`), and
whether page-table walks update PTE bits (`--enable-dirty-update`).

### Booting OS images

For booting operating system images, see the information under the
[os-boot/](os-boot/) subdirectory.

### Using development versions of Sail

Rarely, the version of Sail packaged in opam may not meet your needs. This could happen if you need a bug fix or new feature not yet in the released Sail version, or you are actively working on Sail. In this case you can tell the `sail-riscv` `Makefile` to use a local copy of Sail by setting `SAIL_DIR` to the root of a checkout of the Sail repo when you invoke `make`. Alternatively, you can use `opam pin` to install Sail from a local checkout of the Sail repo as described in the Sail installation instructions.

Licence
-------

The model is made available under the BSD two-clause licence in LICENCE.

Authors
-------

Originally written by Prashanth Mundkur at SRI International, and further developed by others, especially researchers at the University of Cambridge.

See `LICENCE` and Git blame for a complete list of authors.

Funding
-------

This software was developed by the above within the Rigorous
Engineering of Mainstream Systems (REMS) project, partly funded by
EPSRC grant EP/K008528/1, at the Universities of Cambridge and
Edinburgh.

This software was developed by SRI International and the University of
Cambridge Computer Laboratory (Department of Computer Science and
Technology) under DARPA/AFRL contract FA8650-18-C-7809 ("CIFV"), and
under DARPA contract HR0011-18-C-0016 ("ECATS") as part of the DARPA
SSITH research programme.

This project has received funding from the European Research Council
(ERC) under the European Union’s Horizon 2020 research and innovation
programme (grant agreement 789108, ELVER).
