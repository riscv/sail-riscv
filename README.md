RISCV Sail Model
================

This repository contains a formal specification of the RISC-V architecture, written in
[Sail](https://www.cl.cam.ac.uk/~pes20/sail/) ([repo](https://github.com/rems-project/sail)).   It has been adopted by the RISC-V Foundation.  As of 2021-08-24, the repo has been moved from <https://github.com/rems-project/sail-riscv> to <https://github.com/riscv/sail-riscv>.

The model specifies
assembly language formats of the instructions, the corresponding
encoders and decoders, and the instruction semantics.
The current status of its
coverage of the prose RISC-V specification is summarized
[here](doc/Status.md).
A [reading guide](doc/ReadingGuide.md) to the model is provided in the
[doc/](doc/) subdirectory, along with a guide on [how to
extend](doc/ExtendingGuide.md) the model. 


Latex definitions can be generated from the model that are suitable
for inclusion in reference documentation.  Drafts of the RISC-V
[unprivileged](https://github.com/rems-project/riscv-isa-manual/blob/sail/release/riscv-spec-sail-draft.pdf)
and [privileged](https://github.com/rems-project/riscv-isa-manual/blob/sail/release/riscv-privileged-sail-draft.pdf)
specifications that include the Sail formal definitions are available
in the sail branch of this [risc-v-isa-manual repository](https://github.com/rems-project/riscv-isa-manual/tree/sail).
The process to perform this inclusion is explained [here](https://github.com/rems-project/riscv-isa-manual/blob/sail/README.SAIL).

This is one of [several formal models](https://github.com/riscv/ISA_Formal_Spec_Public_Review/blob/master/comparison_table.md) that were compared within the 
[RISC-V ISA Formal Spec Public Review](https://github.com/riscv/ISA_Formal_Spec_Public_Review).

Sail Model for RISC-V Pack Extension
================

This branch add all instructions in [RISC-V Pack-extension](https://github.com/riscv/riscv-p-spec/blob/master/P-ext-proposal.adoc). The code is contributed  by  a team including Programming Language Lab (NTHU CS), Academia Sinica(Taiwan), and Andes Technology Corporation.

Sail Model for RISC-V Pack Extension Authors
===============
Chuanhua Chang, Andes Technology Corporation;  
Chun-Ping Chung, National Tsing-Hua University(Taiwan); 
Yu-Tse Huang, National Tsing-Hua University(Taiwan);
Chao-Lin Lee, National Tsing-Hua University(Taiwan);
Jenq-Kuen Lee, National Tsing-Hua University(Taiwan);
Yu-Wen Shao, National Tsing-Hua University(Taiwan);
Charlie Su, Andes Technology Corporation;
Chia-Hui Su, National Tsing-Hua University(Taiwan);
Bow-Yaw Wang, Academia Sinica(Taiwan);
Ti-Han Wu, National Tsing-Hua University(Taiwan).

Directory Structure
-------------------

```
sail-riscv
|
+---- model               // Sail specification modules
|     |
|     |+---- riscv_insts_pext_32_compute.sail
|     |+---- riscv_insts_pext_32_mul_64_add.sail
|     |+---- riscv_insts_pext_add.sail
|     |+---- riscv_insts_pext_compare.sail
|     |+---- riscv_insts_pext_cr.sail
|     |+---- riscv_insts_pext_define.sail
|     |+---- riscv_insts_pext_kmda.sail
|     |+---- riscv_insts_pext_misc.sail
|     |+---- riscv_insts_pext_misc32.sail
|     |+---- riscv_insts_pext_msb_add_mul.sail
|     |+---- riscv_insts_pext_mul.sail
|     |+---- riscv_insts_pext_muladdsub.sail
|     |+---- riscv_insts_pext_muladdsub32.sail
|     |+---- riscv_insts_pext_pext_ov.sail
|     |+---- riscv_insts_pext_pack.sail
|     |+---- riscv_insts_pext_pack32.sail
|     |+---- riscv_insts_pext_prelude.sail
|     |+---- riscv_insts_pext_q15_64.sail
|     |+---- riscv_insts_pext_q15.sail
|     |+---- riscv_insts_pext_q32_sat.sail
|     |+---- riscv_insts_pext_shift.sail
|     |+---- riscv_insts_pext_shift32.sail
|     |+---- riscv_insts_pext_sub.sail
|     |+---- riscv_insts_pext_tmp_function_32.sail
|     |+---- riscv_insts_pext_tmp_function_64.sail
|     |+---- riscv_insts_pext_unpack.sail
```

Getting started
---------------

### Building the model

Install [Sail](https://github.com/rems-project/sail/) [using opam](https://github.com/rems-project/sail/blob/sail2/INSTALL.md) then:

```
$ make
```
will build the 64-bit OCaml simulator in
`ocaml_emulator/riscv_ocaml_sim_RV64`, the C simulator in
`c_emulator/riscv_sim_RV64`, the Isabelle model in
`generated_definitions/isabelle/RV64/Riscv.thy`, the Coq model in
`generated_definitions/coq/RV64/riscv.v`, and the HOL4 model in
`generated_definitions/hol4/RV64/riscvScript.sml`.

One can build either the RV32 or the RV64 model by specifying
`ARCH=RV32` or `ARCH=RV64` on the `make` line, and using the matching
target suffix.  RV64 is built by default, but the RV32 model can be
built using:

```
$ ARCH=RV32 make
```

which creates the 32-bit OCaml simulator in
`ocaml_emulator/riscv_ocaml_sim_RV32`, and the C simulator in
`c_emulator/riscv_sim_RV32`, and the prover models in the
corresponding `RV32` subdirectories.

The Makefile targets `riscv_isa_build`, `riscv_coq_build`, and
`riscv_hol_build` invoke the respective prover to process the
definitions.  We have tested Isabelle 2018, Coq 8.8.1, and HOL4
Kananaskis-12.  When building these targets, please make sure the
corresponding prover libraries in the Sail directory
(`$SAIL_DIR/lib/$prover`) are up-to-date and built, e.g. by running
`make` in those directories.

### Executing test binaries

The C and OCaml simulators can be used to execute small test binaries.  The
OCaml simulator depends on the Device Tree Compiler package, which can be
installed in Ubuntu with:

```
$ sudo apt-get install device-tree-compiler
```

Then, you can run test binaries:


```
$ ./ocaml_emulator/riscv_ocaml_sim_<arch>  <elf-file>
$ ./c_emulator/riscv_sim_<arch> <elf-file>
```

A suite of RV32 and RV64 test programs derived from the
[`riscv-tests`](https://github.com/riscv/riscv-tests) test-suite is
included under [test/riscv-tests/](test/riscv-tests/).  The test-suite
can be run using `test/run_tests.sh`.

### Configuring platform options

Some information on additional configuration options for each
simulator is available from `./ocaml_emulator/riscv_ocaml_sim_<arch>
-h` and `./c_emulator/riscv_sim_<arch> -h`.

Some useful options are: configuring whether misaligned accesses trap
(`--enable-misaligned` for C and `-enable-misaligned` for OCaml), and
whether page-table walks update PTE bits (`--enable-dirty-update` for C
and `-enable-dirty-update` for OCaml).

### Experimental integration with riscv-config

There is also (as yet unmerged) support for [integration with riscv-config](https://github.com/rems-project/sail-riscv/pull/43) to allow configuring the compiled model according to a riscv-config yaml specification.

### Booting OS images

For booting operating system images, see the information under the
[os-boot/](os-boot/) subdirectory.

### Using development versions of Sail

Rarely, the version of Sail packaged in opam may not meet your needs. This could happen if you need a bug fix or new feature not yet in the released Sail version, or you are actively working on Sail. In this case you can tell the `sail-riscv` `Makefile` to use a local copy of Sail by setting `SAIL_DIR` to the root of a checkout of the Sail repo when you invoke `make`. Alternatively, you can use `opam pin` to install Sail from a local checkout of the Sail repo as described in the Sail installation instructions.
                        
Licence
-------

The model is made available under the BSD two-clause licence in LICENCE.
