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
let SIG_GUEST_OFFSET = 8

private val sig_load : forall 'n, 0 < 'n <= max_mem_access . (MemoryAccessType(mem_payload), physaddr, int('n)) -> MemoryOpResult(bits(8 * 'n))
function sig_load(access, addr, width) = {
  let Physaddr(paddr) = addr;
  // Version of this MMIO device (1.1 currently).
  // This follows semver.
  let VERSION = 0x00010001;

  if width != 4 | paddr[1 .. 0] != zeros()
  then Err(addr, accessFaultFromAccessType(access))
  else {
    if paddr == plat_sig_base + SIG_VERSION_OFFSET
    then Ok(VERSION)
    else if paddr == plat_sig_base + SIG_PLATFORM_OFFSET
    then Ok(zeros())
    else if paddr == plat_sig_base + SIG_GUEST_OFFSET & currentlyEnabled(Ext_H)
    then Ok(zeros())
    else Err(addr, accessFaultFromAccessType(access))
  }
}

private val sig_store : forall 'n, 0 < 'n <= max_mem_access . (physaddr, int('n), bits(8 * 'n)) -> MemoryOpResult(bool)
function sig_store(addr, width, data) = {
  let Physaddr(paddr) = addr;
  if width != 4 | paddr[1 .. 0] != zeros()
  then Err(addr, E_SAMO_Access_Fault())
  else {
    if paddr == plat_sig_base + SIG_VERSION_OFFSET
    then Ok(true)
    else if paddr == plat_sig_base + SIG_PLATFORM_OFFSET
    then {
      let value = data[31];
      let data = Mk_Minterrupts(zero_extend(data));

      // Reserved bits must currently be written with zeros.
      if [data with MEI = 0b0, SEI = 0b0, MSI = 0b0, SSI = 0b0].bits[30 .. 0] != zeros()
      then return Err(addr, E_SAMO_Access_Fault());

      if data[MEI] == 0b1 then sig_meip = value;
      if data[SEI] == 0b1 then sig_seip = value;
      if data[MSI] == 0b1 then sig_msip = value;
      if data[SSI] == 0b1 then sig_ssip = value;

      csr_write_callback("mip", read_mip(IncludePlatformInterrupts).bits);

      Ok(true)
    } else if paddr == plat_sig_base + SIG_GUEST_OFFSET & currentlyEnabled(Ext_H)
    then {
      let value = data[31];
      let guest = unsigned(data[5 .. 0]);

      // Reserved bits must currently be written with zeros.
      if data[30 .. 6] != zeros()
      then return Err(addr, E_SAMO_Access_Fault());

      // hgeip bit 0 is always zero, so anything outside 1..GEILEN does not
      // name a guest interrupt file.
      if guest == 0 | guest > geilen
      then return Err(addr, E_SAMO_Access_Fault());

      hgeip[guest] = value;

      // mip.SGEIP and hip.VSEIP both follow from hgeip, but they are derived on
      // read (see external_interrupts_pending()) so there is nothing to update.
      csr_write_callback("hgeip", hgeip);
      csr_write_callback("mip", read_mip(IncludePlatformInterrupts).bits);

      Ok(true)
    } else Err(addr, E_SAMO_Access_Fault())
  }
}
