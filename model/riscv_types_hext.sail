/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// The current virtualization mode
// indicates whether the hart is currently executing in a guest
enum Virtualization = { V0, V1 }

function virt_priv_to_str(priv : Privilege, virt: Virtualization) -> string = {
  match (priv, virt) {
    (User      , V0) => "U",  // User mode
    (Supervisor, V0) => "HS", // Hypervisor-extended supervisor mode
    (Machine   , V0) => "M",  // Machine mode
    (User      , V1) => "VU", // Virtual user mode
    (Supervisor, V1) => "VS", // Virtual supervisor mode
    (Machine   , V1) => internal_error(__FILE__, __LINE__, "illegal privilege mode"),
  }
}
overload to_str = {virt_priv_to_str}

function two_stage_translation_enabled(priv : Privilege, virt : Virtualization) -> bool = {
  match (priv, virt) {
    (priv, V1) if priv != Machine => true,
    _ => false,
  }
}
