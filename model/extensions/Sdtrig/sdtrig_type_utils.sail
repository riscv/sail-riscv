// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

private function make_etrigger_flag(e : ExceptionType) -> xlenbits =
  (zero_extend(0b1) : xlenbits) << (zero_extend(exceptionType_bits(e)) : xlenbits)

// TODO: add configuration flags for individual triggers
let supported_etrigger_mask : xlenbits = {
  var supported : xlenbits = zeros();
  supported = supported | make_etrigger_flag(E_Fetch_Addr_Align());
  supported = supported | make_etrigger_flag(E_Fetch_Access_Fault());
  supported = supported | make_etrigger_flag(E_Illegal_Instr());
  supported = supported | make_etrigger_flag(E_Load_Addr_Align());
  supported = supported | make_etrigger_flag(E_Load_Access_Fault());
  supported = supported | make_etrigger_flag(E_SAMO_Addr_Align());
  supported = supported | make_etrigger_flag(E_SAMO_Access_Fault());
  supported = supported | make_etrigger_flag(E_U_EnvCall());
  supported = supported | make_etrigger_flag(E_S_EnvCall());
  supported = supported | make_etrigger_flag(E_VS_EnvCall());
  supported = supported | make_etrigger_flag(E_M_EnvCall());
  supported = supported | make_etrigger_flag(E_Fetch_Page_Fault());
  supported = supported | make_etrigger_flag(E_Load_Page_Fault());
  supported = supported | make_etrigger_flag(E_SAMO_Page_Fault());
  supported = supported | make_etrigger_flag(E_Software_Check());
  supported = supported | make_etrigger_flag(E_Fetch_GPage_Fault());
  supported = supported | make_etrigger_flag(E_Load_GPage_Fault());
  supported = supported | make_etrigger_flag(E_Virtual_Instr());
  supported = supported | make_etrigger_flag(E_SAMO_GPage_Fault());
  supported = supported | make_etrigger_flag(E_Breakpoint(Brk_Software));
  supported
}

private function make_itrigger_flag(i : InterruptType) -> xlenbits =
  (zero_extend(0b1) : xlenbits) << (zero_extend(interruptType_bits(i)) : xlenbits)

// TODO: add configuration flags for individual triggers
let supported_itrigger_mask : xlenbits = {
  var supported : xlenbits = zeros();
  supported = supported | make_itrigger_flag(I_S_Software);
  supported = supported | make_itrigger_flag(I_VS_Software);
  supported = supported | make_itrigger_flag(I_M_Software);
  supported = supported | make_itrigger_flag(I_S_Timer);
  supported = supported | make_itrigger_flag(I_VS_Timer);
  supported = supported | make_itrigger_flag(I_M_Timer);
  supported = supported | make_itrigger_flag(I_S_External);
  supported = supported | make_itrigger_flag(I_VS_External);
  supported = supported | make_itrigger_flag(I_M_External);
  supported = supported | make_itrigger_flag(I_SG_External);
  supported = supported | make_itrigger_flag(I_COF);
  supported
}
