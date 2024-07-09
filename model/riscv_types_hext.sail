/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Virtualization modes */

type virt_mode = bits(1)
enum Virtualization = {V0, V1}

val virtMode_to_bits : Virtualization -> virt_mode
function virtMode_to_bits (v) =
  match (v) {
    V0 => 0b0,
    V1 => 0b1
  }

val virtMode_of_bits : virt_mode -> Virtualization
function virtMode_of_bits(v) =
  match (v) {
    0b0 => V0,
    0b1 => V1
  }

val virtMode_to_str : Virtualization -> string
function virtMode_to_str (v) =
  match (v) {
    V0 => "V=0",
    V1 => "V=1"
  }

overload to_str = {virtMode_to_str}

val virt_priv_to_str : (Privilege, Virtualization) -> string
function virt_priv_to_str (priv, virt) =
  match (priv, virt) {
    (User, V1)       => "VU",
    (User, V0)       => "U",
    (Supervisor, V1) => "VS",
    (Supervisor, V0) => "HS",
    (Machine, V1)    => internal_error(__FILE__, __LINE__, "illegal privilege mode"),
    (Machine, V0)    => "M",
  }

overload to_str = {virt_priv_to_str}
