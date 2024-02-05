/*=======================================================================================*/
/*  RISCV Sail Model                                                                     */
/*                                                                                       */
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except for the snapshots of the Lem and Sail libraries                   */
/*  in the prover_snapshots directory (which include copies of their                     */
/*  licences), is subject to the BSD two-clause licence below.                           */
/*                                                                                       */
/*  Copyright (c) 2017-2023                                                              */
/*    Prashanth Mundkur                                                                  */
/*    Rishiyur S. Nikhil and Bluespec, Inc.                                              */
/*    Jon French                                                                         */
/*    Brian Campbell                                                                     */
/*    Robert Norton-Wright                                                               */
/*    Alasdair Armstrong                                                                 */
/*    Thomas Bauereiss                                                                   */
/*    Shaked Flur                                                                        */
/*    Christopher Pulte                                                                  */
/*    Peter Sewell                                                                       */
/*    Alexander Richardson                                                               */
/*    Hesham Almatary                                                                    */
/*    Jessica Clarke                                                                     */
/*    Microsoft, for contributions by Robert Norton-Wright and Nathaniel Wesley Filardo  */
/*    Peter Rugg                                                                         */
/*    Aril Computer Corp., for contributions by Scott Johnson                            */
/*    Philipp Tomsich                                                                    */
/*    VRULL GmbH, for contributions by its employees                                     */
/*                                                                                       */
/*  All rights reserved.                                                                 */
/*                                                                                       */
/*  This software was developed by the above within the Rigorous                         */
/*  Engineering of Mainstream Systems (REMS) project, partly funded by                   */
/*  EPSRC grant EP/K008528/1, at the Universities of Cambridge and                       */
/*  Edinburgh.                                                                           */
/*                                                                                       */
/*  This software was developed by SRI International and the University of               */
/*  Cambridge Computer Laboratory (Department of Computer Science and                    */
/*  Technology) under DARPA/AFRL contract FA8650-18-C-7809 ("CIFV"), and                 */
/*  under DARPA contract HR0011-18-C-0016 ("ECATS") as part of the DARPA                 */
/*  SSITH research programme.                                                            */
/*                                                                                       */
/*  This project has received funding from the European Research Council                 */
/*  (ERC) under the European Union’s Horizon 2020 research and innovation                */
/*  programme (grant agreement 789108, ELVER).                                           */
/*                                                                                       */
/*                                                                                       */
/*  Redistribution and use in source and binary forms, with or without                   */
/*  modification, are permitted provided that the following conditions                   */
/*  are met:                                                                             */
/*  1. Redistributions of source code must retain the above copyright                    */
/*     notice, this list of conditions and the following disclaimer.                     */
/*  2. Redistributions in binary form must reproduce the above copyright                 */
/*     notice, this list of conditions and the following disclaimer in                   */
/*     the documentation and/or other materials provided with the                        */
/*     distribution.                                                                     */
/*                                                                                       */
/*  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''                   */
/*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED                    */
/*  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A                      */
/*  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR                  */
/*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,                         */
/*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT                     */
/*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF                     */
/*  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND                  */
/*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,                   */
/*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT                   */
/*  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF                   */
/*  SUCH DAMAGE.                                                                         */
/*=======================================================================================*/

/* H-ext CSR defined handles */
function clause ext_is_CSR_defined(0x34A, _) = haveHExt() /* mtinst */
function clause ext_is_CSR_defined(0x34B, _) = haveHExt() /* mtval2 */
function clause ext_is_CSR_defined(0x600, _) = haveHExt() /* hstatus */
function clause ext_is_CSR_defined(0x602, _) = haveHExt() /* hedeleg */
function clause ext_is_CSR_defined(0x603, _) = haveHExt() /* hideleg */
function clause ext_is_CSR_defined(0x604, _) = haveHExt() /* hie */
function clause ext_is_CSR_defined(0x606, _) = haveHExt() /* hcounteren */
function clause ext_is_CSR_defined(0x607, _) = haveHExt() /* hgeie */
function clause ext_is_CSR_defined(0x643, _) = haveHExt() /* htval */
function clause ext_is_CSR_defined(0x644, _) = haveHExt() /* hip */
function clause ext_is_CSR_defined(0x645, _) = haveHExt() /* hvip */
function clause ext_is_CSR_defined(0x64A, _) = haveHExt() /* htinst */
function clause ext_is_CSR_defined(0xE12, _) = haveHExt() /* hgeip */
function clause ext_is_CSR_defined(0x60A, _) = haveHExt() /* henvcfg */
function clause ext_is_CSR_defined(0x61A, _) = haveHExt() /* henvcfgh */
function clause ext_is_CSR_defined(0x680, _) = haveHExt() /* hgatp */
function clause ext_is_CSR_defined(0x605, _) = haveHExt() /* htimedelta */
function clause ext_is_CSR_defined(0x615, _) = haveHExt() /* htimedeltah */
function clause ext_is_CSR_defined(0x200, _) = haveHExt() /* vsstatus */
function clause ext_is_CSR_defined(0x204, _) = haveHExt() /* vsie */
function clause ext_is_CSR_defined(0x205, _) = haveHExt() /* vstvec */
function clause ext_is_CSR_defined(0x240, _) = haveHExt() /* vsscratch */
function clause ext_is_CSR_defined(0x241, _) = haveHExt() /* vsepc */
function clause ext_is_CSR_defined(0x242, _) = haveHExt() /* vscause */
function clause ext_is_CSR_defined(0x243, _) = haveHExt() /* vstval */
function clause ext_is_CSR_defined(0x244, _) = haveHExt() /* vsip */
function clause ext_is_CSR_defined(0x280, _) = haveHExt() /* vsatp */

/* Initialize hypervisor extension */
function init_hext() -> unit = {
  /* Start with V=0 */
  cur_virtualization = V0;

  /* Init M-mode CRSs */

  if sizeof(xlen) == 32
  then mstatush = set_mstatush_MPV(mstatush, virtMode_to_bits(V0))
  else mstatus = set_mstatus_MPV(mstatus, virtMode_to_bits(V0));

  if sizeof(xlen) == 32
  then mstatush = set_mstatush_GVA(mstatush, 0b0)
  else mstatus = set_mstatus_GVA(mstatus, 0b0);

  mtinst = zeros();
  mtval2 = zeros();

  mideleg = update_SGEI(mideleg, 0b1); /* Note: SGEIE is "read-only one" only if GEILEN > 0 */
  mideleg = update_VSEI(mideleg, 0b1);
  mideleg = update_VSTI(mideleg, 0b1);
  mideleg = update_VSSI(mideleg, 0b1);

  /* Init HS-mode CSRs */

  hstatus->bits() = zeros();
  hstatus = set_hstatus_VSXL(hstatus, misa.MXL()); /* Dynamic XLEN changes are not (yet) supported */

  hedeleg->bits() = zeros();
  hideleg->bits() = zeros();
  hcounteren->bits() = zeros();
  htval = zeros();
  htinst = zeros();
  hgeie = legalize_hgeie(zeros());
  hgeip = zeros();
  /* TODO: init henvcfg */
  /* TODO: init henvcfgh */
  htimedelta = zeros();

  /* Init VS-mode CSRs */

  vsstatus->bits() = zeros();
  vsstatus = set_vsstatus_UXL(vsstatus, misa.MXL()); /* Dynamic XLEN changes are not (yet) supported */
  vstvec->bits() = zeros();
  vsscratch = zeros();
  vsepc = zeros();
  vscause->bits() = zeros();
  vstval = zeros();
  vsatp = zeros();
}

/*
 * Determine if an illegal CSR access should raise a "virtual instruction exception" instead of
 * an "illegal instruction exception"
 *
 * According to the spec. (V20211203 - Section 9.6), this should happen in the following cases:
 *   [X] in VS-mode, attempts to access a non-high-half counter CSR when the corresponding bit
 *       in hcounteren is 0 and the same bit in mcounteren is 1;
 *   [ ] in VS-mode, if XLEN=32, attempts to access a high-half counter CSR when the
 *       corresponding bit in hcounteren is 0 and the same bit in mcounteren is 1;
 *   [X] in VU-mode, attempts to access a non-high-half counter CSR when the corresponding bit
 *       in either hcounteren or scounteren is 0 and the same bit in mcounteren is 1;
 *   [ ] in VU-mode, if XLEN=32, attempts to access a high-half counter CSR when the
 *       corresponding bit in either hcounteren or scounteren is 0 and the same bit in
 *       mcounteren is 1;
 *   [x] in VS-mode or VU-mode, attempts to access an implemented non-high-half hypervisor CSR
 *       or VS CSR when the same access (read/write) would be allowed in HS-mode, assuming
 *       mstatus.TVM=0;
 *   [ ] in VS-mode or VU-mode, if XLEN=32, attempts to access an implemented high-half
 *       hypervisor CSR or high-half VS CSR when the same access (read/write) to the CSR’s
 *       low-half partner would be allowed in HS-mode, assuming mstatus.TVM=0;
 *   [x] in VU-mode, attempts to access an implemented non-high-half supervisor CSR when the
 *       same access (read/write) would be allowed in HS-mode, assuming mstatus.TVM=0;
 *   [ ] in VU-mode, if XLEN=32, attempts to access an implemented high-half supervisor CSR
 *       when the same access to the CSR’s low-half
 *       partner would be allowed in HS-mode, assuming mstatus.TVM=0;
 *   [X] in VS-mode, attempts to access satp, when hstatus.VTVM=1
 */
/* FIXME: The above cases should probably be checked in unittests instead of listed here */
function csr_access_raises_virtual_instr(csr : csreg, p : Privilege, v: Virtualization, isWrite : bool) -> bool = {
  if v == V0
  then false
  // Would HS-access be allowed?
  // Note: Can't reuse check_CSR since it also checks TVM
  else is_CSR_defined(csr, Supervisor) &
       check_CSR_access(csrAccess(csr), csrPriv(csr), Supervisor, V0, isWrite) &
       check_Counteren(csr, Supervisor, V0) &
       check_seed_CSR(csr, Supervisor, isWrite)
}
