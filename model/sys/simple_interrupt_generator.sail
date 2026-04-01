// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

private val sig_load : forall 'n, 0 < 'n <= max_mem_access . (MemoryAccessType(mem_payload), physaddr, int('n)) -> MemoryOpResult(bits(8 * 'n))
function sig_load(access, Physaddr(paddr), width) = {
  if width == 4 & paddr == plat_sig_base
  then Ok(zeros())
  else Err(accessFaultFromAccessType(access))
}

private val sig_store : forall 'n, 0 < 'n <= max_mem_access . (physaddr, int('n), bits(8 * 'n)) -> MemoryOpResult(bool)
function sig_store(Physaddr(paddr), width, data) = {
  if width == 4 & paddr == plat_sig_base
  then {
    let set = data[31] == 0b1;
    let data = Mk_Minterrupts(zero_extend(data));
    if set then {
      // Set
      if data[MEI] == 0b1 then {
        sig_meip = 0b1;
      };
      if data[SEI] == 0b1 then {
        sig_seip = 0b1;
      };
      if data[MSI] == 0b1 then {
        mip[MSI] = 0b1;
      };
    } else {
      // Clear
      if data[MEI] == 0b1 then {
        sig_meip = 0b0;
      };
      if data[SEI] == 0b1 then {
        sig_seip = 0b0;
      };
      if data[MSI] == 0b1 then {
        mip[MSI] = 0b0;
      };
    };

    Ok(true)
  }
  else Err(E_SAMO_Access_Fault())
}
