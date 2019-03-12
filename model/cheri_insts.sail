/*========================================================================*/
/*                                                                        */
/*  Copyright (c) 2015-2019 Robert M. Norton                              */
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

function raise_c2_exception6(capEx, regnum) =
  {
    print("CHERI " ^ string_of_capex(capEx) ^ " Reg=" ^ BitStr(regnum));
    let cause : cheri_cause = struct {
        cap_idx = regnum,
        capEx   = capEx
    };
    let t : sync_exception = struct {
      trap = E_CHERI,
      excinfo = (None() : option(xlenbits)),
      ccause = Some(cause)
    };
    nextPC = handle_exception(cur_privilege, CTL_TRAP(t), PC);
    false
  }

/*!
causes the processor to raise a capability exception by writing the given capability exception cause and register number to the xccsr register then signalling an exception. */
val raise_c2_exception : (CapEx, bits(5)) -> bool effect {escape, rreg, wreg}
function raise_c2_exception(capEx, regnum) =
  let reg6 = 0b0 @ regnum in
  raise_c2_exception6(capEx, reg6)

/*!
is as [raise_c2_exception] except that CapCause.RegNum  is written with the special value 0x10 indicating PCC register.
 */
val raise_c2_exception_pcc : (CapEx) -> bool effect {escape, rreg, wreg}
function raise_c2_exception_pcc(capEx) =
  raise_c2_exception6(capEx, 0b100000)

val pcc_access_system_regs : unit -> bool effect {rreg}
function pcc_access_system_regs () = PCC.access_system_regs

val execute_branch_pcc : Capability -> unit effect {wreg}
function execute_branch_pcc(newPCC) = {
  nextPC = newPCC.address;
  nextPCC = newPCC;
}

/* Operations that extract parts of a capability into GPR */

union clause ast = CGetPerm   : (regbits, regbits)
union clause ast = CGetType   : (regbits, regbits)
union clause ast = CGetBase   : (regbits, regbits)
union clause ast = CGetLen    : (regbits, regbits)
union clause ast = CGetTag    : (regbits, regbits)
union clause ast = CGetSealed : (regbits, regbits)
union clause ast = CGetOffset : (regbits, regbits)
union clause ast = CGetAddr   : (regbits, regbits)

function clause execute (CGetPerm(rd, cb)) =
{
  checkCP2usable();
  let capVal = readCapReg(cb);
  wGPR(rd) = zero_extend(getCapPerms(capVal));
  true
}

function clause execute (CGetType(rd, cb)) =
{
  checkCP2usable();
  let capVal = readCapReg(cb);
  wGPR(rd) = if capVal.sealed
    then zero_extend(capVal.otype)
    else 0xffffffffffffffff;
  true
}

function clause execute (CGetBase(rd, cb)) =
{
  checkCP2usable();
  let capVal = readCapReg(cb);
  wGPR(rd) = to_bits(64, getCapBase(capVal));
  true
}

function clause execute (CGetOffset(rd, cb)) =
{
  checkCP2usable();
  let capVal = readCapReg(cb);
  wGPR(rd) = to_bits(64, getCapOffset(capVal));
  true
}

function clause execute (CGetLen(rd, cb)) =
{
  checkCP2usable();
  let capVal = readCapReg(cb);
  let len65  = getCapLength(capVal);
  wGPR(rd) = to_bits(64, if len65 > MAX_U64 then MAX_U64 else len65);
  true
}

function clause execute (CGetTag(rd, cb)) =
{
  checkCP2usable();
  let capVal = readCapReg(cb);
  wGPR(rd) = zero_extend(capVal.tag);
  true
}

function clause execute (CGetSealed(rd, cb)) =
{
  checkCP2usable();
  let capVal = readCapReg(cb);
  wGPR(rd) = zero_extend(capVal.sealed);
  true
}

function clause execute (CGetAddr(rd, cb)) =
{
  checkCP2usable();
  let capVal = readCapReg(cb);
  wGPR(rd) = to_bits(64, getCapCursor(capVal));
  true
}
/*

union clause ast = CGetPCCSetOffset : (regbits, regbits)
function clause execute (CGetPCCSetOffset(cd, rs)) =
{
  checkCP2usable();
  let rs_val = rGPR(rs);
  let (success, newPCC) = setCapOffset(PCC, rs_val);
  if (success) then
    writeCapReg(cd, newPCC)
  else
    writeCapReg(cd, int_to_cap(rs_val));
  true
}
/* Get and Set CP2 cause register */

union clause ast = CGetCause : regbits
function clause execute (CGetCause(rd)) = 
{
  checkCP2usable();
  if not (pcc_access_system_regs ()) then
    raise_c2_exception_pcc(CapEx_AccessSystemRegsViolation)
  else {
    wGPR(rd) = zero_extend(CapCause.bits());
    true
  }
}

union clause ast = CSetCause : regbits
function clause execute (CSetCause(rt)) = 
{
  checkCP2usable();
  if not (pcc_access_system_regs ()) then
    raise_c2_exception_pcc(CapEx_AccessSystemRegsViolation)
  else
  {
    let rt_val = rGPR(rt);
    CapCause->ExcCode() = rt_val[15..8];
    CapCause->RegNum()  = rt_val[7..0];
    true
  }
}

*/

union clause ast = CSpecialRW : (regbits, regbits, regbits)
function clause execute (CSpecialRW(cd, cs, idx)) =
{
  checkCP2usable();
  let (specialExists, ro, priv, needASR) : (bool, bool, Privilege, bool) = match idx {
    0  => (true, true,  User, false),
    1  => (true, false, User, false),
    4  => (true, false, User, true),
    6  => (true, false, User, true),
    7  => (true, false, User, true),
    12 => (true, false, Supervisor, true),
    14 => (true, false, Supervisor, true),
    15 => (true, false, Supervisor, true),
    28 => (true, false, Machine, true),
    30 => (true, false, Machine, true),
    31 => (true, false, Machine, true),
    _  => (false, true, Machine, true)
  };
  if (not(specialExists)) then {
    handle_illegal();
    false
  } else if (ro & cs != 0) |
     (cur_privilege <_u priv) |
     (needASR & not(pcc_access_system_regs())) then {
    raise_c2_exception6(CapEx_AccessSystemRegsViolation, 0b1 @ idx)
  } else {
    let cs_val = readCapReg(cs);
    if (cd != 0) then {
      // read special cap
      let special_val : Capability = match idx {
        0  => {
          let (success, pcc) = setCapAddr(PCC, PC);
          assert (success, "PCC with offset PC should always be representable");
          pcc
        },
        1  => DDC,
        4  => UTCC,
        6  => UScratchC,
        7  => UEPCC, /* XXX should mask offset as per uepc etc? */
        12 => STCC,
        14 => SScratchC,
        15 => SEPCC,
        28 => MTCC,
        30 => MScratchC,
        31 => MEPCC,
        _  => {assert(false, "unreachable"); null_cap}
      };
      writeCapReg(cd, special_val);
    };
    if (cs != 0) then {
      // write special cap
      match idx {
        1  => DDC = cs_val,
        4  => UTCC = cs_val,   /* XXX should legalize mode? */
        6  => UScratchC = cs_val,
        7  => UEPCC = cs_val, /* XXX should legalize offset as per uepc etc? */
        12 => STCC = cs_val,
        14 => SScratchC = cs_val,
        15 => SEPCC = cs_val,
        28 => MTCC = cs_val,
        30 => MScratchC = cs_val,
        31 => MEPCC = cs_val,
        _  => assert(false, "unreachable")
      }
    };
    true
  }
}

union clause ast = CAndPerm : (regbits, regbits, regbits)
function clause execute(CAndPerm(cd, cb, rt)) = 
{
  checkCP2usable();
  let cb_val = readCapReg(cb);
  let rt_val = rGPR(rt);
  if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else
  {
    let perms   = getCapPerms(cb_val);
    let newCap  = setCapPerms(cb_val, (perms & rt_val[30..0]));
    writeCapReg(cd, newCap);
    true
  }
}



union clause ast = CToPtr : (regbits, regbits, regbits)
function clause execute(CToPtr(rd, cb, ct)) = 
{
  checkCP2usable();
  let ct_val = readCapRegDDC(ct);
  let cb_val = readCapReg(cb);
  if not (ct_val.tag) then
    raise_c2_exception(CapEx_TagViolation, ct)
  else if cb_val.tag & cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else 
  {
    let ctBase = getCapBase(ct_val);
    /* Note: returning zero for untagged values breaks magic constants such as SIG_IGN */
    wGPR(rd) = if not (cb_val.tag) then
        zeros()
      else
        to_bits(64, getCapCursor(cb_val) - ctBase);
    true
  }
}

union clause ast = CIncOffset : (regbits, regbits, regbits)
function clause execute (CIncOffset(cd, cb, rt)) =
{
  checkCP2usable();
  let cb_val = readCapReg(cb);
  let rt_val = rGPR(rt);
  if cb_val.tag & cb_val.sealed & (rt_val != 0x0000000000000000) then
    raise_c2_exception(CapEx_SealViolation, cb)
  else
  {
    let (success, newCap) = incCapOffset(cb_val, rt_val);
    if success then
        writeCapReg(cd, newCap)
    else
        writeCapReg(cd, int_to_cap(to_bits(64, getCapBase(cb_val)) + rt_val));
    true
  }
}

union clause ast = CIncOffsetImmediate : (regbits, regbits, bits(12))
function clause execute (CIncOffsetImmediate(cd, cb, imm)) =
{
  checkCP2usable();
  let cb_val = readCapReg(cb);
  let imm64 : bits(64) = sign_extend(imm);
  if cb_val.tag & cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else
  {
    let (success, newCap) = incCapOffset(cb_val, imm64);
    if success then
        writeCapReg(cd, newCap)
    else
        writeCapReg(cd, int_to_cap(to_bits(64, getCapBase(cb_val)) + imm64));
    true
  }
}

union clause ast = CSetOffset : (regbits, regbits, regbits)
function clause execute (CSetOffset(cd, cb, rt)) =
{
  checkCP2usable();
  let cb_val = readCapReg(cb);
  let rt_val = rGPR(rt);
  if cb_val.tag & cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else
  {
    let (success, newCap) = setCapOffset(cb_val, rt_val);
    if success then
        writeCapReg(cd, newCap)
    else
        writeCapReg(cd, int_to_cap(to_bits(64, getCapBase(cb_val)) + rt_val));
    true
  }
}

union clause ast = CSetBounds : (regbits, regbits, regbits)
function clause execute (CSetBounds(cd, cb, rt)) =
{
  checkCP2usable();
  let cb_val = readCapReg(cb);
  let rt_val = unsigned(rGPR(rt));
  let cursor = getCapCursor(cb_val);
  let base   = getCapBase(cb_val);
  let top    = getCapTop(cb_val);
  let newTop = cursor + rt_val;
  if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else if cursor < base then
    raise_c2_exception(CapEx_LengthViolation, cb)
  else if newTop > top then
    raise_c2_exception(CapEx_LengthViolation, cb)
  else
  {
    let (_, newCap) = setCapBounds(cb_val, to_bits(64, cursor), to_bits(65, newTop));
    writeCapReg(cd, newCap); /* ignore exact */
    true
  }
}

union clause ast = CSetBoundsImmediate : (regbits, regbits, bits(12))
function clause execute (CSetBoundsImmediate(cd, cb, imm)) =
{
  checkCP2usable();
  let cb_val = readCapReg(cb);
  let immU   = unsigned(imm);
  let cursor = getCapCursor(cb_val);
  let base   = getCapBase(cb_val);
  let top    = getCapTop(cb_val);
  let newTop = cursor + immU;
  if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else if cursor < base then
    raise_c2_exception(CapEx_LengthViolation, cb)
  else if newTop > top then
    raise_c2_exception(CapEx_LengthViolation, cb)
  else
  {
    let (_, newCap) = setCapBounds(cb_val, to_bits(64, cursor), to_bits(65, newTop));
    writeCapReg(cd, newCap); /* ignore exact */
    true
  }
}

union clause ast = CSetBoundsExact : (regbits, regbits, regbits)
function clause execute (CSetBoundsExact(cd, cb, rt)) =
{
  checkCP2usable();
  let cb_val = readCapReg(cb);
  let rt_val = unsigned(rGPR(rt));
  let cursor = getCapCursor(cb_val);
  let base   = getCapBase(cb_val);
  let top    = getCapTop(cb_val);
  let newTop = cursor + rt_val;
  if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else if cursor < base then
    raise_c2_exception(CapEx_LengthViolation, cb)
  else if newTop > top then
    raise_c2_exception(CapEx_LengthViolation, cb)
  else
  {
    let (exact, newCap) = setCapBounds(cb_val, to_bits(64, cursor), to_bits(65, newTop));
    if not (exact) then
        raise_c2_exception(CapEx_InexactBounds, cb)
    else {
        writeCapReg(cd, newCap);
        true
    }
  }
}

union clause ast = CClearTag : (regbits, regbits)
function clause execute (CClearTag(cd, cb)) =
{
  checkCP2usable();
  let cb_val = readCapReg(cb);
  writeCapReg(cd, {cb_val with tag=false});
  true
}

union clause ast = CMove : (regbits, regbits)
function clause execute (CMove(cd, cb)) =
{
  checkCP2usable();
  writeCapReg(cd) = readCapReg(cb);
  true
}

union clause ast = ClearRegs : (ClearRegSet, bits(2), bits(8))
function clause execute (ClearRegs(regset, q, m)) =
{
  /*
  if ((regset == CLo) | (regset == CHi)) then
    checkCP2usable();
  */
  foreach (i from 0 to 7)
    if (m[i]) then
      match regset {
        GPRegs => wGPR(8 * unsigned(q) + i) = zeros(),
        FPRegs => () /* XXX no F regs yet */
      };
  true
}

union clause ast = CFromPtr : (regbits, regbits, regbits)
function clause execute (CFromPtr(cd, cb, rt)) =
{
  checkCP2usable();
  let cb_val = readCapRegDDC(cb);
  let rt_val = rGPR(rt);
  if rt_val == 0x0000000000000000 then {
    writeCapReg(cd, null_cap);
    true
  } else if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else
  {
    let (success, newCap) = setCapOffset(cb_val, rt_val);
    if success then
        writeCapReg(cd, newCap)
    else
        writeCapReg(cd, int_to_cap(to_bits(64, getCapBase(cb_val)) + rt_val));
    true
  }
}

union clause ast = CBuildCap : (regbits, regbits, regbits)
function clause execute (CBuildCap(cd, cb, ct)) =
{
  checkCP2usable();
  let cb_val = readCapRegDDC(cb);
  let ct_val = readCapReg(ct);
  let cb_base = getCapBase(cb_val);
  let ct_base = getCapBase(ct_val);
  let cb_top = getCapTop(cb_val);
  let ct_top = getCapTop(ct_val);
  let cb_perms = getCapPerms(cb_val);
  let ct_perms = getCapPerms(ct_val);
  let ct_offset = getCapOffset(ct_val);
  if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else if ct_base < cb_base then
    raise_c2_exception(CapEx_LengthViolation, cb)
  else if ct_top > cb_top then
    raise_c2_exception(CapEx_LengthViolation, cb)
   else if ct_base > ct_top then /* check for length < 0 - possible because ct might be untagged */
    raise_c2_exception(CapEx_LengthViolation, ct)
   else if (ct_perms & cb_perms) != ct_perms then
    raise_c2_exception(CapEx_UserDefViolation, cb)
  else
  {
    let (exact, cd1) = setCapBounds(cb_val, to_bits(64, ct_base), to_bits(65, ct_top));
    let (representable, cd2) = setCapOffset(cd1, to_bits(64, ct_offset));
    let cd3 = setCapPerms(cd2, ct_perms);
    {
      assert(exact, "CBuildCap: setCapBounds was not exact"); /* base and top came from ct originally so will be exact */
      assert(representable, "CBuildCap: offset was not representable"); /* similarly offset should be representable XXX except for fastRepCheck */
      writeCapReg(cd, cd3);
      true
    }
  }
}

union clause ast = CCopyType : (regbits, regbits, regbits)
function clause execute (CCopyType(cd, cb, ct)) =
{
  checkCP2usable();
  let cb_val = readCapReg(cb);
  let ct_val = readCapReg(ct);
  let cb_base = getCapBase(cb_val);
  let cb_top  = getCapTop(cb_val);
  let ct_otype = unsigned(ct_val.otype);
  if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else if ct_val.sealed then
  {
    if ct_otype < cb_base then
      raise_c2_exception(CapEx_LengthViolation, cb)
    else if ct_otype >= cb_top then
      raise_c2_exception(CapEx_LengthViolation, cb)
    else
    {
      let (success, cap) = setCapOffset(cb_val, to_bits(64, ct_otype - cb_base));
      assert(success, "CopyType: offset is in bounds so should be representable");
      writeCapReg(cd, cap);
      true
    }
  }
  else {
    writeCapReg(cd, int_to_cap(0xffffffffffffffff));
    true
  }
}

union clause ast = CCheckPerm : (regbits, regbits)
function clause execute (CCheckPerm(cs, rt)) =
{
  checkCP2usable();
  let cs_val = readCapReg(cs);
  let cs_perms : bits(64) = zero_extend(getCapPerms(cs_val));
  let rt_perms = rGPR(rt);
  if not (cs_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cs)
  else if (cs_perms & rt_perms) != rt_perms then
    raise_c2_exception(CapEx_UserDefViolation, cs)
  else
    true
}

union clause ast = CCheckType : (regbits, regbits)
function clause execute (CCheckType(cs, cb)) =
{
  checkCP2usable();
  let cs_val = readCapReg(cs);
  let cb_val = readCapReg(cb);
  if not (cs_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cs)
  else if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if not (cs_val.sealed) then
    raise_c2_exception(CapEx_SealViolation, cs)
  else if not (cb_val.sealed) then
    raise_c2_exception(CapEx_SealViolation, cb)
  else if cs_val.otype != cb_val.otype then
    raise_c2_exception(CapEx_TypeViolation, cs)
  else
    true
}

union clause ast = CCheckTag : (regbits)
function clause execute (CCheckTag (cs)) =
{
  checkCP2usable();
  let cs_val = readCapReg(cs);
  if not(cs_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cs)
  else
    true
}

union clause ast = CTestSubset : (regbits, regbits, regbits)
function clause execute (CTestSubset(rd, cb, ct)) =
{
  checkCP2usable();
  let cb_val = readCapRegDDC(cb);
  let ct_val = readCapReg(ct);
  let ct_top   = getCapTop(ct_val);
  let ct_base  = getCapBase(ct_val);
  let ct_perms = getCapPerms(ct_val);
  let cb_top   = getCapTop(cb_val);
  let cb_base  = getCapBase(cb_val);
  let cb_perms = getCapPerms(cb_val);
  let result = if cb_val.tag != ct_val.tag then
                0b0
           else if ct_base < cb_base then
                0b0
           else if ct_top > cb_top then
                0b0
           else if (ct_perms & cb_perms) != ct_perms then
                0b0
           else
                0b1;
  wGPR(rd) = zero_extend(result);
  true
}

union clause ast = CSeal : (regbits, regbits, regbits)
function clause execute (CSeal(cd, cs, ct)) =
{
  checkCP2usable();
  let cs_val = readCapReg(cs);
  let ct_val = readCapReg(ct);
  let ct_cursor = getCapCursor(ct_val);
  let ct_top    = getCapTop(ct_val);
  let ct_base   = getCapBase(ct_val);
  if not (cs_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cs)
  else if not (ct_val.tag) then
    raise_c2_exception(CapEx_TagViolation, ct)
  else if cs_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cs)
  else if ct_val.sealed then
    raise_c2_exception(CapEx_SealViolation, ct)
  else if not (ct_val.permit_seal) then
    raise_c2_exception(CapEx_PermitSealViolation, ct)
  else if ct_cursor < ct_base then
    raise_c2_exception(CapEx_LengthViolation, ct)
  else if ct_cursor >= ct_top then
    raise_c2_exception(CapEx_LengthViolation, ct)
  else if ct_cursor > max_otype then
    raise_c2_exception(CapEx_LengthViolation, ct)
  else
  {
    let (success, newCap) = sealCap(cs_val, to_bits(24, ct_cursor));
    if not (success) then
        raise_c2_exception(CapEx_InexactBounds, cs)
    else {
        writeCapReg(cd, newCap);
        true
    }
  }
}

union clause ast = CCSeal : (regbits, regbits, regbits)
function clause execute (CCSeal(cd, cs, ct)) =
{
  checkCP2usable();
  let cs_val = readCapReg(cs);
  let ct_val = readCapReg(ct);
  let ct_cursor = getCapCursor(ct_val);
  let ct_top    = getCapTop(ct_val);
  let ct_base   = getCapBase(ct_val);
  if not (cs_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cs)
  else if not (ct_val.tag) | (getCapCursor(ct_val) == MAX_U64) then {
    writeCapReg(cd, cs_val);
    true
  } else if cs_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cs)
  else if ct_val.sealed then
    raise_c2_exception(CapEx_SealViolation, ct)
  else if not (ct_val.permit_seal) then
    raise_c2_exception(CapEx_PermitSealViolation, ct)
  else if ct_cursor < ct_base then
    raise_c2_exception(CapEx_LengthViolation, ct)
  else if ct_cursor >= ct_top then
    raise_c2_exception(CapEx_LengthViolation, ct)
  else if ct_cursor > max_otype then
    raise_c2_exception(CapEx_LengthViolation, ct)
  else
  {
    let (success, newCap) = sealCap(cs_val, to_bits(24, ct_cursor));
    if not (success) then
      raise_c2_exception(CapEx_InexactBounds, cs)
    else {
      writeCapReg(cd, newCap);
      true
    }
  }
}

union clause ast = CUnseal : (regbits, regbits, regbits)
function clause execute (CUnseal(cd, cs, ct)) =
{
  checkCP2usable();
  let cs_val = readCapReg(cs);
  let ct_val = readCapReg(ct);
  let ct_cursor = getCapCursor(ct_val);
  if not (cs_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cs)
  else if not (ct_val.tag) then
    raise_c2_exception(CapEx_TagViolation, ct)
  else if not (cs_val.sealed) then
    raise_c2_exception(CapEx_SealViolation, cs)
  else if ct_val.sealed then
    raise_c2_exception(CapEx_SealViolation, ct)
  else if ct_cursor != unsigned(cs_val.otype) then
    raise_c2_exception(CapEx_TypeViolation, ct)
  else if not (ct_val.permit_unseal) then
    raise_c2_exception(CapEx_PermitUnsealViolation, ct)
  else if ct_cursor <  getCapBase(ct_val) then
    raise_c2_exception(CapEx_LengthViolation, ct)
  else if ct_cursor >= getCapTop(ct_val) then
    raise_c2_exception(CapEx_LengthViolation, ct)
  else {
    writeCapReg(cd, {unsealCap(cs_val) with 
      global=(cs_val.global & ct_val.global)
    });
    true
  }
}

union clause ast = CCall : (regbits, regbits, regbits)
function clause execute (CCall(cs, cb, 0b00000)) = /* selector=0 */
{
  /* Partial implementation of CCall with checks in hardware, but raising a trap to perform trusted stack manipulation */
  checkCP2usable();
  let cs_val = readCapReg(cs);
  let cb_val = readCapReg(cb);
  let cs_cursor = getCapCursor(cs_val);
  if not (cs_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cs)
  else if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if not (cs_val.sealed) then
    raise_c2_exception(CapEx_SealViolation, cs)
  else if not (cb_val.sealed) then
    raise_c2_exception(CapEx_SealViolation, cb)
  else if cs_val.otype != cb_val.otype then
    raise_c2_exception(CapEx_TypeViolation, cs)
  else if not (cs_val.permit_execute) then
    raise_c2_exception(CapEx_PermitExecuteViolation, cs)
  else if cb_val.permit_execute then
    raise_c2_exception(CapEx_PermitExecuteViolation, cb)
  else if cs_cursor < getCapBase(cs_val) then
    raise_c2_exception(CapEx_LengthViolation, cs)
  else if cs_cursor >= getCapTop(cs_val) then
    raise_c2_exception(CapEx_LengthViolation, cs)
  else
    raise_c2_exception(CapEx_CallTrap, cs);
}

function clause execute (CCall(cs, cb, 0b00001)) = /* selector=1 */
{
  /* Jump-like implementation of CCall that unseals arguments */
  checkCP2usable();
  let cs_val = readCapReg(cs);
  let cb_val = readCapReg(cb);
  let cs_cursor = getCapCursor(cs_val);
  if not (cs_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cs)
  else if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if not (cs_val.sealed) then
    raise_c2_exception(CapEx_SealViolation, cs)
  else if not (cb_val.sealed) then
    raise_c2_exception(CapEx_SealViolation, cb)
  else if cs_val.otype != cb_val.otype then
    raise_c2_exception(CapEx_TypeViolation, cs)
  else if not (cs_val.permit_ccall) then
    raise_c2_exception(CapEx_PermitCCallViolation, cs)
  else if not (cb_val.permit_ccall) then
    raise_c2_exception(CapEx_PermitCCallViolation, cb)
  else if not (cs_val.permit_execute) then
    raise_c2_exception(CapEx_PermitExecuteViolation, cs)
  else if cb_val.permit_execute then
    raise_c2_exception(CapEx_PermitExecuteViolation, cb)
  else if cs_cursor < getCapBase(cs_val) then
    raise_c2_exception(CapEx_LengthViolation, cs)
  else if cs_cursor >= getCapTop(cs_val) then
    raise_c2_exception(CapEx_LengthViolation, cs)
  else
  {
    
    C26 = unsealCap(cb_val);
    nextPC = cs_val.address;
    nextPCC = unsealCap(cs_val);
    true
  }
}

function clause execute (CCall(_, _, 0b11111)) = /* CReturn */
{
  checkCP2usable();
  raise_c2_exception(CapEx_ReturnTrap, 0b11111) /* XXX what should correct reg number be? */
}

union clause ast = CJALR : (regbits, regbits)
function clause execute(CJALR(cd, cb)) = 
{
  checkCP2usable();
  let cb_val = readCapReg(cb);
  let cb_ptr = getCapCursor(cb_val);
  let cb_top = getCapTop(cb_val);
  let cb_base= getCapBase(cb_val);
  if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if (cb_val.sealed) then
    raise_c2_exception(CapEx_SealViolation, cb)
  else if not (cb_val.permit_execute) then
    raise_c2_exception(CapEx_PermitExecuteViolation, cb)
  else if cb_ptr < cb_base then
    raise_c2_exception(CapEx_LengthViolation, cb)
  else if (cb_ptr + min_inst_bytes) > cb_top then
    raise_c2_exception(CapEx_LengthViolation, cb)
  else if (cb_ptr % min_inst_bytes) != 0 then {
    handle_mem_exception(to_bits(xlen, cb_ptr),  E_Fetch_Addr_Align);
    false
  } else {
    let (success, linkCap) = setCapAddr(PCC, nextPC); /* Note that nextPC accounts for compressed instrucitons */
    assert(success, "Link cap should always be representable.");
    writeCapReg(cd, linkCap);
    execute_branch_pcc(cb_val);
    true
  };
}

val handle_load_data_via_cap : (regbits, bits(6), Capability, uint64, bool, word_width) -> bool effect {escape, rmem, rreg, wmv, wmvt, wreg}
function handle_load_data_via_cap(rd, cs, cap_val, vaddr, is_unsigned, width) = {
  let (base, top) = getCapBounds(cap_val);
  let vaddrBits = to_bits(xlen, vaddr);
  let size = word_width_bytes(width);
  let aq : bool = false;
  let rl : bool = false;
  if not(cap_val.tag) then {
    raise_c2_exception6(CapEx_TagViolation, cs);
  } else if cap_val.sealed then {
    raise_c2_exception6(CapEx_SealViolation, cs);
  } else if not (cap_val.permit_load) then {
    raise_c2_exception6(CapEx_PermitLoadViolation, cs);
  } else if (vaddr + size) > top then {
    raise_c2_exception6(CapEx_LengthViolation, cs);
  } else if vaddr < base then {
    raise_c2_exception6(CapEx_LengthViolation, cs);
  } else if check_misaligned(vaddrBits, width) then {
    handle_mem_exception(vaddrBits, E_Load_Addr_Align);
    false
  } else match translateAddr(vaddrBits, Read, Data) {
    TR_Failure(e) => { handle_mem_exception(vaddrBits, e); false },
    TR_Address(addr) => process_load(rd, vaddrBits, mem_read(addr, size, aq, rl, false), is_unsigned)
  }
}

union clause ast = CLoadDDC : (regbits, regbits, bool, word_width)
function clause execute (CLoadDDC(rd, rs, is_unsigned, width)) =
{
  checkCP2usable();
  let ddc_val = DDC;
  let vaddr = (getCapBase(ddc_val) + unsigned(X(rs))) % pow2(xlen);
  handle_load_data_via_cap(rd, 0b100001, ddc_val, vaddr, is_unsigned, width)
}

union clause ast = CLoadCap : (regbits, regbits, bool, word_width)
function clause execute (CLoadCap(rd, cs, is_unsigned, width)) =
{
  checkCP2usable();
  let cap_val = readCapReg(cs);
  let vaddr = getCapCursor(cap_val);
  handle_load_data_via_cap(rd, 0b0 @ cs, cap_val, vaddr, is_unsigned, width)
}

val handle_load_cap_via_cap : (regbits, bits(6), Capability, uint64) -> bool effect {escape, rmem, rmemt, rreg, wmv, wmvt, wreg}
function handle_load_cap_via_cap(rd, cs, cap_val, vaddr) = {
  let (base, top) = getCapBounds(cap_val);
  let vaddrBits = to_bits(xlen, vaddr);
  let aq : bool = false;
  let rl : bool = false;
  if not(cap_val.tag) then {
    raise_c2_exception6(CapEx_TagViolation, cs);
  } else if cap_val.sealed then {
    raise_c2_exception6(CapEx_SealViolation, cs);
  } else if not (cap_val.permit_load) then {
    raise_c2_exception6(CapEx_PermitLoadViolation, cs);
  } else if (vaddr + cap_size) > top then {
    raise_c2_exception6(CapEx_LengthViolation, cs);
  } else if vaddr < base then {
    raise_c2_exception6(CapEx_LengthViolation, cs);
  } else if not(is_aligned_addr(vaddrBits, cap_size)) then {
    handle_mem_exception(vaddrBits, E_Load_Addr_Align);
    false
  } else match translateAddr(vaddrBits, Read, Data) {
    TR_Failure(e) => { handle_mem_exception(vaddrBits, e); false },
    TR_Address(addr) => {
      let c = mem_read_cap(addr, aq, rl, false);
      match c {
        MemValue(v) => {writeCapReg(rd, v); true},
        MemException(e) => {handle_mem_exception(vaddrBits, e); false }
      }
    }
  }
}

union clause ast = CLoadCapDDC : (regbits, regbits)
function clause execute (CLoadCapDDC(rd, rs)) =
{
  checkCP2usable();
  let ddc_val = DDC;
  let vaddr = (getCapBase(ddc_val) + unsigned(X(rs))) % pow2(xlen);
  handle_load_cap_via_cap(rd, 0b100001, ddc_val, vaddr)
}

union clause ast = CLoadCapCap : (regbits, regbits)
function clause execute (CLoadCapCap(rd, cs)) =
{
  checkCP2usable();
  let cap_val = readCapReg(cs);
  let vaddr = getCapCursor(cap_val);
  handle_load_cap_via_cap(rd, 0b0 @ cs, cap_val, vaddr)
}

val handle_store_data_via_cap : (regbits, regbits, Capability, uint64, word_width) -> bool effect {eamem, escape, rmem, rreg, wmv, wmvt, wreg}
function handle_store_data_via_cap(rs, cs, cap_val, vaddr, width) = {
  let (base, top) = getCapBounds(cap_val);
  let vaddrBits = to_bits(xlen, vaddr);
  let size = word_width_bytes(width);
  let aq : bool = false;
  let rl : bool = false;
  if not(cap_val.tag) then {
    raise_c2_exception(CapEx_TagViolation, cs);
  } else if cap_val.sealed then {
    raise_c2_exception(CapEx_SealViolation, cs);
  } else if not (cap_val.permit_store) then {
    raise_c2_exception(CapEx_PermitStoreViolation, cs);
  } else if (vaddr + size) > top then {
    raise_c2_exception(CapEx_LengthViolation, cs);
  } else if vaddr < base then {
    raise_c2_exception(CapEx_LengthViolation, cs);
  } else if check_misaligned(vaddrBits, width) then {
    handle_mem_exception(vaddrBits, E_SAMO_Addr_Align);
    false
  } else match translateAddr(vaddrBits, Write, Data) {
    TR_Failure(e) => { handle_mem_exception(vaddrBits, e); false },
    TR_Address(addr) => {
      let eares : MemoryOpResult(unit) = mem_write_ea(addr, size, aq, rl, false);
      match (eares) {
        MemException(e) => { handle_mem_exception(addr, e); false },
        MemValue(_) => {
          let rs_val = X(rs);
          let res : MemoryOpResult(bool) = match width {
            BYTE   => mem_write_value(addr, 1, rs_val[7..0],  aq, rl, false),
            HALF   => mem_write_value(addr, 2, rs_val[15..0], aq, rl, false),
            WORD   => mem_write_value(addr, 4, rs_val[31..0], aq, rl, false),
            DOUBLE => mem_write_value(addr, 8, rs_val,        aq, rl, false)
          };
          match (res) {
            MemValue(true)  => true,
            MemValue(false) => internal_error("store got false from mem_write_value"),
            MemException(e) => { handle_mem_exception(addr, e); false }
          }
        }
      }
    }
  }
}

union clause ast = CStoreDDC : (regbits, regbits, word_width)
function clause execute (CStoreDDC(rd, rs, width)) =
{
  checkCP2usable();
  let ddc_val = DDC;
  let vaddr = (getCapBase(ddc_val) + unsigned(X(rs))) % pow2(xlen);
  handle_store_data_via_cap(rd, 0b00000, ddc_val, vaddr, width)
}

union clause ast = CStoreCap : (regbits, regbits, word_width)
function clause execute (CStoreCap(rs, cs, width)) =
{
  checkCP2usable();
  let cap_val = readCapReg(cs);
  let vaddr = getCapCursor(cap_val);
  handle_store_data_via_cap(rs, cs, cap_val, vaddr, width)
}

val handle_store_cap_via_cap : (regbits, regbits, Capability, uint64) -> bool effect {eamem, escape, rmem, rreg, wmv, wreg, wmvt}
function handle_store_cap_via_cap(rs, cs, cap_val, vaddr) = {
  let (base, top) = getCapBounds(cap_val);
  let vaddrBits = to_bits(xlen, vaddr);
  let aq : bool = false;
  let rl : bool = false;
  if not(cap_val.tag) then {
    raise_c2_exception(CapEx_TagViolation, cs);
  } else if cap_val.sealed then {
    raise_c2_exception(CapEx_SealViolation, cs);
  } else if not (cap_val.permit_store) then {
    raise_c2_exception(CapEx_PermitStoreViolation, cs);
  } else if (vaddr + cap_size) > top then {
    raise_c2_exception(CapEx_LengthViolation, cs);
  } else if vaddr < base then {
    raise_c2_exception(CapEx_LengthViolation, cs);
  } else if not(is_aligned_addr(vaddrBits, cap_size)) then {
    handle_mem_exception(vaddrBits, E_SAMO_Addr_Align);
    false
  } else match translateAddr(vaddrBits, Write, Data) {
    TR_Failure(e) => { handle_mem_exception(vaddrBits, e); false },
    TR_Address(addr) => {
      let eares : MemoryOpResult(unit) = mem_write_ea_cap(addr, aq, rl, false);
      match (eares) {
        MemException(e) => { handle_mem_exception(addr, e); false },
        MemValue(_) => {
          let rs_val = readCapReg(rs);
          let res : MemoryOpResult(bool) = mem_write_cap(addr, rs_val, aq, rl, false);
          match (res) {
            MemValue(true)  => true,
            MemValue(false) => internal_error("store got false from mem_write_value"),
            MemException(e) => { handle_mem_exception(addr, e); false }
          }
        }
      }
    }
  }
}

union clause ast = CStoreCapDDC : (regbits, regbits)
function clause execute (CStoreCapDDC(rd, rs)) =
{
  checkCP2usable();
  let ddc_val = DDC;
  let vaddr = (getCapBase(ddc_val) + unsigned(X(rs))) % pow2(xlen);
  handle_store_cap_via_cap(rd, 0b00000, ddc_val, vaddr)
}

union clause ast = CStoreCapCap : (regbits, regbits)
function clause execute (CStoreCapCap(rs, cs)) =
{
  checkCP2usable();
  let cap_val = readCapReg(cs);
  let vaddr = getCapCursor(cap_val);
  handle_store_cap_via_cap(rs, cs, cap_val, vaddr)
}

/*

union clause ast = CLoadTags : (regbits, regbits)
function clause execute (CLoadTags(rd, cb)) =
{
  checkCP2usable();
  let cb_val = readCapRegDDC(cb);
  if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else if not (cb_val.permit_load) then
    raise_c2_exception(CapEx_PermitLoadViolation, cb)
  else if not (cb_val.permit_load_cap) then
    raise_c2_exception(CapEx_PermitLoadViolation, cb)
  else
  {
    let vAddr   = getCapCursor(cb_val);
    let vAddr64 = to_bits(64, getCapCursor(cb_val));
    if (vAddr + 8 * cap_size) > getCapTop(cb_val) then
      raise_c2_exception(CapEx_LengthViolation, cb)
    else if vAddr < getCapBase(cb_val) then
      raise_c2_exception(CapEx_LengthViolation, cb)
    else if not (vAddr64[5..0] == 0b000000) then /* XXX Cache line width? */
      SignalExceptionBadAddr(AdEL, vAddr64)
    else
      {
        let pAddr  = TLBTranslate(vAddr64, LoadData);
        let tag0   = MEMr_tag(pAddr + 0*cap_size);
        let tag1   = MEMr_tag(pAddr + 1*cap_size);
        let tag2   = MEMr_tag(pAddr + 2*cap_size);
        let tag3   = MEMr_tag(pAddr + 3*cap_size);
        let tag4   = MEMr_tag(pAddr + 4*cap_size);
        let tag5   = MEMr_tag(pAddr + 5*cap_size);
        let tag6   = MEMr_tag(pAddr + 6*cap_size);
        let tag7   = MEMr_tag(pAddr + 7*cap_size);
        wGPR(rd)   = zero_extend (tag7 @ tag6 @ tag5 @ tag4
                                @ tag3 @ tag2 @ tag1 @ tag0);
        true
      }
  }
}

union clause ast = CStore : (regbits, regbits, regbits, bits(8), WordType)
function clause execute (CStore(rs, cb, rt, offset, width)) =
{
  checkCP2usable();
  let cb_val = readCapRegDDC(cb);
  if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else if not (cb_val.permit_store) then
    raise_c2_exception(CapEx_PermitStoreViolation, cb)
  else
  {
    let size   = wordWidthBytes(width);
    let cursor = getCapCursor(cb_val);
    let vAddr  = (cursor + unsigned(rGPR(rt)) + size * signed(offset)) % pow2(64);
    let vAddr64= to_bits(64, vAddr);
    if (vAddr + size) > getCapTop(cb_val) then
      raise_c2_exception(CapEx_LengthViolation, cb)
    else if vAddr < getCapBase(cb_val) then
      raise_c2_exception(CapEx_LengthViolation, cb)
    else if not (isAddressAligned(vAddr64, width)) then
      SignalExceptionBadAddr(AdES, vAddr64)
    else
    {
      let pAddr  = TLBTranslate(vAddr64, StoreData);
      let rs_val = rGPR(rs);
      match width
      {
        B  => MEMw_wrapper(pAddr, 1) = rs_val[7..0],
        H  => MEMw_wrapper(pAddr, 2) = rs_val[15..0],
        W  => MEMw_wrapper(pAddr, 4) = rs_val[31..0],
        D  => MEMw_wrapper(pAddr, 8) = rs_val
      };
      true
    }
  }
}

union clause ast = CStoreConditional : (regbits, regbits, regbits, WordType)
function clause execute (CStoreConditional(rs, cb, rd, width)) =
{
  checkCP2usable();
  let cb_val = readCapRegDDC(cb);
  if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else if not (cb_val.permit_store) then
    raise_c2_exception(CapEx_PermitStoreViolation, cb)
  else
  {
    let size    = wordWidthBytes(width);
    let vAddr   = getCapCursor(cb_val);
    let vAddr64 = to_bits(64, vAddr);
    if (vAddr + size) > getCapTop(cb_val) then
      raise_c2_exception(CapEx_LengthViolation, cb)
    else if vAddr < getCapBase(cb_val) then
      raise_c2_exception(CapEx_LengthViolation, cb)
    else if not (isAddressAligned(vAddr64, width)) then
      SignalExceptionBadAddr(AdES, vAddr64)
    else
    {
      let pAddr  = TLBTranslate(vAddr64, StoreData);
      let rs_val = rGPR(rs);
      let success : bool = if (CP0LLBit[0]) then
          match width
          {
            B  => MEMw_conditional_wrapper(pAddr, 1, rs_val[7..0]),
            H  => MEMw_conditional_wrapper(pAddr, 2, rs_val[15..0]),
            W  => MEMw_conditional_wrapper(pAddr, 4, rs_val[31..0]),
            D  => MEMw_conditional_wrapper(pAddr, 8, rs_val)
          }
        else
          false;
      wGPR(rd) = zero_extend(success);
      true
    }
  }
}

union clause ast = CSC : (regbits, regbits, regbits, bits(11))
function clause execute (CSC(cs, cb, rt, offset)) =
{
  checkCP2usable();
  let cs_val = readCapReg(cs);
  let cb_val = readCapRegDDC(cb);
  if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else if not (cb_val.permit_store) then
    raise_c2_exception(CapEx_PermitStoreViolation, cb)
  else if not (cb_val.permit_store_cap) then
    raise_c2_exception(CapEx_PermitStoreCapViolation, cb)
  else if not (cb_val.permit_store_local_cap) & (cs_val.tag) & not (cs_val.global) then
    raise_c2_exception(CapEx_PermitStoreLocalCapViolation, cb)
  else
  {
    let cursor  = getCapCursor(cb_val);
    let vAddr   = (cursor + unsigned(rGPR(rt)) + 16 * signed(offset)) % pow2(64);
    let vAddr64 = to_bits(64, vAddr);
    if (vAddr + cap_size) > getCapTop(cb_val) then
      raise_c2_exception(CapEx_LengthViolation, cb)
    else if vAddr < getCapBase(cb_val) then
      raise_c2_exception(CapEx_LengthViolation, cb)
    else if (vAddr % cap_size) != 0 then
      SignalExceptionBadAddr(AdES, vAddr64)
    else
    {
      let (pAddr, noStoreCap) = TLBTranslateC(vAddr64, StoreData);
      if cs_val.tag & noStoreCap then
        raise_c2_exception(CapEx_TLBNoStoreCap, cs)
      else {
        MEMw_tagged(pAddr, cs_val.tag, capToMemBits(cs_val));
        true
      }
    }
  }
}

union clause ast = CSCC : (regbits, regbits, regbits)
function clause execute (CSCC(cs, cb, rd)) =
{
  checkCP2usable();
  let cs_val = readCapReg(cs);
  let cb_val = readCapRegDDC(cb);
  if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else if not (cb_val.permit_store) then
    raise_c2_exception(CapEx_PermitStoreViolation, cb)
  else if not (cb_val.permit_store_cap) then
    raise_c2_exception(CapEx_PermitStoreCapViolation, cb)
  else if not (cb_val.permit_store_local_cap) & (cs_val.tag) & not (cs_val.global) then
    raise_c2_exception(CapEx_PermitStoreLocalCapViolation, cb)
  else
  {
    let vAddr   = getCapCursor(cb_val);
    let vAddr64 = to_bits(64, vAddr);
    if (vAddr + cap_size) > getCapTop(cb_val) then
      raise_c2_exception(CapEx_LengthViolation, cb)
    else if vAddr < getCapBase(cb_val) then
      raise_c2_exception(CapEx_LengthViolation, cb)
    else if (vAddr % cap_size) != 0 then
      SignalExceptionBadAddr(AdES, vAddr64)
    else
    {
      let (pAddr, noStoreCap) = TLBTranslateC(vAddr64, StoreData);
      if cs_val.tag & noStoreCap then
        raise_c2_exception(CapEx_TLBNoStoreCap, cs)
      else
      {
        let success = if (CP0LLBit[0]) then
            MEMw_tagged_conditional(pAddr, cs_val.tag, capToMemBits(cs_val))
          else
            false;
        wGPR(rd) = zero_extend(success);
        true
      }
    }
  }
}

union clause ast = CLC : (regbits, regbits, regbits, bits(11))
function clause execute (CLC(cd, cb, rt, offset)) =  
{
  checkCP2usable();
  let cb_val = readCapRegDDC(cb);
  if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else if not (cb_val.permit_load) then
    raise_c2_exception(CapEx_PermitLoadViolation, cb)
  else
  {
    let cursor  = getCapCursor(cb_val);
    let vAddr   = (cursor + unsigned(rGPR(rt)) + 16 * signed(offset)) % pow2(64);
    let vAddr64 = to_bits(64, vAddr);
    if (vAddr + cap_size) > getCapTop(cb_val) then
      raise_c2_exception(CapEx_LengthViolation, cb)
    else if vAddr < getCapBase(cb_val) then
      raise_c2_exception(CapEx_LengthViolation, cb)
    else if (vAddr % cap_size) != 0 then
      SignalExceptionBadAddr(AdEL, vAddr64)
    else
    {
      let (pAddr, suppressTag) = TLBTranslateC(vAddr64, LoadData);
      let (tag, mem) = MEMr_tagged(pAddr);
      let cap = memBitsToCapability(tag & cb_val.permit_load_cap & not (suppressTag), mem);
      writeCapReg(cd, cap);
      true
    }
  }
}

union clause ast = CLCBI : (regbits, regbits, bits(16))
function clause execute (CLCBI(cd, cb, offset)) =  
{
  checkCP2usable();
  let cb_val = readCapRegDDC(cb);
  if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else if not (cb_val.permit_load) then
    raise_c2_exception(CapEx_PermitLoadViolation, cb)
  else
  {
    let cursor  = getCapCursor(cb_val);
    let vAddr   = (cursor + 16 * signed(offset)) % pow2(64);
    let vAddr64 = to_bits(64, vAddr);
    if (vAddr + cap_size) > getCapTop(cb_val) then
      raise_c2_exception(CapEx_LengthViolation, cb)
    else if vAddr < getCapBase(cb_val) then
      raise_c2_exception(CapEx_LengthViolation, cb)
    else if (vAddr % cap_size) != 0 then
      SignalExceptionBadAddr(AdEL, vAddr64)
    else
    {
      let (pAddr, suppressTag) = TLBTranslateC(vAddr64, LoadData);
      let (tag, mem) = MEMr_tagged(pAddr);
      let cap = memBitsToCapability(tag & cb_val.permit_load_cap & not (suppressTag), mem);
      writeCapReg(cd, cap);
      true
    }
  }
}

union clause ast = CLLC : (regbits, regbits)
function clause execute (CLLC(cd, cb)) =  
{
  checkCP2usable();
  let cb_val = readCapRegDDC(cb);
  if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else if not (cb_val.permit_load) then
    raise_c2_exception(CapEx_PermitLoadViolation, cb)
  else
  {
    let vAddr   = getCapCursor(cb_val);
    let vAddr64 = to_bits(64, vAddr);
    if (vAddr + cap_size) > getCapTop(cb_val) then
      raise_c2_exception(CapEx_LengthViolation, cb)
    else if vAddr < getCapBase(cb_val) then
      raise_c2_exception(CapEx_LengthViolation, cb)
    else if (vAddr % cap_size) != 0 then
      SignalExceptionBadAddr(AdEL, vAddr64)
    else
    {
      let (pAddr, suppressTag) = TLBTranslateC(vAddr64, LoadData);
      let (tag, mem) : (bool, CapBits) = MEMr_tagged_reserve(pAddr);
      let cap = memBitsToCapability(tag & cb_val.permit_load_cap & not (suppressTag), mem);
      writeCapReg(cd, cap);
      CP0LLBit  = 0b1;
      CP0LLAddr = pAddr;
      true
    }
  }
}
*/


/* 
NB: Must be careful about order of matching because unused register
fields are re-used as additional function codes: more specific matches
must come before more general ones. In our case that means two-arg
instructions (that have 0x7f in func7 field) must come before
three-arg ones.
*/

/* Two arg */

mapping clause encdec = CGetPerm(rd, cb)   <-> 0b1111111 @ 0b00000 @ cb @ 0b000 @ rd @ 0b1011011
mapping clause encdec = CGetType(rd, cb)   <-> 0b1111111 @ 0b00001 @ cb @ 0b000 @ rd @ 0b1011011
mapping clause encdec = CGetBase(rd, cb)   <-> 0b1111111 @ 0b00010 @ cb @ 0b000 @ rd @ 0b1011011
mapping clause encdec = CGetLen(rd, cb)    <-> 0b1111111 @ 0b00011 @ cb @ 0b000 @ rd @ 0b1011011
mapping clause encdec = CGetTag(rd, cb)    <-> 0b1111111 @ 0b00100 @ cb @ 0b000 @ rd @ 0b1011011
mapping clause encdec = CGetSealed(rd, cb) <-> 0b1111111 @ 0b00101 @ cb @ 0b000 @ rd @ 0b1011011
mapping clause encdec = CGetOffset(rd, cb) <-> 0b1111111 @ 0b00110 @ cb @ 0b000 @ rd @ 0b1011011
mapping clause encdec = CGetAddr(rd, cb)   <-> 0b1111111 @ 0b01111 @ cb @ 0b000 @ rd @ 0b1011011

mapping clause encdec = CMove(cd, cs)      <-> 0b1111111 @ 0b01010 @ cs @ 0b000 @ cd @ 0b1011011
mapping clause encdec = CClearTag(cd, cs)  <-> 0b1111111 @ 0b01011 @ cs @ 0b000 @ cd @ 0b1011011
mapping clause encdec = CJALR(cd, cb)      <-> 0b1111111 @ 0b01100 @ cb @ 0b000 @ cd @ 0b1011011

mapping clause encdec = CCheckPerm(cs, rt) <-> 0b1111111 @ 0b01000 @ rt @ 0b000 @ cs @ 0b1011011
mapping clause encdec = CCheckType(cs, cb) <-> 0b1111111 @ 0b01001 @ cb @ 0b000 @ cs @ 0b1011011

mapping clause encdec = ClearRegs(GPRegs, q, m3 @ m5) <-> 0b1111111 @ 0b01101 @ q : bits(2) @ m3 : bits(3) @ 0b000 @ m5 : regbits @ 0b1011011
mapping clause encdec = ClearRegs(FPRegs, q, m3 @ m5) <-> 0b1111111 @ 0b10000 @ q : bits(2) @ m3 : bits(3) @ 0b000 @ m5 : regbits @ 0b1011011

mapping clause assembly = CGetPerm(rd, cb)   <-> "CGetPerm"   ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(cb)
mapping clause assembly = CGetType(rd, cb)   <-> "CGetType"   ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(cb)
mapping clause assembly = CGetBase(rd, cb)   <-> "CGetBase"   ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(cb)
mapping clause assembly = CGetLen(rd, cb)    <-> "CGetLen"    ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(cb)
mapping clause assembly = CGetTag(rd, cb)    <-> "CGetTag"    ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(cb)
mapping clause assembly = CGetSealed(rd, cb) <-> "CGetSealed" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(cb)
mapping clause assembly = CGetOffset(rd, cb) <-> "CGetOffset" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(cb)
mapping clause assembly = CGetAddr(rd, cb)   <-> "CGetAddr"   ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(cb)

mapping clause assembly = CMove(cd, cs)      <-> "CMove"      ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cs)
mapping clause assembly = CClearTag(cd, cs)  <-> "CClearTag"  ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cs)
mapping clause assembly = CJALR(0b00000, cb) <-> "CJR"        ^ spc() ^ reg_name(cb)
mapping clause assembly = CJALR(cd, cb)      <-> "CJALR"      ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cb)

mapping clause assembly = CCheckPerm(cs, rt) <-> "CCheckPerm" ^ spc() ^ reg_name(cs) ^ sep() ^ reg_name(rt)
mapping clause assembly = CCheckType(cs, cb) <-> "CCheckType" ^ spc() ^ reg_name(cs) ^ sep() ^ reg_name(cb)

mapping clause assembly = ClearRegs(GPRegs, q, m8) <-> "Clearq"   ^ spc() ^ hex_bits_2(q) ^ sep() ^ hex_bits_8(m8)
mapping clause assembly = ClearRegs(FPRegs, q, m8) <-> "FPClearq" ^ spc() ^ hex_bits_2(q) ^ sep() ^ hex_bits_8(m8)

/* Three arg */

mapping clause encdec = CSeal(cd, cs, ct)      <-> 0b0001011 @ ct @ cs @ 0b000 @ cd @ 0b1011011
mapping clause encdec = CUnseal(cd, cs, ct)    <-> 0b0001100 @ ct @ cs @ 0b000 @ cd @ 0b1011011
mapping clause encdec = CAndPerm(cd, cs, rt)   <-> 0b0001101 @ rt @ cs @ 0b000 @ cd @ 0b1011011
mapping clause encdec = CSetOffset(cd, cs, rt) <-> 0b0001111 @ rt @ cs @ 0b000 @ cd @ 0b1011011
mapping clause encdec = CIncOffset(cd, cs, rt) <-> 0b0010001 @ rt @ cs @ 0b000 @ cd @ 0b1011011
mapping clause encdec = CSetBounds(cd, cs, rt) <-> 0b0001000 @ rt @ cs @ 0b000 @ cd @ 0b1011011
mapping clause encdec = CSetBoundsExact(cd, cs, rt) <-> 0b0001001 @ rt @ cs @ 0b000 @ cd @ 0b1011011
mapping clause encdec = CBuildCap(cd, cb, ct) <-> 0b0011101 @ ct @ cb @ 0b000 @ cd @ 0b1011011
mapping clause encdec = CCopyType(cd, cb, ct) <-> 0b0011110 @ ct @ cb @ 0b000 @ cd @ 0b1011011
mapping clause encdec = CCSeal(cd, cs, ct)    <-> 0b0011111 @ ct @ cs @ 0b000 @ cd @ 0b1011011

mapping clause encdec = CToPtr(rd, cb, cs)    <-> 0b0010010 @ cs @ cb @ 0b000 @ rd @ 0b1011011
mapping clause encdec = CFromPtr(cd, cb, rs)  <-> 0b0010011 @ rs @ cb @ 0b000 @ cd @ 0b1011011
mapping clause encdec = CCall(cs, cb, 0b00000) <-> 0b1111110 @ 0b00000 @ cb @ 0b000 @ cs @ 0b1011011 /* CCall */
mapping clause encdec = CCall(cs, cb, 0b00001) <-> 0b1111110 @ 0b00001 @ cb @ 0b000 @ cs @ 0b1011011 /* CCallFast */
mapping clause encdec = CCall(cs, cb, 0b11111) <-> 0b1111110 @ 0b11111 @ cb @ 0b000 @ cs @ 0b1011011 /* CReturn */

mapping clause encdec = CTestSubset(rd, cb, ct) <-> 0b0100000 @ ct @ cb @ 0b000 @ rd @ 0b1011011
mapping clause encdec = CSpecialRW(cd, cs, idx) <-> 0b0000001 @ idx @ cs @ 0b000 @ cd @ 0b1011011

mapping clause encdec = CIncOffsetImmediate(cd, cb, imm12) <-> imm12 : bits(12) @ cb @ 0b001 @ cd @ 0b1011011
mapping clause encdec = CSetBoundsImmediate(cd, cb, imm12) <-> imm12 : bits(12) @ cb @ 0b010 @ cd @ 0b1011011

mapping clause assembly = CSeal(cd, cs, ct)      <-> "CSeal"      ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cs) ^ sep() ^ reg_name(ct)
mapping clause assembly = CUnseal(cd, cs, ct)    <-> "CUnseal"    ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cs) ^ sep() ^ reg_name(ct)
mapping clause assembly = CAndPerm(cd, cs, rt)   <-> "CAndPerm"   ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cs) ^ sep() ^ reg_name(rt)
mapping clause assembly = CSetOffset(cd, cs, rt) <-> "CSetOffset" ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cs) ^ sep() ^ reg_name(rt)
mapping clause assembly = CIncOffset(cd, cs, rt) <-> "CIncOffset" ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cs) ^ sep() ^ reg_name(rt)
mapping clause assembly = CSetBounds(cd, cs, rt) <-> "CSetBounds" ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cs) ^ sep() ^ reg_name(rt)
mapping clause assembly = CSetBoundsExact(cd, cs, rt) <-> "CSetBoundsExact" ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cs) ^ sep() ^ reg_name(rt)
mapping clause assembly = CBuildCap(cd, cb, ct) <-> "CBuildCap"   ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cb) ^ sep() ^ reg_name(ct)
mapping clause assembly = CCopyType(cd, cb, ct) <-> "CCopyType"   ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cb) ^ sep() ^ reg_name(ct)
mapping clause assembly = CCSeal(cd, cs, ct)    <-> "CCSeal"      ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cs) ^ sep() ^ reg_name(ct)

mapping clause assembly = CToPtr(rd, cb, cs)    <-> "CToPtr"      ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(cb) ^ sep() ^ reg_name(cs)
mapping clause assembly = CFromPtr(cd, cb, rs)  <-> "CFromPtr"    ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cb) ^ sep() ^ reg_name(rs)
mapping clause assembly = CCall(cs, cb, 0b00000) <-> "CCall"      ^ spc() ^ reg_name(cs) ^ sep() ^ reg_name(cb)
mapping clause assembly = CCall(cs, cb, 0b00001) <-> "CCallFast"  ^ spc() ^ reg_name(cs) ^ sep() ^ reg_name(cb)
mapping clause assembly = CCall(cs, cb, 0b11111) <-> "CCallReturn" ^ spc() ^ reg_name(cs) ^ sep() ^ reg_name(cb)

mapping clause assembly = CTestSubset(rd, cb, ct) <-> "CTestSubset" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(cb) ^ sep() ^ reg_name(ct)
mapping clause assembly = CSpecialRW(cd, cs, idx) <-> "CSpecialRW"  ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cs) ^ sep() ^ reg_name(idx)

mapping clause assembly = CIncOffsetImmediate(cd, cb, imm12) <-> "CIncOffsetImmediate" ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cb) ^ sep() ^ hex_bits_12(imm12)
mapping clause assembly = CSetBoundsImmediate(cd, cb, imm12) <-> "CSetBoundsImmediate" ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cb) ^ sep() ^ hex_bits_12(imm12)

/* Loads and stores */

mapping clause encdec = CLoadDDC(rd, rs, false, BYTE)   <-> 0b0000000 @ 0b00000 @ rs @ 0b000 @ rd @ 0b1011011  /* lbddc */
mapping clause encdec = CLoadDDC(rd, rs, false, HALF)   <-> 0b0000000 @ 0b00001 @ rs @ 0b000 @ rd @ 0b1011011  /* lhddc */
mapping clause encdec = CLoadDDC(rd, rs, false, WORD)   <-> 0b0000000 @ 0b00010 @ rs @ 0b000 @ rd @ 0b1011011  /* lwddc */
mapping clause encdec = CLoadDDC(rd, rs, false, DOUBLE) <-> 0b0000000 @ 0b00011 @ rs @ 0b000 @ rd @ 0b1011011  /* ldddc */
mapping clause encdec = CLoadDDC(rd, rs, true, BYTE)    <-> 0b0000000 @ 0b00100 @ rs @ 0b000 @ rd @ 0b1011011  /* lbuddc */
mapping clause encdec = CLoadDDC(rd, rs, true, HALF)    <-> 0b0000000 @ 0b00101 @ rs @ 0b000 @ rd @ 0b1011011  /* lhuddc */
mapping clause encdec = CLoadDDC(rd, rs, true, WORD)    <-> 0b0000000 @ 0b00110 @ rs @ 0b000 @ rd @ 0b1011011  /* lwuddc */
mapping clause encdec = CLoadDDC(rd, rs, true, DOUBLE)  <-> 0b0000000 @ 0b00111 @ rs @ 0b000 @ rd @ 0b1011011  /* lduddc */
mapping clause encdec = CStoreDDC(rd, rs, BYTE)         <-> 0b0000000 @ 0b01000 @ rs @ 0b000 @ rd @ 0b1011011  /* sbddc */
mapping clause encdec = CStoreDDC(rd, rs, HALF)         <-> 0b0000000 @ 0b01001 @ rs @ 0b000 @ rd @ 0b1011011  /* shddc */
mapping clause encdec = CStoreDDC(rd, rs, WORD)         <-> 0b0000000 @ 0b01010 @ rs @ 0b000 @ rd @ 0b1011011  /* swddc */
mapping clause encdec = CStoreDDC(rd, rs, DOUBLE)       <-> 0b0000000 @ 0b01011 @ rs @ 0b000 @ rd @ 0b1011011  /* sdddc */
mapping clause encdec = CStoreCapDDC(rd, rs)            <-> 0b0000000 @ 0b01100 @ rs @ 0b000 @ rd @ 0b1011011  /* sqddc */
mapping clause encdec = CLoadCapDDC(rd, rs)             <-> 0b0000000 @ 0b01101 @ rs @ 0b000 @ rd @ 0b1011011  /* lqddc */

/* Load / store data via cap, cs */
mapping clause encdec = CLoadCap(rd, cs, false, BYTE)   <-> 0b0000000 @ 0b10000 @ cs @ 0b000 @ rd @ 0b1011011  /* lbcap */
mapping clause encdec = CLoadCap(rd, cs, false, HALF)   <-> 0b0000000 @ 0b10001 @ cs @ 0b000 @ rd @ 0b1011011  /* lhcap */
mapping clause encdec = CLoadCap(rd, cs, false, WORD)   <-> 0b0000000 @ 0b10010 @ cs @ 0b000 @ rd @ 0b1011011  /* lwcap */
mapping clause encdec = CLoadCap(rd, cs, false, DOUBLE) <-> 0b0000000 @ 0b10011 @ cs @ 0b000 @ rd @ 0b1011011  /* ldcap */
mapping clause encdec = CLoadCap(rd, cs, true, BYTE)    <-> 0b0000000 @ 0b10100 @ cs @ 0b000 @ rd @ 0b1011011  /* lbucap */
mapping clause encdec = CLoadCap(rd, cs, true, HALF)    <-> 0b0000000 @ 0b10101 @ cs @ 0b000 @ rd @ 0b1011011  /* lhucap */
mapping clause encdec = CLoadCap(rd, cs, true, WORD)    <-> 0b0000000 @ 0b10110 @ cs @ 0b000 @ rd @ 0b1011011  /* lwucap */
mapping clause encdec = CLoadCap(rd, cs, true, DOUBLE)  <-> 0b0000000 @ 0b10111 @ cs @ 0b000 @ rd @ 0b1011011  /* lducap */
mapping clause encdec = CStoreCap(rd, cs, BYTE)         <-> 0b0000000 @ 0b11000 @ cs @ 0b000 @ rd @ 0b1011011  /* sbcap */
mapping clause encdec = CStoreCap(rd, cs, HALF)         <-> 0b0000000 @ 0b11001 @ cs @ 0b000 @ rd @ 0b1011011  /* shcap */
mapping clause encdec = CStoreCap(rd, cs, WORD)         <-> 0b0000000 @ 0b11010 @ cs @ 0b000 @ rd @ 0b1011011  /* swcap */
mapping clause encdec = CStoreCap(rd, cs, DOUBLE)       <-> 0b0000000 @ 0b11011 @ cs @ 0b000 @ rd @ 0b1011011  /* sdcap */
mapping clause encdec = CStoreCapCap(rd, cs)            <-> 0b0000000 @ 0b11100 @ cs @ 0b000 @ rd @ 0b1011011  /* sqcap */
mapping clause encdec = CLoadCapCap(rd, cs)             <-> 0b0000000 @ 0b11101 @ cs @ 0b000 @ rd @ 0b1011011  /* lqcap */

mapping clause assembly = CLoadDDC(rd, rs, u, w) <-> "l" ^ size_mnemonic(w) ^ maybe_u(u) ^ "DDC" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs)
mapping clause assembly = CLoadCap(rd, cs, u, w) <-> "l" ^ size_mnemonic(w) ^ maybe_u(u) ^ "Cap" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(cs)
mapping clause assembly = CStoreDDC(rd, rs, w)   <-> "s" ^ size_mnemonic(w) ^ "DDC" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs)
mapping clause assembly = CStoreCap(rd, rs, w)   <-> "s" ^ size_mnemonic(w) ^ "Cap" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs)
mapping clause assembly = CStoreCapDDC(rd, rs)   <-> "lqDDC" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs)
mapping clause assembly = CLoadCapDDC(rd, rs)    <-> "sqDDC" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs)
mapping clause assembly = CStoreCapCap(rd, rs)   <-> "lqCap" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs)
mapping clause assembly = CLoadCapCap(rd, rs)    <-> "sqCap" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs)

/*

function clause decode (0b010010 @ 0b10000 @ rd : regbits @ cb : regbits @ 0b00000001 @ 0b0 @ 0b00) = Some(CLoadLinked(rd, cb, false, B)) /* CLLBU */
function clause decode (0b010010 @ 0b10000 @ rd : regbits @ cb : regbits @ 0b00000001 @ 0b1 @ 0b00) = Some(CLoadLinked(rd, cb, true,  B)) /* CLLB  */
function clause decode (0b010010 @ 0b10000 @ rd : regbits @ cb : regbits @ 0b00000001 @ 0b0 @ 0b01) = Some(CLoadLinked(rd, cb, false, H)) /* CLLHU */
function clause decode (0b010010 @ 0b10000 @ rd : regbits @ cb : regbits @ 0b00000001 @ 0b1 @ 0b01) = Some(CLoadLinked(rd, cb, true,  H)) /* CLLH  */
function clause decode (0b010010 @ 0b10000 @ rd : regbits @ cb : regbits @ 0b00000001 @ 0b0 @ 0b10) = Some(CLoadLinked(rd, cb, false, W)) /* CLLWU */
function clause decode (0b010010 @ 0b10000 @ rd : regbits @ cb : regbits @ 0b00000001 @ 0b1 @ 0b10) = Some(CLoadLinked(rd, cb, true,  W)) /* CLLW  */
function clause decode (0b010010 @ 0b10000 @ rd : regbits @ cb : regbits @ 0b00000001 @ 0b0 @ 0b11) = Some(CLoadLinked(rd, cb, false, D)) /* CLLD  */

function clause decode (0b111010 @ rs : regbits @ cb : regbits@ rt : regbits @ offset : bits(8) @ 0b0 @ 0b00) = Some(CStore(rs, cb, rt, offset, B)) /* CSB */
function clause decode (0b111010 @ rs : regbits @ cb : regbits@ rt : regbits @ offset : bits(8) @ 0b0 @ 0b01) = Some(CStore(rs, cb, rt, offset, H)) /* CSH */
function clause decode (0b111010 @ rs : regbits @ cb : regbits@ rt : regbits @ offset : bits(8) @ 0b0 @ 0b10) = Some(CStore(rs, cb, rt, offset, W)) /* CSW */
function clause decode (0b111010 @ rs : regbits @ cb : regbits@ rt : regbits @ offset : bits(8) @ 0b0 @ 0b11) = Some(CStore(rs, cb, rt, offset, D)) /* CSD */

function clause decode (0b010010 @ 0b10000 @ rs : regbits @ cb : regbits @ rd : regbits @ 0b0000 @ 0b00) = Some(CStoreConditional(rs, cb, rd, B)) /* CSCB */
function clause decode (0b010010 @ 0b10000 @ rs : regbits @ cb : regbits @ rd : regbits @ 0b0000 @ 0b01) = Some(CStoreConditional(rs, cb, rd, H)) /* CSCH */
function clause decode (0b010010 @ 0b10000 @ rs : regbits @ cb : regbits @ rd : regbits @ 0b0000 @ 0b10) = Some(CStoreConditional(rs, cb, rd, W)) /* CSCW */
function clause decode (0b010010 @ 0b10000 @ rs : regbits @ cb : regbits @ rd : regbits @ 0b0000 @ 0b11) = Some(CStoreConditional(rs, cb, rd, D)) /* CSCD */

function clause decode (0b111110 @ cs : regbits @ cb : regbits@ rt : regbits @ offset : bits(11)) = Some(CSC(cs, cb, rt, offset))
function clause decode (0b010010 @ 0b10000 @ cs : regbits @ cb : regbits@ rd : regbits @ 0b00 @ 0b0111) = Some(CSCC(cs, cb, rd))

function clause decode (0b110110 @ cd : regbits @ cb : regbits @ rt : regbits @ offset : bits(11)) = Some(CLC(cd, cb, rt, offset))
function clause decode (0b010010 @ 0b10000 @ cd : regbits @ cb : regbits@ 0b0000000 @ 0b1111) = Some(CLLC(cd, cb))
function clause decode (0b011101 @ cd : regbits @ cb : regbits @ offset : bits(16)) = Some(CLCBI(cd, cb, offset))

*/
