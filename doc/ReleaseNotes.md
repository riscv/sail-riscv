# Release notes for the upcoming 0.8 release

This is a major release with some backwards-incompatible changes.

The highlights of the release are:

- A single executable binary for the various ISA versions (RV32/RV64)
  and floating-point extensions (F/D).

- The introduction of a JSON-based configuration system.

- The use of the Sail module system to provide a modular structure
  to the RISC-V model.

- Many new extensions, including complete coverage of the RVA23 vector
  and vector crypto extensions.

- The removal of obsolete in-tree ELF tests in favor of more recent
  upstream tests (currently from `riscv-software-src/riscv-tests` and
  `chipsalliance/riscv-vector-tests`) in a unified test repo; these
  upstream tests are now used in CI.

- The removal of obsolete in-tree images for OS boot in favor of build
  scripts for more recent Linux boot images.

## Single executable binary

Releases of previous versions of the model had two executable binaries
(`riscv_sim_rv32d` and `riscv_sim_rv64d`) to support the RV32 and RV64
ISAs respectively, that each integrated support for the F and D
extensions. This release provides a single binary (`sail_riscv_sim`)
that can be configured to implement either RV32 or RV64, and either
the F or D extensions, or both.

## JSON-based configuration system

The configuration parameters for the model are now specified in a JSON
file. These parameters include `base.xlen` (which is set to `32` for
RV32 or `64` for RV64), various platform settings and flags to enable
each individual extension, and any parameters for these extensions.
Sample configurations are provided for RV32 (`config/rv32.json`) and
RV64 (`config/rv64.json`).

The `--config` option to `sail_riscv_sim` is used to specify the
configuration file. The default configuration can be printed using
`--print-default-config`. A configuration can be checked for validity
using `--validate-config`.

A JSON schema for the configuration is provided in
`sail_riscv_config_schema.json`.

Several CLI options that were used to specify configuration parameters
are no longer necessary and have been removed.

## Modular model structure

The Sail code in the RISC-V model is now specified in the
`model/riscv.sail_project` file using the module system support in the
Sail language. This project file groups related Sail files into Sail
modules and specifies the dependency structure of these modules.

## New extensions

The following extensions have been added since the 0.7 release:

Zacas, Zawrs, Zimop, Zcmop, Zhinxmin, Zvbc, Zvknha, Zvknhb, Zvksh,
Zvkned, Zvksed, Zvkg

With the latter extensions, the model now provides complete coverage of
the suite of vector extensions needed to pass the
`chipsalliance/riscv-vector-tests` testsuite.

## Other changes

- The model now requires the Sail 0.19.1 compiler version.

- The simulator can now generate a device-tree (using
  `--print-device-tree`) and ISA string (using `--print-isa-string`)
  corresponding to the specified configuration.

- A `--version` option prints the release version of the model.

- A `--build-info` option prints more build information for the model.
  This should be used when reporting issues in the model.

- The CLI help message for the simulator has been improved.

# Release notes for version 0.7

This is the first binary release of the emulators, currently for Linux
x86_64 only. These are statically compiled on Rocky 8 with only glibc
2.17 (from 2012) as a dependency so they should run on most distros.

The tarball includes emulators for RV32D and RV64D. If you need RV32F
or RV64F you must still compile from source.

The JSON file is intended for use with asciidoctor-sail to allow
inclusion of Sail code snippets in documentation.

# Release notes for version 0.6

Currently we do not release binaries for the emulator (it is planned),
so if you are using the emulator we recommend you compile it from the
latest `master`.

This release exists to provide the JSON bundle, which can be used to
embed Sail code into [the ISA manual](https://github.com/riscv/riscv-isa-manual).
