/*========================================================================*/
/*                                                                        */
/*  Copyright (c) 2015-2017 Robert M. Norton                              */
/*  Copyright (c) 2015-2017 Kathyrn Gray                                  */
/*  All rights reserved.                                                  */
/*                                                                        */
/*  This software was developed by the University of Cambridge Computer   */
/*  Laboratory as part of the Rigorous Engineering of Mainstream Systems  */
/*  (REMS) project, funded by EPSRC grant EP/K008528/1.                   */
/*                                                                        */
/*  Redistribution and use in source and binary forms, with or without    */
/*  modification, are permitted provided that the following conditions    */
/*  are met:                                                              */
/*  1. Redistributions of source code must retain the above copyright     */
/*     notice, this list of conditions and the following disclaimer.      */
/*  2. Redistributions in binary form must reproduce the above copyright  */
/*     notice, this list of conditions and the following disclaimer in    */
/*     the documentation and/or other materials provided with the         */
/*     distribution.                                                      */
/*                                                                        */
/*  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''    */
/*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED     */
/*  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A       */
/*  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR   */
/*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,          */
/*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT      */
/*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF      */
/*  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND   */
/*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,    */
/*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT    */
/*  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF    */
/*  SUCH DAMAGE.                                                          */
/*========================================================================*/

register PCC        : Capability
register NextPCC    : Capability
register DDC : Capability
register C01 : Capability
register C02 : Capability
register C03 : Capability
register C04 : Capability
register C05 : Capability
register C06 : Capability
register C07 : Capability
register C08 : Capability
register C09 : Capability
register C10 : Capability
register C11 : Capability
register C12 : Capability
register C13 : Capability
register C14 : Capability
register C15 : Capability
register C16 : Capability
register C17 : Capability
register C18 : Capability
register C19 : Capability
register C20 : Capability
register C21 : Capability
register C22 : Capability
register C23 : Capability
register C24 : Capability /* aka return code capability, RCC */
register C25 : Capability
register C26 : Capability /* aka invoked data capability, IDC */
register C27 : Capability
register C28 : Capability
register C29 : Capability
register C30 : Capability
register C31 : Capability

register CULR : Capability /* User thread local storage capabiltiy */
register CPLR : Capability /* Privileged thread local storage capabiltiy */
register KR1C : Capability /* kernel reserved capability 1 */
register KR2C : Capability /* kernel reserved capability 2 */
register KCC  : Capability /* kernel code capability */
register KDC  : Capability /* kernel data capability */
register EPCC : Capability     /* exception program counter capability */
register ErrorEPCC : Capability /* error program counter capability */

let CapRegs : vector(32, dec, register(Capability)) =
  [
    ref C31,
    ref C30,
    ref C29,
    ref C28,
    ref C27,
    ref C26,
    ref C25,
    ref C24,
    ref C23,
    ref C22,
    ref C21,
    ref C20,
    ref C19,
    ref C18,
    ref C17,
    ref C16,
    ref C15,
    ref C14,
    ref C13,
    ref C12,
    ref C11,
    ref C10,
    ref C09,
    ref C08,
    ref C07,
    ref C06,
    ref C05,
    ref C04,
    ref C03,
    ref C02,
    ref C01,
    ref DDC
  ]

let have_cp2 = true

val capToString : (Capability, bool) -> string effect {escape}

/*!
THIS reads a given capability register or,
the null capabiility if the argument is zero.
*/
val readCapReg : regno -> Capability effect {rreg}
function readCapReg(n) =
  if (n == 0b00000) then
    null_cap
  else
    let i = unsigned(n) in
    reg_deref(CapRegs[i])

/*!
THIS is the same as [readCapReg] except that when the argument is zero the value of DDC is returned 
instead of the null capability. This is used for instructions that expect an address, where using
null would always generate an exception.
*/
val readCapRegDDC : regno -> Capability effect {rreg}
function readCapRegDDC(n) =
  let i = unsigned(n) in
  reg_deref(CapRegs[i]) /* NB CapRegs[0] is points to DDC */

/*!
THIS`(cd, cap_val)` writes capability, `cap_val` capability register `cd`. Writes to register zero are ignored.
 */
val writeCapReg : (regno, Capability) -> unit effect {wreg, escape}
function writeCapReg(n, cap) =
  if (n == 0b00000) then
    ()
  else {
    let i = unsigned(n);
    if trace then {
      prerr(string_of_int(i));
      prerr(" <- ");
      prerr_endline(capToString(cap, false));
      /* Additionally check that the cap we are storing is in normal
         form i.e. it is unchanged by round-tripping through bits.
         This is quite a strong check because caps might differ from
         normal form in ways that don't really matter (e.g. otype
         non-zero for unsealed capability) but it is probably a good
         idea to maintain this invariant. It's disabled if not tracing
         because it is slow. We might be able to eliminate the
         non-normal values with a better type... */
      let cap2 = capBitsToCapability(cap.tag, capToBits(cap));
      if (cap != cap2) then {
        prerr_endline("Wrote non-normal cap:");
        prerr_endline(capToString(cap, false));
        prerr_endline(capToString(cap2, false));
        assert(false, "wrote non-normal capability");
      };
    } else {
      skip_escape();
    };
    (*CapRegs[i]) = cap;
  }

enum CapEx = {
  CapEx_None, 
  CapEx_LengthViolation,
  CapEx_TagViolation,
  CapEx_SealViolation,
  CapEx_TypeViolation,
  CapEx_CallTrap,
  CapEx_ReturnTrap,
  CapEx_TSSUnderFlow,
  CapEx_UserDefViolation,
  CapEx_TLBNoStoreCap,
  CapEx_InexactBounds,
  CapEx_GlobalViolation,
  CapEx_PermitExecuteViolation,
  CapEx_PermitLoadViolation,
  CapEx_PermitStoreViolation,
  CapEx_PermitLoadCapViolation,
  CapEx_PermitStoreCapViolation,
  CapEx_PermitStoreLocalCapViolation,
  CapEx_PermitSealViolation,
  CapEx_AccessSystemRegsViolation,
  CapEx_PermitCCallViolation,
  CapEx_AccessCCallIDCViolation,
  CapEx_PermitUnsealViolation,
  CapEx_PermitSetCIDViolation
}

function CapExCode(ex) : CapEx -> bits(8)=
  match ex {
    CapEx_None                          => 0x00,
    CapEx_LengthViolation               => 0x01,
    CapEx_TagViolation                  => 0x02,
    CapEx_SealViolation                 => 0x03,
    CapEx_TypeViolation                 => 0x04,
    CapEx_CallTrap                      => 0x05,
    CapEx_ReturnTrap                    => 0x06,
    CapEx_TSSUnderFlow                  => 0x07,
    CapEx_UserDefViolation              => 0x08,
    CapEx_TLBNoStoreCap                 => 0x09,
    CapEx_InexactBounds                 => 0x0a,
    CapEx_GlobalViolation               => 0x10,
    CapEx_PermitExecuteViolation        => 0x11,
    CapEx_PermitLoadViolation           => 0x12,
    CapEx_PermitStoreViolation          => 0x13,
    CapEx_PermitLoadCapViolation        => 0x14,
    CapEx_PermitStoreCapViolation       => 0x15,
    CapEx_PermitStoreLocalCapViolation  => 0x16,
    CapEx_PermitSealViolation           => 0x17,
    CapEx_AccessSystemRegsViolation     => 0x18,
    CapEx_PermitCCallViolation          => 0x19,
    CapEx_AccessCCallIDCViolation       => 0x1a,
    CapEx_PermitUnsealViolation         => 0x1b,
    CapEx_PermitSetCIDViolation         => 0x1c
  }

function string_of_capex (ex) : CapEx -> string = 
  match ex {
    CapEx_None                          => "None"                        ,
    CapEx_LengthViolation               => "LengthViolation"             ,
    CapEx_TagViolation                  => "TagViolation"                ,
    CapEx_SealViolation                 => "SealViolation"               ,
    CapEx_TypeViolation                 => "TypeViolation"               ,
    CapEx_CallTrap                      => "CallTrap"                    ,
    CapEx_ReturnTrap                    => "ReturnTrap"                  ,
    CapEx_TSSUnderFlow                  => "TSSUnderFlow"                ,
    CapEx_UserDefViolation              => "UserDefViolation"            ,
    CapEx_TLBNoStoreCap                 => "TLBNoStoreCap"               ,
    CapEx_InexactBounds                 => "InexactBounds"               ,
    CapEx_GlobalViolation               => "GlobalViolation"             ,
    CapEx_PermitExecuteViolation        => "PermitExecuteViolation"      ,
    CapEx_PermitLoadViolation           => "PermitLoadViolation"         ,
    CapEx_PermitStoreViolation          => "PermitStoreViolation"        ,
    CapEx_PermitLoadCapViolation        => "PermitLoadCapViolation"      ,
    CapEx_PermitStoreCapViolation       => "PermitStoreCapViolation"     ,
    CapEx_PermitStoreLocalCapViolation  => "PermitStoreLocalCapViolation",
    CapEx_PermitSealViolation           => "PermitSealViolation"         ,
    CapEx_AccessSystemRegsViolation     => "AccessSystemRegsViolation"   ,
    CapEx_PermitCCallViolation          => "PermitCCallViolation"        ,
    CapEx_AccessCCallIDCViolation       => "AccessCCallIDCViolation"     ,
    CapEx_PermitUnsealViolation         => "PermitUnsealViolation"       ,
    CapEx_PermitSetCIDViolation         => "PermitSetCIDViolation"
  }

bitfield CapCauseReg : bits(16) = {
  ExcCode : 15..8,
  RegNum : 7..0,
}

register CapCause : CapCauseReg
register CID : bits(64)

/*!
THIS executes a branch to the given capability, replacing PCC and taking the new PC from the offset field. Note that on MIPS the new PCC does not take effect until after the branch delay slot.
 */
val execute_branch_pcc : Capability -> unit effect {wreg}
function execute_branch_pcc(newPCC) = {
  DelayedPC = to_bits(64, getCapOffset(newPCC));
  DelayedPCC = newPCC;
  BranchPending = 0b1;
  NextInBranchDelay = 0b1;
}

/*!
THIS sets PCC to the given capability before executing the next instruction. It is used for CCall, which has no branch delay.
 */
val set_next_pcc : Capability -> unit effect {wreg} 
function set_next_pcc(newPCC) = {
  NextPCC    = newPCC;
  DelayedPCC = newPCC; /* always write DelayedPCC together with NextPCC so 
                          that non-capability branches don't override PCC */
}

function SignalException (ex) = {
  traceException(ex);
  /* Only update EPC and BD if not already in EXL mode */
  if (~ (CP0Status.EXL())) then 
  {
    let epc : bits(64) = if (InBranchDelay[0]) then 
      {
        CP0Cause->BD() = 0b1;
        PC - 4
      }
      else {
        CP0Cause->BD() = 0b0;
        PC
      };
    let (representable, newEPCC) = setCapOffset(PCC, epc);
    /* EPCC should always be representable because PC should always been (nearly) in bounds */
    assert(representable);
    if (PCC.sealed) then {
      /* Check that we didn't accidentally modify a sealed capabiltiy. */
      assert(getCapOffset(PCC) == unsigned(epc));
    };
    EPCC = newEPCC;
  };
  /* Fill in BadInstr + BadInstrP. */
  updateBadInstr();
  let vectorOffset = exceptionVectorOffset(ex);
  let vectorBase = exceptionVectorBase();
  /* On CHERI we have to subtract KCC.base so that we end up at the 
     right absolute vector address after indirecting via new PCC */
  let kccBase = getCapBase(KCC) in
  NextPC = vectorBase + zero_extend(vectorOffset) - to_bits(64, kccBase);
  set_next_pcc(KCC);
  CP0Cause->ExcCode() = ExceptionCode(ex);
  CP0Status->EXL()    = 0b1;
  throw (ISAException());
}

function ERETHook() : unit -> unit =
  {
    if (CP0Status.ERL() == bitone) then
      set_next_pcc(ErrorEPCC)
    else
      set_next_pcc(EPCC);
  }

val raise_c2_exception8 : forall ('o : Type) . (CapEx, bits(8)) -> 'o effect {escape, rreg, wreg}
function raise_c2_exception8(capEx, regnum) =
  {
    if trace then {
      prerr(" C2Ex ");
      prerr(string_of_capex(capEx));
      prerr(" reg: ");
      prerr_endline(BitStr(regnum));
    };
    CapCause->ExcCode() = CapExCode(capEx);
    CapCause->RegNum()  = regnum;
    let mipsEx = 
      if ((capEx == CapEx_CallTrap) | (capEx == CapEx_ReturnTrap)) 
      then C2Trap else C2E in
    SignalException(mipsEx);
  }

/*!
causes the processor to raise a capability exception by writing the given capability exception cause and register number to the CapCause register then signalling an exception using [SignalException] (on CHERI-MIPS this is a C2E exception in most cases, or a special C2Trap for CCall and CReturn). */
val raise_c2_exception : forall ('o : Type) . (CapEx, regno) -> 'o effect {escape, rreg, wreg}
function raise_c2_exception(capEx, regnum) =
  let reg8 = 0b000 @ regnum in
  raise_c2_exception8(capEx, reg8)
/*!
is as [raise_c2_exception] except that CapCause.RegNum  is written with the special value 0xff indicating PCC or no register.
 */
val raise_c2_exception_noreg : forall ('o : Type) . (CapEx) -> 'o effect {escape, rreg, wreg}
function raise_c2_exception_noreg(capEx) =
  raise_c2_exception8(capEx, 0xff)

val pcc_access_system_regs : unit -> bool effect {rreg}
function pcc_access_system_regs () = PCC.access_system_regs

/*!
reads the tag associated with the given physical address.
 */
val MEMr_tag = "read_tag_bool"  : bits(64) -> bool effect { rmemt }
val MEMw_tag = "write_tag_bool" : (bits(64) , bool) -> unit effect { wmvt }

/*!
reads `cap_size` bytes from the given physical address in memory and the associated tag value. The address should be capability-aligned.
 */
val MEMr_tagged : bits(64) -> (bool, bits('cap_size * 8)) effect { escape, rmem, rmemt }
function MEMr_tagged (addr) =
{
  /* assumes addr is cap. aligned */
  assert(unsigned(addr) % cap_size == 0);
  let tag  = MEMr_tag(addr) in
  let data = MEMr(addr, cap_size) in
  (tag, reverse_endianness(data))
}

/*!
is as [MEMr_tagged] except that the load is marked as part of a load linked / store conditional.
 */
val MEMr_tagged_reserve : bits(64) -> (bool, bits('cap_size * 8)) effect { escape, rmem, rmemt }
function MEMr_tagged_reserve (addr) =
{
  /* assumes addr is cap. aligned */
  assert(unsigned(addr) % cap_size == 0);
  let tag = MEMr_tag(addr) in
  let data = MEMr_reserve(addr, cap_size) in
  (tag, reverse_endianness(data))
}

/*!
THIS`(addr, t, value)` writes `cap_size` bytes, `value`, to physical address, `addr`, with associated tag value, `t`.
 */
val MEMw_tagged : (bits(64), bool, bits('cap_size * 8)) -> unit effect { escape, eamem, wmv, wmvt }
function MEMw_tagged(addr, tag, data) =
{
  /* assumes addr is cap. aligned */
  assert(unsigned(addr) % cap_size == 0);
  MEMea(addr, cap_size);
  MEMval(addr, cap_size, reverse_endianness(data));
  MEMw_tag(addr, tag);
}

/*!
THIS`(addr, t, value)` writes `cap_size` bytes, `value`, to physical address, `addr`, with associated tag value, `t` and returns store conditional success or failure.
 */
val MEMw_tagged_conditional : (bits(64), bool, bits('cap_size * 8)) -> bool effect { escape, eamem, wmv, wmvt }
function MEMw_tagged_conditional(addr, tag, data) =
{
  /* assumes addr is cap. aligned */
  assert(unsigned(addr) % cap_size == 0);
  MEMea_conditional(addr, cap_size);
  success = MEMval_conditional(addr, cap_size, reverse_endianness(data));
  if success then
     MEMw_tag(addr, tag);
  success;
}

let cap_addr_mask = to_bits(64, pow2(64) - cap_size)

/*!
THIS`(addr, size, value)` writes `size` bytes of `value` to physical address `addr`.
 */
val MEMw_wrapper : forall 'n, 'n >= 1. (bits(64), atom('n), bits(8 * 'n)) -> unit effect {escape, wmv, wmvt, wreg, eamem}
function MEMw_wrapper(addr, size, data) =
  let ledata = reverse_endianness(data) in
  if (addr == 0x000000007f000000) then
  {
    UART_WDATA   = ledata[7..0];
    UART_WRITTEN = 0b1;
  }
  else
  {
    /* require that writes don't cross capability boundaries (should be true due to mips alignment requirements) */  
    assert((addr & cap_addr_mask) == ((addr + to_bits(64, size - 1)) & cap_addr_mask));
    MEMea(addr, size);
    MEMval(addr, size, ledata);
    /* On cheri non-capability writes must clear the corresponding tag*/
    MEMw_tag(addr & cap_addr_mask, false);
  }

/*!
THIS`(addr, size, value)` attempts to write `size` bytes of `value` to physical address `addr` and returns a boolean indicating store conditional success or failure.
 */
val MEMw_conditional_wrapper : forall 'n, 'n >= 1. (bits(64), atom('n), bits(8 * 'n)) -> bool effect {escape, wmv, wmvt, eamem}
function MEMw_conditional_wrapper(addr, size, data) =
  {
    /* require that writes don't cross capability boundaries (should be true due to mips alignment requirements) */
    assert((addr & cap_addr_mask) == ((addr + to_bits(64, size - 1)) & cap_addr_mask));
    MEMea_conditional(addr, size);
    success = MEMval_conditional(addr,size,reverse_endianness(data));
    if success then
       /* On cheri non-capability writes must clear the corresponding tag */
       MEMw_tag(addr & cap_addr_mask, false);
    success;
  }

val checkDDCPerms : (Capability, MemAccessType) -> unit effect {escape, rreg, wreg}
function checkDDCPerms(ddc : Capability, accessType: MemAccessType) = 
  {
    if (not (ddc.tag)) then
      raise_c2_exception(CapEx_TagViolation, 0b00000)
    else if (ddc.sealed) then
      raise_c2_exception(CapEx_SealViolation, 0b00000);
    match accessType {
      Instruction  => assert(false), /* Only data accesses use DDC */
      LoadData     => if (~(ddc.permit_load)) then (raise_c2_exception(CapEx_PermitLoadViolation, 0b00000)),
      StoreData    => if (~(ddc.permit_store)) then (raise_c2_exception(CapEx_PermitStoreViolation, 0b00000))
    };
  }

val addrWrapper : (bits(64), MemAccessType, WordType) -> bits(64) effect {rreg, wreg, escape}
function addrWrapper(addr, accessType, width) =
  {
    let ddc = DDC;
    checkDDCPerms(ddc, accessType);
    cursor = getCapCursor(ddc);
    vAddr  = (cursor + unsigned(addr)) % pow2(64);
    size   = wordWidthBytes(width);
    let (base, top) = getCapBounds(ddc);
    if ((vAddr + size) > top) then
      (raise_c2_exception(CapEx_LengthViolation, 0b00000))
    else if (vAddr < base) then
      (raise_c2_exception(CapEx_LengthViolation, 0b00000))
    else
      to_bits(64, vAddr);
  }

val addrWrapperUnaligned : (bits(64), MemAccessType, WordTypeUnaligned) -> bits(64) effect {rreg, wreg, escape}
function addrWrapperUnaligned(addr, accessType, width) =
  {
    let ddc = DDC;
    checkDDCPerms(ddc, accessType);
    cursor = getCapCursor(ddc);
    vAddr  = (cursor + unsigned(addr)) % pow2(64);
    woffset = vAddr % 4;
    doffset = vAddr % 8;
    /* Compute the address and size of the bytes touched -- this depends on alignment. */
    let (waddr, size) : (int, int) = match width {
      WL => (vAddr, 4 - woffset),
      WR => (vAddr - woffset, woffset + 1),
      DL => (vAddr, 8 - doffset),
      DR => (vAddr - doffset, doffset + 1)
    };
    let (base, top) = getCapBounds(ddc);
    if ((waddr + size) > top) then
      (raise_c2_exception(CapEx_LengthViolation, 0b00000))
    else if (waddr < base) then
      (raise_c2_exception(CapEx_LengthViolation, 0b00000))
    else
      to_bits(64, vAddr);
  }

function execute_branch (pc) = {
  let len = getCapLength(PCC);
  /* Check the branch is within PCC bounds. Note that PC is offset to
  base so branches below base will be negative / very large and
  greater than top. */
  if unsigned(pc) + 4 > len then
    raise_c2_exception_noreg(CapEx_LengthViolation);
  execute_branch_mips(pc); }

$ifdef _MIPS_TLB_STUB
val TranslatePC : bits(64) -> bits(64) effect {rreg, wreg, escape}
$else
val TranslatePC : bits(64) -> bits(64) effect {rreg, wreg, escape, undef}
$endif

function TranslatePC (vAddr) = {
  incrementCP0Count();
  let pcc = PCC;
  let (base, top) = getCapBounds(pcc);
  let absPC = base + unsigned(vAddr);
  if ((absPC % 4)  != 0) then /* bad PC alignment */
    (SignalExceptionBadAddr(AdEL, to_bits(64, absPC))) /* XXX absPC may be truncated */
  else if not (pcc.tag) then
    (raise_c2_exception_noreg(CapEx_TagViolation))
  else if (pcc.sealed) then
    (raise_c2_exception_noreg(CapEx_SealViolation))
  else if not(pcc.permit_execute) then
    (raise_c2_exception_noreg(CapEx_PermitExecuteViolation))
  else if ((absPC + 4) > top) then
    (raise_c2_exception_noreg(CapEx_LengthViolation))
  else
    TLBTranslate(to_bits(64, absPC), Instruction) /* XXX assert absPC never gets truncated due to above check and top <= 2^64 for valid caps */
}

/*!  
THIS raises a co-processor unusable exception if `CP0Status.CU[2]`
is not set. All capability instructions must first check that the
capability co-processor is enabled. This allows the operating system
to only save and restore the full capability context for processes
that use capabilities.
*/
val checkCP2usable : unit -> unit effect {rreg, wreg, escape}
function checkCP2usable ()  =
  if not (CP0Status.CU()[2]) then {
    CP0Cause->CE() = 0b10;
    SignalException(CpU);
  }

function init_cp2_state () = {
  PCC = default_cap;
  NextPCC = default_cap;
  DelayedPCC = default_cap;
  DDC  = default_cap;
  KCC  = default_cap;
  EPCC = default_cap;
  ErrorEPCC = default_cap;
  KDC  = null_cap;
  KR1C = null_cap;
  KR2C = null_cap;
  CPLR = null_cap;
  CULR = null_cap;
  foreach(i from 1 to 31) {
    let idx = to_bits(5, i) in
    writeCapReg(idx, null_cap)
  }
}

function cp2_next_pc () = {
  PCC = NextPCC;
  if InBranchDelay then {
    NextPCC = DelayedPCC;
  };
}

function get_CP0EPC () =
  to_bits(64, getCapOffset(EPCC))

/* EPC is the offset of EPCC so treat as set offset. 
   Take care to clear tag if EPCC is sealed or result is not representable. */
function set_CP0EPC (newEPC) = {
  let (representable, newEPCC) = setCapOffset(EPCC, newEPC);
  /* Unrepresentable EPCC should only happen if CP0EPC is
    written with something far outside bounds of EPCC. Exceptions should
    not cause an unrepresentable EPCC because the PC of the faulting
    instruction is necessarily in-bounds (or nearly in-bounds). For jumps
    that take the PC out-of-bounds the CP2 exception occurs on the jump,
    not the target. */
  EPCC = if representable then
      {newEPCC with tag = newEPCC.tag & not(newEPCC.sealed)}
    else
      int_to_cap(to_bits(64, getCapBase(EPCC)) + newEPC);
}

/* As above but for ErrorEPC... */
function get_CP0ErrorEPC () =
  to_bits(64, getCapOffset(ErrorEPCC))

function set_CP0ErrorEPC (v) = {
  let (representable, newErrorEPCC) = setCapOffset(ErrorEPCC, v);
  ErrorEPCC = if representable then
      {newErrorEPCC with tag = newErrorEPCC.tag & not(newErrorEPCC.sealed)}
    else
      int_to_cap(to_bits(64, getCapBase(ErrorEPCC)) + v);
}

function capToString (cap, fixlen) = {
         skip_escape(); /* because cheri128 getCapX functions contain asserts but cheri256 ones do not */
         len = getCapLength(cap);
         /* When dumping caps at end of test we cap length at 64 bits for compatibility with test suite, when tracing we print the actual value */
         len_str = if fixlen then BitStr(to_bits(64, min(len, MAX(64)))) else BitStr(to_bits(68, len));
         /* Print architectural type which is -1 for unsealed caps */
         let otype64 : bits(64) = if cap.sealed then zero_extend(cap.otype) else ones();
         concat_str(" t:",
         concat_str(if cap.tag then "1" else "0",
         concat_str(" s:",
         concat_str(if cap.sealed then "1" else "0",
         concat_str(" perms:",
         concat_str(BitStr(0b0 @ getCapPerms(cap)),
         concat_str(" type:",
         concat_str(BitStr(otype64),
         concat_str(" offset:",
         concat_str(BitStr(to_bits(64, getCapOffset(cap))),
         concat_str(" base:",
         concat_str(BitStr(to_bits(64, getCapBase(cap))),
         concat_str(" length:", len_str)))))))))))))
         }

function dump_cp2_state () = {
  print(concat_str("DEBUG CAP PCC", capToString(PCC, true)));
  foreach(i from 0 to 31) {
    print(concat_str("DEBUG CAP REG ", concat_str(string_of_int(i), capToString(readCapReg(to_bits(5, i)), true))))
  };
  print(concat_str("DEBUG CAP HWREG 00", capToString(DDC, true)));
  print(concat_str("DEBUG CAP HWREG 01", capToString(CULR, true)));
  print(concat_str("DEBUG CAP HWREG 08", capToString(CPLR, true)));
  /* TODO: these two should not be mirrored to match the FPGA */
  print(concat_str("DEBUG CAP HWREG 22", capToString(KR1C, true)));
  print(concat_str("DEBUG CAP HWREG 23", capToString(KR2C, true)));
  /* ErrorEPCC, KCC, KDC, EPCC */
  print(concat_str("DEBUG CAP HWREG 28", capToString(ErrorEPCC, true)));
  print(concat_str("DEBUG CAP HWREG 29", capToString(KCC, true)));
  print(concat_str("DEBUG CAP HWREG 30", capToString(KDC, true)));
  print(concat_str("DEBUG CAP HWREG 31", capToString(EPCC, true)));

}
