Booting OS images
=================

The Sail model implements a very simple platform based on the one
implemented by the Spike reference simulator.  It implements a console
output port similar to Spike's HTIF (host-target interface) mechanism,
and an interrupt controller based on Spike's CLINT (core-local
interrupt controller).  Console input is not currently supported.

32-bit OS boots require a workaround for the 64-bit HTIF interface,
which is currently not supported.

Booting Linux with the C backend
--------------------------------

The C model needs an ELF-version of the BBL (Berkeley-Boot-Loader)
that contains the Linux kernel as an embedded payload.  It also needs
a DTB (device-tree blob) file describing the platform (say in the file
`spike.dtb`).  Once those are available (see below for suggestions),
the model should be run as:

```
$ ./c_emulator/riscv_sim_<arch> -t console.log -b spike.dtb bbl > execution-trace.log 2>&1 &
$ tail -f console.log
```
The `console.log` file contains the console boot messages. For maximum
performance and benchmarking a model without any execution tracing is
available on the optimize branch (`git checkout optimize`) of this
repository. This currently requires the latest Sail built from source.

Booting Linux with the OCaml backend
------------------------------------

The OCaml model only needs the ELF-version of the BBL, since it can generate its
own DTB.
```
$ ./ocaml_emulator/riscv_ocaml_sim_<arch> bbl > execution-trace.log 2> console.log
```

Caveats for OS boot
-------------------

- Some OS toolchains generate obsolete LR/SC instructions with now
  illegal combinations of `.aq` and `.rl` flags.  You can work-around
  this by changing `riscv_mem.sail` to accept these flags.

- One needs to manually ensure that the DTB used for the C model
  accurately describes the physical memory map implemented in the C
  platform.  This will not be needed once the C model can generate its
  own DTB.

Sample OS images
----------------

This directory contains some sample OS images and support files built
for the basic platform implemented by the model.  They were built with
toolchains that emitted illegal instructions, and require the model to
be patched to boot them:

```
patch -p1 < os-boot/os-boot-patch.diff
```

The device-tree for the 64-bit Sail model is described in `rv64-64mb.dts`.  This file
can be generated using:
```
./ocaml_emulator/riscv_ocaml_sim_RV64 -dump-dts > os-boot/rv64-64mb.dts
```

The device-tree binary for OS boots can be compiled from that source file:
```
dtc < os-boot/rv64-64mb.dts > os-boot/rv64-64mb.dtb
```

The 64-bit Linux image can then be booted as:
```
./c_emulator/riscv_sim_RV64 -b os-boot/rv64-64mb.dtb -t /tmp/console.log os-boot/linux-rv64-64mb.bbl > >(gzip -c - > /tmp/exec-trace.log.gz) 2>&1
tail -f /tmp/console.log
```

The 64-bit FreeBSD image requires hardware PTE update support (`-d`):
```
./c_emulator/riscv_sim_RV64 -d -b os-boot/rv64-64mb.dtb -t /tmp/console.log os-boot/freebsd-rv64.bbl > >(gzip -c - > /tmp/exec-trace.log.gz) 2>&1
```

The 64-bit seL4 image runs its test-suite and requires more memory (`-z`):
```
dtc < os-boot/rv64-2gb.dts > os-boot/rv64-2gb.dtb
./c_emulator/riscv_sim_RV64 -z 2048 -b os-boot/rv64-2gb.dtb -t /tmp/console.log os-boot/sel4-rv64.bbl > >(gzip -c - > /tmp/exec-trace.log.gz) 2>&1
```

Note that the consistency of the `-z` argument and the contents of the
DTB have to be ensured manually for now.
