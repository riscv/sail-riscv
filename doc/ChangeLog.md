# Release notes for the next version

- Updates to the [configuration file](../config/config.json.in):
  - The CLINT and simple interrupt generator can be marked as not
    supported for platforms that do not contain these MMIO devices;
    see `platform.clint.supported` and `platform.simple_interrupt_generator.supported`.
  - An option to control whether reservations can be cancelled by stores
    by the same hart to the reservation set has been added; see
    `platform.reservation.invalidate_on_same_hart_store`. This defaults
    to false to match previous behavior.

# Release notes for version 0.11

- Updates to the [configuration file](../config/config.json.in):
  - PMAs now have additional attributes (see `memory.regions`):
    - `mem_type` for the type of memory covered by the region,
      which can be either `MainMemory` or `IOMemory`.
    - `atomic_support` for the level of atomicity supported in the
      memory region.
    - `supports_pte_read` and `supports_pte_write` for whether the region
      supports the hardware read and write of page table entries respectively.
  - Writable bits of the `scounteren` CSR can now be specified;
    see `base.scounteren_writable_bits`.
  - The behavior when reserved modes are written to the `mtvec` and
    `stvec` CSRs can now be specified; see `base.reserved_behavior.xtvec_mode`.
  - The time limit that wait instructions (e.g. WFI, WRS.NTO, WRS.STO)
    can wait for is now configurable; see `platform.max_time_to_wait`
    (see also https://github.com/riscv/sail-riscv/issues/1564). The
    default setting for `platform.wfi_is_nop` was also changed from
    `true` to `false`.
  - The `dirty_update` attribute of `memory.translation` has been removed,
    since the behavior that attribute configured can now be modeled
    using the Svadu and Svade extensions. When neither of these extensions
    are configured as supported, the model defaults to a hardware update of
    the PTE.
  - The global (i.e. before address translation) handling of
    misaligned accesses can be configured in a more fine-grained way:
    the handling of AMOs, LR/SC and scalar and vector load/stores can
    be individually specified. Misaligned AMOs and LR/SC now both
    raise access faults by default; this is a change from the previous
    default, which raised a misaligned exception, and now matches the
    more common behavior. See `memory.misaligned.exceptions`, which
    replaces `memory.misaligned.supported`.
  - The fine-grained handling of misaligned accesses can also be
    similarly specified in a PMA. See the
    `attributes.misaligned_exceptions` field of each region under
    `memory.regions`; `attributes.misaligned_exceptions` replaces the
    earlier `attributes.misaligned_fault` property.
  - A new `platform.reservation.require_exact_reservation_addr` parameter controls
    whether Store-Conditional instructions are required to provide the
    same address as the matching Load-Reserve in order to succeed.
    This defaults to `false` to match earlier behavior, but can be set
    to `true` to match some implementations such as Spike. The earlier
    `platform.reservation_set_size_exp` parameter has moved to
    `platform.reservation.reservation_set_size_exp`.
  - A new `platform.simple_interrupt_generator.base` parameter specifies
    the memory location of the simple interrupt generator; see below for
    more on this device.

- The following extensions have been added:
  - Ziccamoa
  - Ziccamoc
  - Ziccif
  - Zicclsm
  - Ziccrse
  - Zicfiss
  - Ssccptr
  - Sscounterenw
  - Svade
  - Svadu
  - Svnapot
  - Svpbmt
  - Svvptc

- D, A, U and other bits that are reserved in non-leaf PTEs now raise a page-fault exception.
  This is a backwards incompatible change, and is required since version 1.12 (also known as version 20211203)
  of the privileged specification.

- The emulator tries to detect some potentially infinite trap loops using
  the difference between the traps generated and `xret` instructions
  executed by the hart. If such a potential loop is detected, the
  emulator exits with an error. This detection is enabled by default,
  and a command line option has been added to disable it (see below).

- The command line interface has been updated:
  - A `--rv32` option has been added to use a default RV32
    configuration. This allows emulating RV32 binaries without needing
    to point to a specific RV32 configuration file. This option cannot
    be used with the `--config` option.
  - A new `--trace-tlb` option has been added to enable TLB specific trace output.
  - The previous `--trace-all` option has been renamed to `--trace`.
    `--trace` now enables all trace output except TLB and page table walker (PTW) traces.
  - A `--disable-trap-loop-detection` option has been added to disable
    the default detection of trap loops.

- A Mac ARM binary release is now available.

- Performance improvements:
  - https://github.com/riscv/sail-riscv/pull/1643 : Superpage TLB entries
    were inserted at the wrong index, causing a full page table walk on every
    access within a superpage. This has been fixed, with significant performance
    improvements for superpage-heavy workloads (e.g. Linux boot time reduced
    by ~71%).

- Testing in CI now includes the ACT4 test suite from `riscv/riscv-arch-test`.

- Important issues addressed and bugs fixed:
  - https://github.com/riscv/sail-riscv/issues/1553 : Sail exceptions were not usefully shown in the execution trace
  - https://github.com/riscv/sail-riscv/issues/1560 : Updates to `mip` were not captured in the trace file
  - https://github.com/riscv/sail-riscv/issues/1574 : Misaligned store-conditionals didn't raise a misaligned address exception

- A [Simple Interrupt Generator](../doc/SimpleInterruptGenerator.md) MMIO device has been added for testing purposes. This allows generating external and software interrupts that cannot be directly generated from within the hart.

# Release notes for version 0.10

- The highlight of this release is the switch to using the C++ backend
  of the Sail compiler. The generated model for the hart is wrapped in
  a C++ `class`, which opens up the possibility of instantiating
  multiple harts to simulate multicore platforms (though this is not
  yet implemented).

- A `--config-override` cli option has been added to specify one or more
  additional JSON configuration files that override the corresponding fields
  in a configuration.

- Updates to the [configuration file](../config/config.json.in):
  - New configuration parameters to control reserved behavior have
    been added. See the `reserved_behavior` section for details. More
    such options will continue to be added in subsequent releases.

  - Read-only-zero PMP entries can now be configured; see
    `memory.pmp.usable_count` (see https://github.com/riscv/sail-riscv/issues/1111).

  - The size of the reservation set for Zalrsc atomics can now be
    specified; see `platform.reservation_set_size_exp`.

  - Page faults can now also be configured to set `xtval` registers,
    and `breakpoint` has been disambiguated into `hardware_breakpoint`
    and `software_breakpoint`; see `base.xtval_non_zero`.

  - Explicit configuration for the Zdinx extension was added; see `extensions.Zdinx`.
    Previously, Zdinx was implicitly configured by the Zfinx extension.

- The following extensions have been added:
  - Za64rs, Za128rs
  - Zic64b
  - Sstvala
  - Sstvecd
  - Ssu64xl
  - Smstateen, Sstateen
  - Ssqosid

- The following unratified extensions have been added:
  - Zibi
  - Zvabd

- Command-line options for finer-grained execution tracing have been
  added. Use the `--help` option for details.

- Weekly binary releases are now available for more up-to-date builds
  of the model.

- The model now requires the Sail 0.20.1 compiler version.

- Testing in CI has been updated to the latest `riscv-tests` and
  `riscv-vector-tests`, and the OS boot test now uses Linux 6.18.2 and
  OpenSBI v1.8.1.

- Important issues addressed and bugs fixed:
  - https://github.com/riscv/sail-riscv/issues/1014 : reserved fences were treated as illegal instructions
  - https://github.com/riscv/sail-riscv/issues/1239 : missed PMA access control checks for failing store-conditionals
  - https://github.com/riscv/sail-riscv/issues/1434 : missing write to `rd` for some cases of `vset{i}vl{i}`
  - https://github.com/riscv/sail-riscv/issues/1455 : missing source-destination overlap checks for vector instructions
  - https://github.com/riscv/sail-riscv/issues/1527 : incorrect NaN result from `fcvt.s.bf16` for improperly NaN-boxed inputs

# Release notes for version 0.9

- Support for the RV32E and RV64E base ISAs has been added. These
  are enabled by setting `base.E` to `true` in `config/rv32d.json`
  and `config/rv64d.json` respectively. Dynamic switching between
  the 'E' and 'I' base ISAs is not supported.

- The following extensions have been added:
  - Zvfbfwma
  - Zvfbfmin
  - Zfbfmin
  - Zicbop
  - Zicfilp
  - Zihintntl
  - Zihintpause
  - Zve32x, Zve32f, Zve64x, Zve64f, and Zve64d
  - Zvl32b, Zvl64b, Zvl128b, Zvl256b, Zvl512b, and Zvl1024b
  - Zvfh and Zvfhmin
  - Svrsw60t59b

- Support for specifying arbitrary memory regions and some basic
  static PMAs (Physical Memory Attributes) has been added.

- Switch to ELFIO for ELF parsing, and add symbolization in the
  instruction log output. Each instruction will print
  `<symbol>+<offset>` at the end of the line, e.g. `_start+4`.

- The documentation (in particular, the [Reading
  Guide](./ReadingGuide.md)) has been brought up to date. A new
  [document](./AddingExtensions.md) providing basic suggestions on
  adding an extension to the model has been added.

- A tarfile of the HTML-rendered Sail sources was added to the
  build and release artifacts.

- The JSON configuration used for execution by the C++ simulator is
  now validated against the expected JSON schema. The JSON schema for
  the configuration can be printed using the `--print-config-schema`
  option.

- Linux boot is now tested in CI.

- The model now requires the Sail 0.20 compiler version.

- The release now includes a binary for Linux Arm AArch64. This
  enables using the emulator on Apple Silicon Macs using a Linux
  Docker image.

  The release artifacts are now also attested.

# Release notes for the 0.8 release

This is a major release with some backwards-incompatible changes.

The highlights of the release are:

- A single executable binary for the various ISA versions (RV32/RV64)
  and floating-point extensions (F/D).

- The introduction of a JSON-based configuration system.

- The use of the Sail module system to provide a modular structure
  to the RISC-V model.

- Many new extensions, including complete coverage of the RVA23
  vector crypto extensions.

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
the F or D extensions.

## JSON-based configuration system

The configuration parameters for the model are now specified in a JSON
file. These parameters include `base.xlen` (which is set to `32` for
RV32 or `64` for RV64), various platform settings and flags to enable
each individual extension, and any parameters for these extensions.
Sample configurations are provided for RV32 (`config/rv32d.json`) and
RV64 (`config/rv64d.json`).

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

## CLI changes

Backwards-incompatible changes have been made to the CLI. As mentioned
above, options for model configuration have been removed. In addition,
all short (single-character) options have been removed, and tracing
options have changed.

The help message has been improved and now mentions the supported
tracing options.

All tracing is now disabled by default. Each tracer (such as `instr`,
`mem`, `reg`, `platform`) has its own option to enable it. A
`--trace-all` option enables all tracers.

The simulator can now generate a device-tree (using
`--print-device-tree`) and ISA string (using `--print-isa-string`)
corresponding to the specified configuration.

A `--version` option prints the release version of the model.

A `--build-info` option prints more build information for the model.
This should be used when reporting issues in the model.

## Other changes

- The model now requires the Sail 0.19.1 compiler version.

- The Berkeley SoftFloat dependency has been updated to the latest
  upstream version.

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
