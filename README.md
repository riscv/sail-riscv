# RISCV Sail Model

This repository contains a formal specification of the RISC-V architecture, written in
[Sail](https://github.com/rems-project/sail). It has been adopted by RISC-V International.

The model specifies assembly language formats of the instructions, the corresponding
encoders and decoders, and the instruction semantics. A [reading guide](doc/ReadingGuide.md)
to the model is provided in the [doc/](doc/) subdirectory, along with a guide on [how to
extend](doc/ExtendingGuide.md) the model.

## What is Sail?

[Sail](https://github.com/rems-project/sail) is a language for describing the instruction-set architecture
(ISA) semantics of processors: the architectural specification of the behaviour of machine instructions. Sail is an
engineer-friendly language, much like earlier vendor pseudocode, but more precisely defined and with tooling to support a wide range of use-cases.

Given a Sail specification, the tool can type-check it, generate documentation snippets (in LaTeX or AsciiDoc), generate executable emulators, show specification coverage, generate versions of the ISA for relaxed memory model tools, support automated instruction-sequence test generation, generate theorem-prover definitions for
interactive proof (in Isabelle, Rocq, and Lean), support proof about binary code (in Islaris), and (in progress) generate a reference ISA model in SystemVerilog that can be used for formal hardware verification.

<img width="800" src="https://www.cl.cam.ac.uk/~pes20/sail/overview-sail.png?">

## Getting started

### Building the model

Install [Sail](https://github.com/rems-project/sail/). On Linux you can download a [binary release](https://github.com/rems-project/sail/releases) (strongly recommended), or you can install from source [using opam](https://github.com/rems-project/sail/blob/sail2/INSTALL.md). Then:

```
$ ./build_simulators.sh
```

will build the simulator at `build/c_emulator/sail_riscv_sim`.

If you get an error message saying `sail: unknown option '--require-version'.` it's because your Sail compiler is too old. You need version 0.19.1 or later.

By default `build_simulators.sh` will download and build [libgmp](https://gmplib.org/).
To use a system installation of libgmp, run `env DOWNLOAD_GMP=FALSE ./build_simulators.sh` instead.

### Executing test binaries

The simulator can be used to execute small test binaries.

```
$ build/c_emulator/sail_riscv_sim <elf-file>
```

Test suites targeting RV32, RV64, and RVV (RISC-V Vector Extension) are downloaded automatically when enabled.
The standard `riscv-tests` suite is enabled by default, while vector extension tests
can be enabled via CMake options such as `-DENABLE_RISCV_VECTOR_TESTS_V128_E32=ON`.
All enabled test suites can be executed using `make test` or `ctest` in the build directory
(see `test/README.md` for more information).

### Configuring platform options

The model is configured using a JSON file specifying various tunable
options. The default configuration used for the model can be examined
using `build/c_emulator/sail_riscv_sim --print-default-config`. To
use a custom configuration, save the default configuration into a
file, edit it as needed, and pass it to the simulator using the
`--config` option.

Information on other options for the simulator is available from
`build/c_emulator/sail_riscv_sim -h`.

### Booting OS images

For booting operating system images, see the information under the
[os-boot/](os-boot/) subdirectory.

## Supported RISC-V ISA features

### The Sail specification currently captures the following ISA extensions and features:

- RV32I and RV64I base ISAs, v2.1
- RV32E and RV64E base ISAs, v2.0
- Zifencei extension for instruction-fetch fence, v2.0
- Zicsr extension for CSR instructions, v2.0
- Zicntr and Zihpm extensions for counters, v2.0
- Zicond extension for integer conditional operations, v1.0
- Zicbom and Zicboz extensions for cache-block management (Zicbop not currently supported), v1.0
- Zimop extension for May-Be-Operations, v1.0
- Zihintntl extension for Non-temporal Locality Hints, v1.0
- Zihintpause extension for Pause Hint, v2.0
- M extension for integer multiplication and division, v2.0
- Zmmul extension for integer multiplication only, v1.0
- A extension for atomic instructions, v2.1
- Zalrsc extension for load-reserved and store-conditional operations, v1.0
- Zaamo extension for atomic memory operations, v1.0
- Zawrs extension for Wait-on-Reservation-Set instructions, v1.01
- Zabha extension for byte and halfword atomic memory operations, v1.0
- Zacas extension atomic Compare-and-Swap (CAS) instructions, v1.0.0
- F and D extensions for single and double-precision floating-point, v2.2
- Zfh and Zfhmin extensions for half-precision floating-point, v1.0
- Zfa extension for additional floating-point instructions, v1.0
- Zfinx, Zdinx, Zhinx, and Zhinxmin extensions for floating-point in integer registers, v1.0
- C extension for compressed instructions, v2.0
- Zca, Zcf, Zcd, and Zcb extensions for code size reduction, v1.0
- Zcmop extension for compressed May-Be-Operations, v1.0
- B (Zba, Zbb, Zbs) and Zbc extensions for bit manipulation, v1.0
- Zbkb, Zbkc, and Zbkx extensions for bit manipulation for cryptography, v1.0
- Zkn (Zknd, Zkne, Zknh) and Zks (Zksed, Zksh) extensions for scalar cryptography, v1.0.1
- Zkr extension for entropy source, v1.0
- Zkt extension for data independent execution latency, v1.0 (no impact on model)
- V extension for vector operations, v1.0
- Zvbb extension for vector basic bit-manipulation, v1.0
- Zvbc extension for vector carryless multiplication, v1.0
- Zvkb extension for vector cryptography bit-manipulation, v1.0
- Zvkg extension for vector GCM/GMAC, v1.0
- Zvkn extension for vector cryptography NIST Algorithm Suite
- Zvknc extension for vector cryptography NIST Algorithm Suite with carryless multiply
- Zvkned extension for vector cryptography NIST Suite: Vector AES Block Cipher, v1.0
- Zvkng extension for vector cryptography NIST Algorithm Suite with GCM
- Zvknha and Zvknhb extensions for vector cryptography NIST Suite: Vector SHA-2 Secure Hash, v1.0
- Zvks extension for vector cryptography ShangMi Algorithm Suite
- Zvksc extension for vector cryptography ShangMi Algorithm Suite with carryless multiplication
- Zvksed extension for vector cryptography ShangMi Suite: SM4 Block Cipher, v1.0
- Zvksg extension for vector cryptography ShangMi Algorithm Suite with GCM
- Zvksh extension for vector cryptography ShangMi Suite: SM3 Secure Hash, v1.0
- Zvkt extension for vector data independent execution latency, v1.0 (no impact on model)
- Machine, Supervisor, and User modes
- Smcntrpmf extension for cycle and instret privilege mode filtering, v1.0
- Sscofpmf extension for Count Overflow and Mode-Based Filtering, v1.0
- Sstc extension for Supervisor-mode Timer Interrupts, v1.0
- Svinval extension for fine-grained address-translation cache invalidation, v1.0
- Sv32, Sv39, Sv48 and Sv57 page-based virtual-memory systems
- Svbare extension for Bare mode virtual-memory translation
- Physical Memory Protection (PMP)

<!-- Uncomment the following section when unratified extensions are added
The following unratified extensions are supported and can be enabled using the `--enable-experimental-extensions` flag:
-  -->

**For a list of unsupported extensions and features, see the [Extension Roadmap](https://github.com/riscv/sail-riscv/wiki/Extension-Roadmap).**

## Example RISC-V instruction specifications

These are verbatim excerpts from the model file containing the base instructions, [riscv_insts_base.sail](model/riscv_insts_base.sail), with a few comments added.

### ITYPE (or ADDI)

```
/* the instruction clause for the ITYPE instructions */

union clause instruction = ITYPE : (bits(12), regidx, regidx, iop)

/* the encode/decode mapping between instruction elements and 32-bit words */

mapping encdec_iop : iop <-> bits(3) = {
  ADDI  <-> 0b000,
  SLTI  <-> 0b010,
  SLTIU <-> 0b011,
  ANDI  <-> 0b111,
  ORI   <-> 0b110,
  XORI  <-> 0b100
}

mapping clause encdec = ITYPE(imm, rs1, rd, op) <-> imm @ rs1 @ encdec_iop(op) @ rd @ 0b0010011

/* the execution semantics for the ITYPE instructions */

function clause execute (ITYPE (imm, rs1, rd, op)) = {
  let immext : xlenbits = sign_extend(imm);
  X(rd) = match op {
    ADDI  => X(rs1) + immext,
    SLTI  => zero_extend(bool_to_bits(X(rs1) <_s immext)),
    SLTIU => zero_extend(bool_to_bits(X(rs1) <_u immext)),
    ANDI  => X(rs1) & immext,
    ORI   => X(rs1) | immext,
    XORI  => X(rs1) ^ immext
  };
  RETIRE_SUCCESS
}

/* the assembly/disassembly mapping between instruction elements and strings */

mapping itype_mnemonic : iop <-> string = {
  ADDI  <-> "addi",
  SLTI  <-> "slti",
  SLTIU <-> "sltiu",
  XORI  <-> "xori",
  ORI   <-> "ori",
  ANDI  <-> "andi"
}

mapping clause assembly = ITYPE(imm, rs1, rd, op)
                      <-> itype_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_signed_12(imm)
```

### SRET

```
union clause instruction = SRET : unit

mapping clause encdec = SRET()
  <-> 0b0001000 @ 0b00010 @ 0b00000 @ 0b000 @ 0b00000 @ 0b1110011

function clause execute SRET() = {
  let sret_illegal : bool = match cur_privilege {
    User       => true,
    Supervisor => not(currentlyEnabled(Ext_S)) | mstatus[TSR] == 0b1,
    Machine    => not(currentlyEnabled(Ext_S))
  };
  if   sret_illegal
  then Illegal_Instruction()
  else if not(ext_check_xret_priv (Supervisor))
  then Ext_XRET_Priv_Failure()
  else {
    set_next_pc(exception_handler(cur_privilege, CTL_SRET(), PC));
    RETIRE_SUCCESS
  }
}

mapping clause assembly = SRET() <-> "sret"
```

## Sequential execution

The model builds a C emulator that can execute RISC-V ELF
files, and both emulators provide platform support sufficient to boot
Linux, FreeBSD and seL4.

The C emulator, for the Linux boot, currently runs at approximately
300 KIPS on an Intel i7-7700 (when detailed per-instruction tracing
is disabled), and there are many opportunities for future optimisation
(the Sail MIPS model runs at approximately 1 MIPS). This enables one to
boot Linux in about 4 minutes, and FreeBSD in about 2 minutes. Memory
usage for the C emulator when booting Linux is approximately 140MB.

The files in the C emulator directory implements ELF loading and the
platform devices, defines the physical memory map, and uses command-line
options to select implementation-specific ISA choices.

### Use for specification coverage measurement in testing

The Sail-generated C emulator can measure specification branch
coverage of any executed tests, displaying the results as per-file
tables and as html-annotated versions of the model source.

### Use as test oracle in tandem verification

For tandem verification of random instruction streams, the tools support the
protocols used in [TestRIG](https://github.com/CTSRD-CHERI/TestRIG) to
directly inject instructions into the C emulator and produce trace
information in RVFI format. This has been used for cross testing
against spike and the [RVBS](https://github.com/CTSRD-CHERI/RVBS)
specification written in Bluespec SystemVerilog.

## Concurrent execution

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
tests](https://github.com/litmus-tests/litmus-tests-riscv). The
operational and axiomatic RISC-V concurrency models are in sync for
these tests, and they moreover agree with the corresponding ARM
architected behaviour for the tests in common.

Those tests have also been run on RISC-V hardware, on a SiFive RISC-V
FU540 multicore proto board (Freedom Unleashed), kindly on loan from
Imperas. To date, only sequentially consistent behaviour was observed there.

## Generating theorem-prover definitions

Sail aims to support the generation of idiomatic theorem prover
definitions across multiple tools. At present it supports Isabelle,
Rocq, and Lean.

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
each prover.

## Directory Structure

```
sail-riscv
- model                   // Sail specification modules
- handwritten_support     // prover support files
- c_emulator              // supporting platform files for C emulator
- cmake                   // extra build system modules
- dependencies            // external dependencies (currently only SoftFloat)
- sail_runtime            // build files for sail runtime
- doc                     // documentation, including a reading guide
- test                    // CMake test setup and URL references for RISC-V test suites
  - first_party           // custom C and assembly tests for the model
- os-boot                 // information and sample files for booting OS images
```

## Licence

The model is made available under the BSD two-clause licence in LICENCE.

## Authors

Originally written by Prashanth Mundkur at SRI International, and further developed by others, especially researchers at the University of Cambridge.

See `LICENCE` and Git blame for a complete list of authors.

## Funding

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
