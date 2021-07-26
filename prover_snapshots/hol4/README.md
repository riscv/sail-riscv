# Snapshot of HOL4 output for Sail RISC-V model

These theories are a snapshot of the generated files for the Sail RISC-V models
translated to HOL4 via Lem.  They only require HOL4; the necessary Lem library
files are included.

A recent checkout of HOL4 from the repository at
<https://github.com/HOL-Theorem-Prover/HOL/> is required.  This snapshot was
successfully built with commit `0c88037d2`, for example.

It was generated using sail commit `f69ac352` on revision `c6c1e38`
with the extra option `SAIL_FLAGS+=-grouped_regstate` to make the main
state record small enough for HOL's datatype support.
