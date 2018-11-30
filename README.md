RISCV Sail Model
================

This repository contains a model of the RISCV architecture written in
[Sail](https://www.cl.cam.ac.uk/~pes20/sail/). It used to be contained
in the [Sail repository](https://github.com/rems-project/sail).


Building the model:
-------------------

Install Sail via Opam, or build Sail from source and have SAIL_DIR in
your environment pointing to its top-level directory.

```
$ make
```
will build the OCaml simulator in ```platform```, the C simulator in
```riscv_sim```, and the Isabelle model in ```Riscv.thy```, and the Coq
model in ```riscv.v```.

Booting Linux with the C backend:
---------------------------------

The C model needs an ELF-version of the BBL (Berkeley-Boot-Loader)
that contains the Linux kernel as an embedded payload.  It also needs
a DTB (device-tree blob) file describing the platform (say in the file
```spike.dtb```).  Once those are available, the model should be run
as:

```
$ ./riscv_sim -t console.log -b spike.dtb bbl > execution-trace.log 2>&1 &
$ tail -f console.log
```

The ```console.log``` file contains the console boot messages.  Some
information on additional configuration options is available from
```./riscv_sim -h```.

Booting Linux with the OCaml backend:
-------------------------------------

The OCaml model only needs the ELF-version of the BBL, since it can generate its
own DTB.
```
$ ./platform bbl > execution-trace.log 2> console.log
```
Some information on additional configuration options is available from
```./platform -h```.

Generating Linux binaries:
--------------------------

One could directly build Linux and the toolchain using
```https://github.com/sifive/freedom-u-sdk```.  The built ```bbl```
will be available in ```./work/riscv-pk/bbl```.

The DTB can be generated using Spike and the DeviceTree compiler
```dtc``` as:

```
spike --dump-dts . | dtc > spike.dtb
```

(The '.' above is to workaround a minor Spike bug and may not be
needed in future Spike versions.)
