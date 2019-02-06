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

/* Operations that extract parts of a capability into GPR */

union clause ast = CGetPerm   : (regno, regno)
union clause ast = CGetType   : (regno, regno)
union clause ast = CGetBase   : (regno, regno)
union clause ast = CGetLen    : (regno, regno)
union clause ast = CGetTag    : (regno, regno)
union clause ast = CGetSealed : (regno, regno)
union clause ast = CGetOffset : (regno, regno)
union clause ast = CGetAddr   : (regno, regno)

function clause execute (CGetPerm(rd, cb)) =
{
  checkCP2usable();
  let capVal = readCapReg(cb);
  wGPR(rd) = zero_extend(getCapPerms(capVal));
}

function clause execute (CGetType(rd, cb)) =
{
  checkCP2usable();
  let capVal = readCapReg(cb);
  wGPR(rd) = if capVal.sealed
    then zero_extend(capVal.otype)
    else 0xffffffffffffffff
}

function clause execute (CGetBase(rd, cb)) =
{
  checkCP2usable();
  let capVal = readCapReg(cb);
  wGPR(rd) = to_bits(64, getCapBase(capVal));
}

function clause execute (CGetOffset(rd, cb)) =
{
  checkCP2usable();
  let capVal = readCapReg(cb);
  wGPR(rd) = to_bits(64, getCapOffset(capVal));
}

function clause execute (CGetLen(rd, cb)) =
{
  checkCP2usable();
  let capVal = readCapReg(cb);
  let len65  = getCapLength(capVal);
  wGPR(rd) = to_bits(64, if len65 > MAX_U64 then MAX_U64 else len65);
}

function clause execute (CGetTag(rd, cb)) =
{
  checkCP2usable();
  let capVal = readCapReg(cb);
  wGPR(rd) = zero_extend(capVal.tag);
}

function clause execute (CGetSealed(rd, cb)) =
{
  checkCP2usable();
  let capVal = readCapReg(cb);
  wGPR(rd) = zero_extend(capVal.sealed);
}

function clause execute (CGetAddr(rd, cb)) =
{
  checkCP2usable();
  let capVal = readCapReg(cb);
  wGPR(rd) = to_bits(64, getCapCursor(capVal));
}

union clause ast = CGetPCC : regno
function clause execute (CGetPCC(cd)) =
{
  checkCP2usable();
  let (success, pcc) = setCapOffset(PCC, PC);
  assert (success, "PCC with offset PC should always be representable");
  writeCapReg(cd, pcc);
}


union clause ast = CGetPCCSetOffset : (regno, regno)
function clause execute (CGetPCCSetOffset(cd, rs)) =
{
  checkCP2usable();
  let rs_val = rGPR(rs);
  let (success, newPCC) = setCapOffset(PCC, rs_val);
  if (success) then
    writeCapReg(cd, newPCC)
  else
    writeCapReg(cd, int_to_cap(rs_val));
}
/* Get and Set CP2 cause register */

union clause ast = CGetCause : regno
function clause execute (CGetCause(rd)) = 
{
  checkCP2usable();
  if not (pcc_access_system_regs ()) then
    raise_c2_exception_noreg(CapEx_AccessSystemRegsViolation)
  else
    wGPR(rd) = zero_extend(CapCause.bits())
}

union clause ast = CSetCause : regno
function clause execute (CSetCause(rt)) = 
{
  checkCP2usable();
  if not (pcc_access_system_regs ()) then
    raise_c2_exception_noreg(CapEx_AccessSystemRegsViolation)
  else
  {
    let rt_val = rGPR(rt);
    CapCause->ExcCode() = rt_val[15..8];
    CapCause->RegNum()  = rt_val[7..0];
  }
}

union clause ast = CGetCID : regno
function clause execute (CGetCID(rd)) = 
{
  checkCP2usable();
  wGPR(rd) = CID;
}

union clause ast = CSetCID : regno
function clause execute (CSetCID(cb)) = 
{
  checkCP2usable();
  let cb_val = readCapReg(cb);
  if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else if not (cb_val.permit_set_CID) then
    raise_c2_exception(CapEx_PermitSetCIDViolation, cb)
  else
  {
    let addr = getCapCursor(cb_val);
    if addr < getCapBase(cb_val) then
      raise_c2_exception(CapEx_LengthViolation, cb)
    else if addr >= getCapTop(cb_val) then
      raise_c2_exception(CapEx_LengthViolation, cb)
    else
      CID = to_bits(64, addr);
  }
}

union clause ast = CReadHwr : (regno, regno)
function clause execute (CReadHwr(cd, sel)) = 
{
  checkCP2usable();
  let (needSup, needAccessSys) : (bool, bool) = match unsigned(sel) {
    0  => (false, false), /* DDC   -- no access control */
    1  => (false, false), /* CULR -- no access control */
    8  => (false, true),  /* CPLR -- privileged TLS */
    22 => (true, false),  /* KR1C */
    23 => (true, false),  /* KR2C */
    28 => (true, true),   /* ErrorEPCC */
    29 => (true, true),   /* KCC */
    30 => (true, true),   /* KDC */
    31 => (true, true),   /* EPCC */
    _  => SignalException(ResI)
  };
  if needAccessSys & not(pcc_access_system_regs()) then
     raise_c2_exception(CapEx_AccessSystemRegsViolation, sel)
  else if needSup & not(grantsAccess(getAccessLevel(), Supervisor)) then
     raise_c2_exception(CapEx_AccessSystemRegsViolation, sel)
  else {
    let capVal : Capability = match unsigned(sel) {
      0  => DDC,
      1  => CULR,
      8  => CPLR,
      22 => KR1C,
      23 => KR2C,
      28 => ErrorEPCC,
      29 => KCC,
      30 => KDC,
      31 => EPCC,
      _  => {assert(false, "CReadHwr: should be unreachable code"); undefined}
    };
    writeCapReg(cd, capVal);
  };
}

union clause ast = CWriteHwr : (regno, regno)
function clause execute (CWriteHwr(cb, sel)) = 
{
  checkCP2usable();
  let (needSup, needAccessSys) : (bool, bool) = match unsigned(sel) {
    0  => (false, false), /* DDC   -- no access control */
    1  => (false, false), /* CULR -- no access control */
    8  => (false, true),  /* CPLR -- privileged TLS */
    22 => (true, false),  /* KR1C */
    23 => (true, false),  /* KR2C */
    28 => (true, true),   /* ErrorEPCC */
    29 => (true, true),   /* KCC */
    30 => (true, true),   /* KDC */
    31 => (true, true),   /* EPCC */
    _  => SignalException(ResI)
  };
  if needAccessSys & not(pcc_access_system_regs()) then
     raise_c2_exception(CapEx_AccessSystemRegsViolation, sel)
  else if needSup & not(grantsAccess(getAccessLevel(), Supervisor)) then
     raise_c2_exception(CapEx_AccessSystemRegsViolation, sel)
  else {
    let capVal = readCapReg(cb);
    match unsigned(sel) {
      0  => DDC  = capVal,
      1  => CULR = capVal,
      8  => CPLR = capVal,
      22 => KR1C = capVal,
      23 => KR2C = capVal,
      28 => ErrorEPCC = capVal,
      29 => KCC  = capVal,
      30 => KDC  = capVal,
      31 => EPCC = capVal,
      _  => assert(false, "CWriteHwr: should be unreachable code")
    };
  };
}

union clause ast = CAndPerm : (regno, regno, regno)
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
  }
}



union clause ast = CToPtr : (regno, regno, regno)
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
        to_bits(64, getCapCursor(cb_val) - ctBase)
  }
}



union clause ast = CSub : (regno, regno, regno)
function clause execute(CSub(rd, cb, ct)) = 
{
  checkCP2usable();
  let ct_val = readCapReg(ct);
  let cb_val = readCapReg(cb);
  wGPR(rd) = to_bits(64, getCapCursor(cb_val) - getCapCursor(ct_val))
}

union clause ast = CPtrCmp : (regno, regno, regno, CPtrCmpOp)
function clause execute(CPtrCmp(rd, cb, ct, op)) = 
{
  checkCP2usable();
  let cb_val = readCapReg(cb);
  let ct_val = readCapReg(ct);
  equal  = false;
  ltu    = false;
  lts    = false;
  if cb_val.tag != ct_val.tag then
    {
      if not (cb_val.tag) then
        {
          ltu = true;
          lts = true;
        }
    }
  else
    {
      cursor1 = getCapCursor(cb_val);
      cursor2 = getCapCursor(ct_val);
      equal   = (cursor1 == cursor2);
      ltu     = (cursor1 < cursor2);
      lts     = to_bits(64, cursor1) <_s to_bits(64, cursor2);
    };
  let cmp : bool = match op {
    CEQ    => equal,
    CNE    => not (equal),
    CLT    => lts,
    CLE    => lts | equal,
    CLTU   => ltu,
    CLEU   => ltu | equal,
    CEXEQ  => cb_val == ct_val,
    CNEXEQ => cb_val != ct_val
  };
  wGPR(rd) = zero_extend (cmp)
}

union clause ast = CIncOffset : (regno, regno, regno)
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
        writeCapReg(cd, int_to_cap(to_bits(64, getCapBase(cb_val)) + rt_val))
  }
}

union clause ast = CIncOffsetImmediate : (regno, regno, bits(11))
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
        writeCapReg(cd, int_to_cap(to_bits(64, getCapBase(cb_val)) + imm64))
  }
}

union clause ast = CSetOffset : (regno, regno, regno)
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
        writeCapReg(cd, int_to_cap(to_bits(64, getCapBase(cb_val)) + rt_val))
  }
}

union clause ast = CSetBounds : (regno, regno, regno)
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
    writeCapReg(cd, newCap) /* ignore exact */
  }
}

union clause ast = CSetBoundsImmediate : (regno, regno, bits(11))
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
    writeCapReg(cd, newCap) /* ignore exact */
  }
}

union clause ast = CSetBoundsExact : (regno, regno, regno)
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
    else
        writeCapReg(cd, newCap)
  }
}

union clause ast = CClearTag : (regno, regno)
function clause execute (CClearTag(cd, cb)) =
{
  checkCP2usable();
  let cb_val = readCapReg(cb);
  writeCapReg(cd, {cb_val with tag=false});
}

union clause ast = CMOVX : (regno,regno,regno,bool)
function clause execute (CMOVX(cd, cb, rt, ismovn)) =
{
  checkCP2usable();
  if (rGPR(rt) == zeros()) ^ ismovn then
    writeCapReg(cd) = readCapReg(cb);
}

union clause ast = ClearRegs : (ClearRegSet, bits(16))
function clause execute (ClearRegs(regset, m)) =
{
  if ((regset == CLo) | (regset == CHi)) then
    checkCP2usable();
  foreach (i from 0 to 15)
    if (m[i]) then
      match regset {
        GPLo  => wGPR(to_bits(5, i)) = zeros(),
        GPHi  => wGPR(to_bits(5, i+16)) = zeros(),
        CLo   => if i == 0 then
                   DDC = null_cap
                 else
                   writeCapReg(to_bits(5, i)) = null_cap,
        CHi   => writeCapReg(to_bits(5, i+16)) = null_cap
      }
}

union clause ast = CFromPtr : (regno, regno, regno)
function clause execute (CFromPtr(cd, cb, rt)) =
{
  checkCP2usable();
  let cb_val = readCapRegDDC(cb);
  let rt_val = rGPR(rt);
  if rt_val == 0x0000000000000000 then
    writeCapReg(cd, null_cap)
  else if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else
  {
    let (success, newCap) = setCapOffset(cb_val, rt_val);
    if success then
        writeCapReg(cd, newCap)
    else
        writeCapReg(cd, int_to_cap(to_bits(64, getCapBase(cb_val)) + rt_val))
  }
}

union clause ast = CBuildCap : (regno, regno, regno)
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
    }
  }
}

union clause ast = CCopyType : (regno, regno, regno)
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
    }
  }
  else
    writeCapReg(cd, int_to_cap(0xffffffffffffffff))
}

union clause ast = CCheckPerm : (regno, regno)
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
}

union clause ast = CCheckType : (regno, regno)
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
}

union clause ast = CCheckTag : (regno)
function clause execute (CCheckTag (cs)) =
{
  checkCP2usable();
  let cs_val = readCapReg(cs);
  if not(cs_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cs);
}

union clause ast = CTestSubset : (regno, regno, regno)
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
}

union clause ast = CSeal : (regno, regno, regno)
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
    else
        writeCapReg(cd, newCap)
  }
}

union clause ast = CCSeal : (regno, regno, regno)
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
  else if not (ct_val.tag) | (getCapCursor(ct_val) == MAX_U64) then
    writeCapReg(cd, cs_val)
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
    else
        writeCapReg(cd, newCap)
  }
}

union clause ast = CUnseal : (regno, regno, regno)
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
  else
    writeCapReg(cd, {unsealCap(cs_val) with 
      global=(cs_val.global & ct_val.global)
    })
}

union clause ast = CCall : (regno, regno, bits(11))
function clause execute (CCall(cs, cb, 0b00000000000)) = /* selector=0 */
{
  /* Partial implementation of CCall with checks in hardware, but raising a trap to perform trusted stack manipulation */
  checkCP2usable();
  if InBranchDelay then
    SignalException(ResI);
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

function clause execute (CCall(cs, cb, 0b00000000001)) = /* selector=1 */
{
  /* Jump-like implementation of CCall that unseals arguments */
  checkCP2usable();
  if InBranchDelay then
    SignalException(ResI);
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
    set_next_pcc(unsealCap(cs_val));
    C26 = unsealCap(cb_val);
    NextPC = to_bits(64, getCapOffset(cs_val));
  }
}

union clause ast = CReturn : unit
function clause execute (CReturn()) =
{
  checkCP2usable();
  raise_c2_exception_noreg(CapEx_ReturnTrap)
}

union clause ast = CBX : (regno, bits(16), bool)
function clause execute (CBX(cb, imm, notset)) =
{
  checkCP2usable();
  if InBranchDelay then
     SignalException(ResI);
  let cb_val = readCapReg(cb);
  if cb_val.tag ^ notset then
  {
    let offset : bits(64) = sign_extend(imm @ 0b00) + 4;
    execute_branch(PC + offset);
  };
  NextInBranchDelay = 0b1;
}

union clause ast = CBZ : (regno, bits(16), bool)
function clause execute (CBZ(cb, imm, notzero)) =
{
  checkCP2usable();
  if InBranchDelay then
     SignalException(ResI);
  let cb_val = readCapReg(cb);
  if (cb_val == null_cap) ^ notzero then
  {
    let offset : bits(64) = sign_extend(imm @ 0b00) + 4;
    execute_branch(PC + offset);
  };
  NextInBranchDelay = 0b1;
}

union clause ast = CJALR : (regno, regno, bool)
function clause execute(CJALR(cd, cb, link)) = 
{
  checkCP2usable();
  if InBranchDelay then
     SignalException(ResI);
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
  else if (cb_ptr + 4) > cb_top then
    raise_c2_exception(CapEx_LengthViolation, cb)
  else if (cb_ptr % 4) != 0 then
    SignalException(AdEL)
  else
  {
    if link then
    {
      let (success, linkCap) = setCapOffset(PCC, PC+8);
      assert(success, "Link cap should always be representable.");
      writeCapReg(cd, linkCap);
    };
    execute_branch_pcc(cb_val);
  };
  NextInBranchDelay = 0b1;
}

union clause ast = CLoad : (regno, regno, regno, bits(8), bool, WordType)
function clause execute (CLoad(rd, cb, rt, offset, signext, width)) =
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
    let 'size   = wordWidthBytes(width);
    let cursor  = getCapCursor(cb_val);
    let vAddr   = (cursor + unsigned(rGPR(rt)) + size*signed(offset)) % pow2(64);
    let vAddr64 = to_bits(64, vAddr);
    if (vAddr + size) > getCapTop(cb_val) then
      raise_c2_exception(CapEx_LengthViolation, cb)
    else if vAddr < getCapBase(cb_val) then
      raise_c2_exception(CapEx_LengthViolation, cb)
    else if not (isAddressAligned(vAddr64, width)) then
      SignalExceptionBadAddr(AdEL, vAddr64)
    else
    {
      let pAddr = TLBTranslate(vAddr64, LoadData);
      memResult : bits(64) = extendLoad(MEMr_wrapper(pAddr, size), signext);
      wGPR(rd) = memResult;
    }
  }
}

union clause ast = CLoadLinked : (regno, regno, bool, WordType)
function clause execute (CLoadLinked(rd, cb, signext, width)) =
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
    let 'size   = wordWidthBytes(width);
    let vAddr   = getCapCursor(cb_val);
    let vAddr64 = to_bits(64, vAddr);
    if (vAddr + size) > getCapTop(cb_val) then
      raise_c2_exception(CapEx_LengthViolation, cb)
    else if vAddr < getCapBase(cb_val) then
      raise_c2_exception(CapEx_LengthViolation, cb)
    else if not (isAddressAligned(vAddr64, width)) then
      SignalExceptionBadAddr(AdEL, vAddr64)
    else
    {
      let pAddr = TLBTranslate(vAddr64, LoadData);
      let memResult : bits(64) = extendLoad(MEMr_reserve_wrapper(pAddr, size), signext);
      CP0LLBit  = 0b1;
      CP0LLAddr = pAddr;
      wGPR(rd) = memResult;
    }
  }
}

union clause ast = CLoadTags : (regno, regno)
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
      }
  }
}

union clause ast = CStore : (regno, regno, regno, bits(8), WordType)
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
      }
    }
  }
}

union clause ast = CStoreConditional : (regno, regno, regno, WordType)
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
    }
  }
}

union clause ast = CSC : (regno, regno, regno, bits(11))
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
      else 
        MEMw_tagged(pAddr, cs_val.tag, capToMemBits(cs_val));
    }
  }
}

union clause ast = CSCC : (regno, regno, regno)
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
      }
    }
  }
}

union clause ast = CLC : (regno, regno, regno, bits(11))
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
    }
  }
}

union clause ast = CLCBI : (regno, regno, bits(16))
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
    }
  }
}

union clause ast = CLLC : (regno, regno)
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
    }
  }
}

union clause ast = C2Dump : regno
function clause execute (C2Dump (rt)) =
    () /* Currently a NOP */

/* Old encodings */
function clause decode (0b010010 @ 0b00000 @ rd : regno @ cb : regno @ 0b00000000 @ 0b000) = Some(CGetPerm(rd, cb))
function clause decode (0b010010 @ 0b00000 @ rd : regno @ cb : regno @ 0b00000000 @ 0b001) = Some(CGetType(rd, cb))
function clause decode (0b010010 @ 0b00000 @ rd : regno @ cb : regno @ 0b00000000 @ 0b010) = Some(CGetBase(rd, cb))
function clause decode (0b010010 @ 0b00000 @ rd : regno @ cb : regno @ 0b00000000 @ 0b011) = Some(CGetLen(rd, cb))
function clause decode (0b010010 @ 0b00000 @ rd : regno @ cb : regno @ 0b00000000 @ 0b101) = Some(CGetTag(rd, cb))
function clause decode (0b010010 @ 0b00000 @ rd : regno @ cb : regno @ 0b00000000 @ 0b110) = Some(CGetSealed(rd, cb))
function clause decode (0b010010 @ 0b00000 @ rd : regno @    0b00000 @ 0b00000000 @ 0b100) = Some(CGetCause(rd))

function clause decode (0b010010 @ 0b00110 @ 0b000000000000000000000) = Some(CReturn())

function clause decode (0b010010 @ 0b01101 @ rd : regno @ cb : regno @ 0b00000000 @ 0b010) = Some(CGetOffset(rd, cb)) /* NB encoding does not follow pattern */
function clause decode (0b010010 @ 0b00100 @ 0b00000 @ 0b00000 @ rt : regno @ 0b000 @ 0b100) = Some(CSetCause(rt))
function clause decode (0b010010 @ 0b00100 @ cd : regno @ cb : regno @ rt : regno @ 0b000 @ 0b000) = Some(CAndPerm(cd, cb, rt))
function clause decode (0b010010 @ 0b01100 @ rd : regno @ cb : regno @ ct : regno @ 0b000 @ 0b000) = Some(CToPtr(rd, cb, ct))

function clause decode (0b010010 @ 0b01110 @ rd : regno @ cb : regno @ ct : regno @ 0b000 @ 0b000) = Some(CPtrCmp(rd, cb, ct, CEQ))
function clause decode (0b010010 @ 0b01110 @ rd : regno @ cb : regno @ ct : regno @ 0b000 @ 0b001) = Some(CPtrCmp(rd, cb, ct, CNE))
function clause decode (0b010010 @ 0b01110 @ rd : regno @ cb : regno @ ct : regno @ 0b000 @ 0b010) = Some(CPtrCmp(rd, cb, ct, CLT))
function clause decode (0b010010 @ 0b01110 @ rd : regno @ cb : regno @ ct : regno @ 0b000 @ 0b011) = Some(CPtrCmp(rd, cb, ct, CLE))
function clause decode (0b010010 @ 0b01110 @ rd : regno @ cb : regno @ ct : regno @ 0b000 @ 0b100) = Some(CPtrCmp(rd, cb, ct, CLTU))
function clause decode (0b010010 @ 0b01110 @ rd : regno @ cb : regno @ ct : regno @ 0b000 @ 0b101) = Some(CPtrCmp(rd, cb, ct, CLEU))
function clause decode (0b010010 @ 0b01110 @ rd : regno @ cb : regno @ ct : regno @ 0b000 @ 0b110) = Some(CPtrCmp(rd, cb, ct, CEXEQ))
function clause decode (0b010010 @ 0b01110 @ rd : regno @ cb : regno @ ct : regno @ 0b000 @ 0b111) = Some(CPtrCmp(rd, cb, ct, CNEXEQ))
function clause decode (0b010010 @ 0b01101 @ cd : regno @ cb : regno @ rt : regno @ 0b000 @ 0b000) = Some(CIncOffset(cd, cb, rt))
function clause decode (0b010010 @ 0b01101 @ cd : regno @ cb : regno @ rt : regno @ 0b000 @ 0b001) = Some(CSetOffset(cd, cb, rt))
function clause decode (0b010010 @ 0b00001 @ cd : regno @ cb : regno @ rt : regno @ 0b000000)      = Some(CSetBounds(cd, cb, rt))

function clause decode (0b010010 @ 0b00100 @ cd : regno @ cb : regno @ 0b00000 @ 0b000@ 0b101)    = Some(CClearTag(cd, cb))
function clause decode (0b010010 @ 0b00100 @ cd : regno @ cb : regno @ rt : regno @ 0b000@ 0b111) = Some(CFromPtr(cd, cb, rt))
function clause decode (0b010010 @ 0b01011 @ cs : regno @ 0b00000 @ rt : regno @ 0b000@ 0b000) = Some(CCheckPerm(cs, rt))
function clause decode (0b010010 @ 0b01011 @ cs : regno @ cb : regno @ 0b00000 @ 0b000@ 0b001) = Some(CCheckType(cs, cb))
function clause decode (0b010010 @ 0b00010 @ cd : regno @ cs : regno @ ct : regno @ 0b000@ 0b000) = Some(CSeal(cd, cs, ct))
function clause decode (0b010010 @ 0b00011 @ cd : regno @ cs : regno @ ct : regno @ 0b000@ 0b000) = Some(CUnseal(cd, cs, ct))
function clause decode (0b010010 @ 0b00111 @ cd : regno @ cb : regno @ 0b00000 @ 0b000000) = Some(CJALR(cd, cb, true)) /* CJALR */
function clause decode (0b010010 @ 0b01000 @ 0b00000    @ cb : regno @ 0b00000 @ 0b000000) = Some(CJALR(0b00000, cb, false)) /* CJR */


/* 
New encodings as per CHERI ISA Appendix B.2.  

NB: Must be careful about order of matching because unused register
fields are re-used as additional function codes.
*/

/* One arg */
function clause decode (0b010010 @ 0b00000 @ rd : regno @    0b00001 @    0b11111 @ 0b111111) = Some(CGetCause(rd))
function clause decode (0b010010 @ 0b00000 @ rs : regno @    0b00010 @    0b11111 @ 0b111111) = Some(CSetCause(rs))
function clause decode (0b010010 @ 0b00000 @ cd : regno @    0b00000 @    0b11111 @ 0b111111) = Some(CGetPCC(cd))
function clause decode (0b010010 @ 0b00000 @ cb : regno @    0b00011 @    0b11111 @ 0b111111) = Some(CJALR(0b00000, cb, false)) /* CJR */
function clause decode (0b010010 @ 0b00000 @ rd : regno @    0b00100 @    0b11111 @ 0b111111) = Some(CGetCID(rd))
function clause decode (0b010010 @ 0b00000 @ cb : regno @    0b00101 @    0b11111 @ 0b111111) = Some(CSetCID(cb))

/* Two arg */
function clause decode (0b010010 @ 0b00000 @ cs : regno @ rt : regno @    0b01000 @ 0b111111) = Some(CCheckPerm(cs, rt))
function clause decode (0b010010 @ 0b00000 @ cs : regno @ cb : regno @    0b01001 @ 0b111111) = Some(CCheckType(cs, cb))
function clause decode (0b010010 @ 0b00000 @ cd : regno @ cb : regno @    0b01011 @ 0b111111) = Some(CClearTag(cd, cb))
function clause decode (0b010010 @ 0b00000 @ cd : regno @ cs : regno @    0b01010 @ 0b111111) = Some(CMOVX(cd, cs, 0b00000, false)) /* CMOVE */
function clause decode (0b010010 @ 0b00000 @ cd : regno @ cb : regno @    0b01100 @ 0b111111) = Some(CJALR(cd, cb, true)) /* CJALR */

function clause decode (0b010010 @ 0b00000 @ rd : regno @ cb : regno @    0b11110 @ 0b111111) = Some(CLoadTags(rd, cb))

/* Capability Inspection */
function clause decode (0b010010 @ 0b00000 @ rd : regno @ cb : regno @    0b00000 @ 0b111111) = Some(CGetPerm(rd, cb))
function clause decode (0b010010 @ 0b00000 @ rd : regno @ cb : regno @    0b00001 @ 0b111111) = Some(CGetType(rd, cb))
function clause decode (0b010010 @ 0b00000 @ rd : regno @ cb : regno @    0b00010 @ 0b111111) = Some(CGetBase(rd, cb))
function clause decode (0b010010 @ 0b00000 @ rd : regno @ cb : regno @    0b00011 @ 0b111111) = Some(CGetLen(rd, cb))
function clause decode (0b010010 @ 0b00000 @ rd : regno @ cb : regno @    0b00100 @ 0b111111) = Some(CGetTag(rd, cb))
function clause decode (0b010010 @ 0b00000 @ rd : regno @ cb : regno @    0b00101 @ 0b111111) = Some(CGetSealed(rd, cb))
function clause decode (0b010010 @ 0b00000 @ rd : regno @ cb : regno @    0b00110 @ 0b111111) = Some(CGetOffset(rd, cb))
function clause decode (0b010010 @ 0b00000 @ cd : regno @ rs : regno @    0b00111 @ 0b111111) = Some(CGetPCCSetOffset(cd, rs))

function clause decode (0b010010 @ 0b00000 @ cd : regno @ sel : regno @   0b01101 @ 0b111111) = Some(CReadHwr(cd, sel))
function clause decode (0b010010 @ 0b00000 @ cb : regno @ sel : regno @   0b01110 @ 0b111111) = Some(CWriteHwr(cb, sel))

function clause decode (0b010010 @ 0b00000 @ cb : regno @ sel : regno @   0b01111 @ 0b111111) = Some(CGetAddr(cb, sel))

/* Three operand */

/* Capability Modification */
function clause decode (0b010010 @ 0b00000 @ cd : regno @ cs : regno @ ct : regno @ 0b001011) = Some(CSeal(cd, cs, ct))
function clause decode (0b010010 @ 0b00000 @ cd : regno @ cs : regno @ ct : regno @ 0b001100) = Some(CUnseal(cd, cs, ct))
function clause decode (0b010010 @ 0b00000 @ cd : regno @ cs : regno @ rt : regno @ 0b001101) = Some(CAndPerm(cd, cs, rt))
function clause decode (0b010010 @ 0b00000 @ cd : regno @ cs : regno @ rt : regno @ 0b001111) = Some(CSetOffset(cd, cs, rt))
function clause decode (0b010010 @ 0b00000 @ cd : regno @ cs : regno @ rt : regno @ 0b001000) = Some(CSetBounds(cd, cs, rt))
function clause decode (0b010010 @ 0b00000 @ cd : regno @ cs : regno @ rt : regno @ 0b001001) = Some(CSetBoundsExact(cd, cs, rt))


function clause decode (0b010010 @ 0b00000 @ cd : regno @ cb : regno @ rt : regno @ 0b010001) = Some(CIncOffset(cd, cb, rt))
function clause decode (0b010010 @ 0b00000 @ cd : regno @ cb : regno @ ct : regno @ 0b011101) = Some(CBuildCap(cd, cb, ct))
function clause decode (0b010010 @ 0b00000 @ cd : regno @ cb : regno @ ct : regno @ 0b011110) = Some(CCopyType(cd, cb, ct))
function clause decode (0b010010 @ 0b00000 @ cd : regno @ cs : regno @ ct : regno @ 0b011111) = Some(CCSeal(cd, cs, ct))

/* Pointer Arithmetic */
function clause decode (0b010010 @ 0b00000 @ rd : regno @ cb : regno @ ct : regno @ 0b010010) = Some(CToPtr(rd, cb, ct))
function clause decode (0b010010 @ 0b00000 @ cd : regno @ cb : regno @ rs : regno @ 0b010011) = Some(CFromPtr(cd, cb, rs))
function clause decode (0b010010 @ 0b00000 @ rt : regno @ cb : regno @ cs : regno @ 0b001010) = Some(CSub(rt, cb, cs))
function clause decode (0b010010 @ 0b00000 @ cd : regno @ cs : regno @ rs : regno @ 0b011011) = Some(CMOVX(cd, cs, rs, false)) /* CMOVZ */
function clause decode (0b010010 @ 0b00000 @ cd : regno @ cs : regno @ rs : regno @ 0b011100) = Some(CMOVX(cd, cs, rs, true))  /* CMOVN */

/* Pointer Comparison */
function clause decode (0b010010 @ 0b00000 @ rd : regno @ cb : regno @ cs : regno @ 0b010100) = Some(CPtrCmp(rd, cb, cs, CEQ))
function clause decode (0b010010 @ 0b00000 @ rd : regno @ cb : regno @ cs : regno @ 0b010101) = Some(CPtrCmp(rd, cb, cs, CNE))
function clause decode (0b010010 @ 0b00000 @ rd : regno @ cb : regno @ cs : regno @ 0b010110) = Some(CPtrCmp(rd, cb, cs, CLT))
function clause decode (0b010010 @ 0b00000 @ rd : regno @ cb : regno @ cs : regno @ 0b010111) = Some(CPtrCmp(rd, cb, cs, CLE))
function clause decode (0b010010 @ 0b00000 @ rd : regno @ cb : regno @ cs : regno @ 0b011000) = Some(CPtrCmp(rd, cb, cs, CLTU))
function clause decode (0b010010 @ 0b00000 @ rd : regno @ cb : regno @ cs : regno @ 0b011001) = Some(CPtrCmp(rd, cb, cs, CLEU))
function clause decode (0b010010 @ 0b00000 @ rd : regno @ cb : regno @ cs : regno @ 0b011010) = Some(CPtrCmp(rd, cb, cs, CEXEQ))
function clause decode (0b010010 @ 0b00000 @ rd : regno @ cb : regno @ cs : regno @ 0b100001) = Some(CPtrCmp(rd, cb, cs, CNEXEQ))

function clause decode (0b010010 @ 0b00000 @ rd : regno @ cb : regno @ ct : regno @ 0b100000) = Some(CTestSubset(rd, cb, ct))

function clause decode (0b010010 @ 0b01001 @ cd : regno @ imm : bits(16)) = Some(CBX(cd, imm, true))  /* CBTU */
function clause decode (0b010010 @ 0b01010 @ cd : regno @ imm : bits(16)) = Some(CBX(cd, imm, false)) /* CBTS */
function clause decode (0b010010 @ 0b10001 @ cd : regno @ imm : bits(16)) = Some(CBZ(cd, imm, false)) /* CBEZ */
function clause decode (0b010010 @ 0b10010 @ cd : regno @ imm : bits(16)) = Some(CBZ(cd, imm, true))  /* CBNZ */

function clause decode (0b010010 @ 0b00101 @    0b00000 @    0b00000 @ 0b11111111111) = Some(CReturn())
function clause decode (0b010010 @ 0b00101 @ cs : regno @ cb : regno @ selector : bits(11)) = Some(CCall(cs, cb, selector))

function clause decode (0b010010 @ 0b01111 @ 0b00000 @ imm : bits(16)) = Some(ClearRegs(GPLo, imm))
function clause decode (0b010010 @ 0b01111 @ 0b00001 @ imm : bits(16)) = Some(ClearRegs(GPHi, imm))
function clause decode (0b010010 @ 0b01111 @ 0b00010 @ imm : bits(16)) = Some(ClearRegs(CLo,  imm))
function clause decode (0b010010 @ 0b01111 @ 0b00011 @ imm : bits(16)) = Some(ClearRegs(CHi,  imm))

function clause decode (0b010010 @ 0b10011 @ cd : regno @ cb : regno @ imm : bits(11)) = Some(CIncOffsetImmediate(cd, cb, imm))
function clause decode (0b010010 @ 0b10100 @ cd : regno @ cb : regno @ imm : bits(11)) = Some(CSetBoundsImmediate(cd, cb, imm))

function clause decode (0b110010 @ rd : regno @ cb : regno@ rt : regno @ offset : bits(8) @ 0b0 @ 0b00) = Some(CLoad(rd, cb, rt, offset, false, B)) /* CLBU */
function clause decode (0b110010 @ rd : regno @ cb : regno@ rt : regno @ offset : bits(8) @ 0b1 @ 0b00) = Some(CLoad(rd, cb, rt, offset, true,  B)) /* CLB */
function clause decode (0b110010 @ rd : regno @ cb : regno@ rt : regno @ offset : bits(8) @ 0b0 @ 0b01) = Some(CLoad(rd, cb, rt, offset, false, H)) /* CLHU */
function clause decode (0b110010 @ rd : regno @ cb : regno@ rt : regno @ offset : bits(8) @ 0b1 @ 0b01) = Some(CLoad(rd, cb, rt, offset, true,  H)) /* CLH */
function clause decode (0b110010 @ rd : regno @ cb : regno@ rt : regno @ offset : bits(8) @ 0b0 @ 0b10) = Some(CLoad(rd, cb, rt, offset, false, W)) /* CLWU */
function clause decode (0b110010 @ rd : regno @ cb : regno@ rt : regno @ offset : bits(8) @ 0b1 @ 0b10) = Some(CLoad(rd, cb, rt, offset, true,  W)) /* CLW */
function clause decode (0b110010 @ rd : regno @ cb : regno@ rt : regno @ offset : bits(8) @ 0b0 @ 0b11) = Some(CLoad(rd, cb, rt, offset, false, D)) /* CLD */

function clause decode (0b010010 @ 0b10000 @ rd : regno @ cb : regno @ 0b00000001 @ 0b0 @ 0b00) = Some(CLoadLinked(rd, cb, false, B)) /* CLLBU */
function clause decode (0b010010 @ 0b10000 @ rd : regno @ cb : regno @ 0b00000001 @ 0b1 @ 0b00) = Some(CLoadLinked(rd, cb, true,  B)) /* CLLB  */
function clause decode (0b010010 @ 0b10000 @ rd : regno @ cb : regno @ 0b00000001 @ 0b0 @ 0b01) = Some(CLoadLinked(rd, cb, false, H)) /* CLLHU */
function clause decode (0b010010 @ 0b10000 @ rd : regno @ cb : regno @ 0b00000001 @ 0b1 @ 0b01) = Some(CLoadLinked(rd, cb, true,  H)) /* CLLH  */
function clause decode (0b010010 @ 0b10000 @ rd : regno @ cb : regno @ 0b00000001 @ 0b0 @ 0b10) = Some(CLoadLinked(rd, cb, false, W)) /* CLLWU */
function clause decode (0b010010 @ 0b10000 @ rd : regno @ cb : regno @ 0b00000001 @ 0b1 @ 0b10) = Some(CLoadLinked(rd, cb, true,  W)) /* CLLW  */
function clause decode (0b010010 @ 0b10000 @ rd : regno @ cb : regno @ 0b00000001 @ 0b0 @ 0b11) = Some(CLoadLinked(rd, cb, false, D)) /* CLLD  */

function clause decode (0b111010 @ rs : regno @ cb : regno@ rt : regno @ offset : bits(8) @ 0b0 @ 0b00) = Some(CStore(rs, cb, rt, offset, B)) /* CSB */
function clause decode (0b111010 @ rs : regno @ cb : regno@ rt : regno @ offset : bits(8) @ 0b0 @ 0b01) = Some(CStore(rs, cb, rt, offset, H)) /* CSH */
function clause decode (0b111010 @ rs : regno @ cb : regno@ rt : regno @ offset : bits(8) @ 0b0 @ 0b10) = Some(CStore(rs, cb, rt, offset, W)) /* CSW */
function clause decode (0b111010 @ rs : regno @ cb : regno@ rt : regno @ offset : bits(8) @ 0b0 @ 0b11) = Some(CStore(rs, cb, rt, offset, D)) /* CSD */

function clause decode (0b010010 @ 0b10000 @ rs : regno @ cb : regno @ rd : regno @ 0b0000 @ 0b00) = Some(CStoreConditional(rs, cb, rd, B)) /* CSCB */
function clause decode (0b010010 @ 0b10000 @ rs : regno @ cb : regno @ rd : regno @ 0b0000 @ 0b01) = Some(CStoreConditional(rs, cb, rd, H)) /* CSCH */
function clause decode (0b010010 @ 0b10000 @ rs : regno @ cb : regno @ rd : regno @ 0b0000 @ 0b10) = Some(CStoreConditional(rs, cb, rd, W)) /* CSCW */
function clause decode (0b010010 @ 0b10000 @ rs : regno @ cb : regno @ rd : regno @ 0b0000 @ 0b11) = Some(CStoreConditional(rs, cb, rd, D)) /* CSCD */

function clause decode (0b111110 @ cs : regno @ cb : regno@ rt : regno @ offset : bits(11)) = Some(CSC(cs, cb, rt, offset))
function clause decode (0b010010 @ 0b10000 @ cs : regno @ cb : regno@ rd : regno @ 0b00 @ 0b0111) = Some(CSCC(cs, cb, rd))

function clause decode (0b110110 @ cd : regno @ cb : regno @ rt : regno @ offset : bits(11)) = Some(CLC(cd, cb, rt, offset))
function clause decode (0b010010 @ 0b10000 @ cd : regno @ cb : regno@ 0b0000000 @ 0b1111) = Some(CLLC(cd, cb))
function clause decode (0b011101 @ cd : regno @ cb : regno @ offset : bits(16)) = Some(CLCBI(cd, cb, offset))

function clause decode (0b010010 @ 0b00100 @ rt : regno @ 0x0006) = Some(C2Dump(rt))
