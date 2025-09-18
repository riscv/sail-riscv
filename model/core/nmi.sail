type nmi_cause = bits(xlen - 1)

// Pending Non Maskable Interrupt. If this is Some() an NMI is taken.
// This is not a real RISC-V CSR; it is used by the model to
// decide whether to trap to an NMI or not.
//
// The value is written to mcause. A value of 0 means unknown.
// Other values are implementation defined.
//
// This is reset to None() automatically when the NMI is taken.
register pending_nmi : option(nmi_cause) = None()

// Utility function to set the above value from C etc. This has
// nicer generated C types than dealing with option(nmi_cause) directly.
$option --c-preserve set_pending_nmi
function set_pending_nmi(cause : bits(31)) -> unit = pending_nmi = Some(zero_extend(cause))
