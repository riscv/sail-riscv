/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// Chip reset. This only does the minimum resets required by the RISC-V spec.
function reset() -> unit = {
  reset_sys();
  reset_vmem();

  // To allow model extensions (code outside this repo) to perform additional reset.
  ext_reset();
}

// Initialize model state. This is only called once; not for every chip reset.
function init_model(config_filename : string) -> unit = {
  assert(config_is_valid(), (if   config_filename == ""
                             then "Default config"
                             else "Config in " ^ config_filename)
                             ^ " is invalid.");
  hart_state = HART_ACTIVE();
  init_platform();
  reset();
}

// For compatibility with the de facto boot interface, set a0=mhartid, a1=&dtb.
// The C++ code always places the DTB at the start of the ROM.
//
// See https://github.com/torvalds/linux/blob/master/Documentation/arch/riscv/boot.rst
function init_boot_requirements() -> unit = {
  X(Regno(10)) = mhartid;
  X(Regno(11)) = to_bits_checked(config platform.rom.base : int);
}
