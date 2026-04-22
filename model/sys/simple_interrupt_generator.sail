// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Register offsets.
let SIG_VERSION_OFFSET = 0
let SIG_PLATFORM_OFFSET = 4

private val sig_load : forall 'n, 0 < 'n <= max_mem_access . (MemoryAccessType(mem_payload), physaddr, int('n)) -> MemoryOpResult(bits(8 * 'n))
function sig_load(access, Physaddr(paddr), width) = {
  // Version of this MMIO device (1.0 currently).
  // This follows semver.
  let VERSION = 0x00010000;

  if width != 4 | paddr[1 .. 0] != zeros()
  then Err(accessFaultFromAccessType(access))
  else {
    if paddr == plat_sig_base + SIG_VERSION_OFFSET
    then Ok(VERSION)
    else if paddr == plat_sig_base + SIG_PLATFORM_OFFSET
    then Ok(zeros())
    else Err(accessFaultFromAccessType(access))
  }
}

private val sig_store : forall 'n, 0 < 'n <= max_mem_access . (physaddr, int('n), bits(8 * 'n)) -> MemoryOpResult(bool)
function sig_store(Physaddr(paddr), width, data) = {
  if width != 4 | paddr[1 .. 0] != zeros()
  then Err(E_SAMO_Access_Fault())
  else {
    if paddr == plat_sig_base + SIG_VERSION_OFFSET
    then Ok(true)
    else if paddr == plat_sig_base + SIG_PLATFORM_OFFSET
    then {
      let value = data[31];
      let data = Mk_Minterrupts(zero_extend(data));

      // Reserved bits must currently be written with zeros.
      if [data with MEI = 0b0, SEI = 0b0, MSI = 0b0, SSI = 0b0].bits[30 .. 0] != zeros()
      then return Err(E_SAMO_Access_Fault());

      if data[MEI] == 0b1 then sig_meip = value;
      if data[SEI] == 0b1 then sig_seip = value;
      if data[MSI] == 0b1 then mip[MSI] = value;
      // SSI is read-only zero if the hart does not support supervisor mode.
      if data[SSI] == 0b1 & currentlyEnabled(Ext_S) then mip[SSI] = value;

      csr_write_callback("mip", read_mip(IncludePlatformInterrupts).bits);

      Ok(true)
    } else Err(E_SAMO_Access_Fault())
  }
}
