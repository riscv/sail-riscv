# Adding an extension

Here are some suggestions for dealing with common issues when adding a
new simple extension to the Sail RISC-V model. For historical
reasons, existing extensions may not always follow these guidelines.
These guidelines will not suffice for larger and more complex
extensions.

## Naming the new files

Each file implementing an extension should embed the extension name
(ideally as it appears in the ISA string) into the file name.

A simple extension could be defined in a single file named
`riscv_<ext_name>.sail`.

More complex extensions will typically require the definition of new
types, enums and helper or utility functions. New types and enums
could be defined in `riscv_<ext_name>_types.sail` and helper functions
in `riscv_<ext_name>_utils.sail`. New instructions should go in a
file named `riscv_insts_<ext_name>.sail`.

## Adding the extension to the project file

A new module for the extension would need to be defined in the
[riscv.sail_project](../model/riscv.sail_project) project file that specifies
the new files for the extension. Complex extensions might need to be
split into multiple modules, as has been done for the `V` vector
extension. Modules for related extensions could be grouped under a
common module, as for example the `Zaamo` and `Zalrsc` under the `A`
module.

Files could also be grouped into submodules to simplify the
dependencies between the submodules and the modules in the rest of the
specification.

## Registering and configuring the extension

An enum clause for the extension needs to be added to
[riscv_extensions.sail](../model/riscv_extensions.sail) at an
appropriate location according to the canonical ordering described
there. The extension should also be added to the
`extensions_ordered_for_isa_string` array.

A new `"<ext_name>"` entry for the extension should also be created in
the `"extensions"` list in the JSON configuration files for RV32
([rv32d.json](../config/rv32d.json)) and RV64
([rv64d.json](../config/rv64d.json)). This entry should have a
`"supported"` field with a boolean value. If an extension is not
defined for a base ISA, it should still be added to the configuration
file for that ISA with a `"supported"` value of `"false"`. For
example, the `Sv39` extension is specified (as unsupported) in config
files for RV32 even though `Sv39` is not defined for RV32. Any
configuration parameters for the extension should be specified as
fields of this entry.

The value of `"supported"` in the JSON config file is used to define
the `hartSupports` clause for the extension in
[riscv_extensions.sail](../model/riscv_extensions.sail) using the
`config extensions.<ext_name>.supported` construct.

A definition for the `currentlyEnabled` clause for the extension
should be provided in one of the files implementing the extension.

## Adding new instructions

Each new set of instructions can be specified in a separate
self-contained file, with their instruction encodings, assembly
language specifications and the corresponding encoders and decoders,
and execution semantics. The various `riscv_insts_*.sail` files can be
examined for examples on how this can be done. Care should be taken when
defining the assembly clauses to ensure they are consistent with the
format expected by assemblers in standard toolchains.

Instructions that interact with virtual memory can use the functions
defined in [riscv_vmem_utils.sail](../model/riscv_vmem_utils.sail).

## Adding new CSRs

Architectural state such as CSRs should be introduced with `register`
declarations. Any bit-oriented structure of a CSR should be specified
with a `bitfield` definition; the type of the `register` definition
will usually be this `bitfield` type. Clauses of the
`is_CSR_accessible`, `read_CSR` and `write_CSR` functions should be
added for each CSR.
