val main : unit -> unit effect {barr, eamem, escape, exmem, rmem, rreg, wmv, wreg}

function main () = {
  // initialize extensions
  ext_init ();

  // PC = __GetSlice_int(64, elf_entry(), 0);
  PC = sail_zero_extend(0x1000, sizeof(xlen));
  print_bits("PC = ", PC);

  try {
    init_model();
    loop()
  } catch {
    Error_not_implemented(s) => print_string("Error: Not implemented: ", s),
    Error_internal_error() => print("Error: internal error")
  }
}
