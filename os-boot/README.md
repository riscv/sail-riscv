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

Generating input files for Linux boot
-------------------------------------

One could directly build Linux and the toolchain using
`https://github.com/sifive/freedom-u-sdk`.  The built `bbl`
will be available in `./work/riscv-pk/bbl`.  You will need to configure
a kernel that can be booted on Spike; in particular, it should be
configured to use the HTIF console.

The DTB can be generated using Spike and the DeviceTree compiler
`dtc` as:

```
spike --dump-dts . | dtc > spike.dtb
```

(The '.' above is to work around a minor Spike bug and may not be
needed in future Spike versions.)

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

This directory contains some sample OS images and support files, built
for the basic platform implemented by the model.  They were built with
toolchains that emitted illegal instructions, and require the model to
be patched to boot them:

```
patch -p1 < os-boot/os-boot-patch.diff
```

The device-tree can be compiled from its source:
```
dtc < os-boot/rv64-64mb.dts > os-boot/rv64-64mb.dtb
```

The 64-bit Linux image can then be booted as:
```
./c_emulator/riscv_sim_RV64 -b os-boot/rv64-64mb.dtb -t /tmp/console.log os-boot/linux-rv64-64mb.bbl > >(gzip -c - > /tmp/exec-trace.log.gz) 2>&1
tail -f /tmp/console.log
```

The 64-bit seL4 image runs its test-suite, which can take a very long time in a simulator:
```
./c_emulator/riscv_sim_RV64 -d -b os-boot/rv64-64mb.dtb -t /tmp/console.log os-boot/sel4-rv64.bbl > /tmp/exec-trace.log 2>&1 &
```

The 64-bit FreeBSD image requires hardware PTE update support (`-d`):
```
./c_emulator/riscv_sim_RV64 -d -b os-boot/rv64-64mb.dtb -t /tmp/console.log os-boot/freebsd-rv64.bbl > /tmp/exec-trace.log 2>&1
```
