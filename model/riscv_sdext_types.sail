/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

enum debug_entry_cause = {DBGEntry_None, DBGEntry_EBreak, DBGEntry_Trigger, DBGEntry_HaltReq,
                          DBGEntry_Step, DBGEntry_ResetHaltReq, DBGEntry_Group, DBGEntry_Other}

mapping debug_cause_bits : bits(3) <-> debug_entry_cause = {
  0b000 <-> DBGEntry_None,
  0b001 <-> DBGEntry_EBreak,
  0b010 <-> DBGEntry_Trigger,
  0b011 <-> DBGEntry_HaltReq,
  0b100 <-> DBGEntry_Step,
  0b101 <-> DBGEntry_ResetHaltReq,
  0b110 <-> DBGEntry_Group,
  0b111 <-> DBGEntry_Other,
}
