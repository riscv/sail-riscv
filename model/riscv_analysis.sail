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

$include <regfp.sail>

/* in reverse order because inc vectors don't seem to work (bug) */
let GPRstrs : vector(32, dec, string) = [ "x31", "x30", "x29", "x28", "x27", "x26", "x25", "x24", "x23", "x22", "x21",
  "x20", "x19", "x18", "x17", "x16", "x15", "x14", "x13", "x12", "x11",
  "x10", "x9", "x8", "x7", "x6", "x5", "x4", "x3", "x2", "x1", "x0"
  ]

function GPRstr(i: bits(5)) -> string = GPRstrs[unsigned(i)]

let CIA_fp = RFull("CIA")
let NIA_fp = RFull("NIA")

$ifndef FEATURE_UNION_BARRIER

function initial_analysis (instr:ast) -> (regfps,regfps,regfps,niafps,diafp,instruction_kind) = {
  iR = [| |] : regfps;
  oR = [| |] : regfps;
  aR = [| |] : regfps;
  ik = IK_simple() : instruction_kind;
  Nias = [| NIAFP_successor() |] : niafps;
  Dia = DIAFP_none() : diafp;

  match instr {
     EBREAK() => (),
     UTYPE(imm, rd, op) => {
            if (rd == 0b00000) then () else oR = RFull(GPRstr(rd)) :: oR;
     },
     RISCV_JAL(imm, rd) => {
            if (rd == 0b00000) then () else oR = RFull(GPRstr(rd)) :: oR;
            let offset : bits(64) = sign_extend(imm) in
            Nias = [| NIAFP_concrete_address (PC + offset) |];
            ik = IK_branch();
     },
     RISCV_JALR(imm, rs, rd) => {
            if (rs == 0b00000) then () else iR = RFull(GPRstr(rs)) :: iR;
            if (rd == 0b00000) then () else oR = RFull(GPRstr(rd)) :: oR;
            let offset : bits(64) = sign_extend(imm) in
            Nias = [| NIAFP_indirect_address() |];
            ik = IK_branch();
     },
     BTYPE(imm, rs2, rs1, op) => {
            if (rs2 == 0b00000) then () else iR = RFull(GPRstr(rs2)) :: iR;
            if (rs1 == 0b00000) then () else iR = RFull(GPRstr(rs1)) :: iR;
            ik = IK_branch();
            let offset : bits(64) = sign_extend(imm) in
            Nias = [| NIAFP_concrete_address(PC + offset), NIAFP_successor() |];
      },
      ITYPE(imm, rs, rd, op) => {
            if (rs == 0b00000) then () else iR = RFull(GPRstr(rs)) :: iR;
            if (rd == 0b00000) then () else oR = RFull(GPRstr(rd)) :: oR;
      },
      SHIFTIOP(imm, rs, rd, op) => {
             if (rs == 0b00000) then () else iR = RFull(GPRstr(rs)) :: iR;
             if (rd == 0b00000) then () else oR = RFull(GPRstr(rd)) :: oR;
      },
      RTYPE(rs2, rs1, rd, op) => {
             if (rs2 == 0b00000) then () else iR = RFull(GPRstr(rs2)) :: iR;
             if (rs1 == 0b00000) then () else iR = RFull(GPRstr(rs1)) :: iR;
             if (rd == 0b00000) then () else oR = RFull(GPRstr(rd)) :: oR;
      },
      CSR(csr, rs1, rd, is_imm, op) => {
               let isWrite : bool = match op {
                   CSRRW  => true,
                   _      => if is_imm then unsigned(rs1) != 0 else unsigned(rs1) != 0
               };
               iR = RFull(csr_name(csr)) :: iR;
               if not(is_imm) then {
                  iR = RFull(GPRstr(rs1)) :: iR;
               };
               if isWrite then {
                  oR = RFull(csr_name(csr)) :: oR;
               };
               oR = RFull(GPRstr(rd)) :: oR;
      },
      LOAD(imm, rs, rd, unsign, width, aq, rl) => { /* XXX "unsigned" causes name conflict in lem shallow embedding... */
             if (rs == 0b00000) then () else iR = RFull(GPRstr(rs)) :: iR;
             if (rd == 0b00000) then () else oR = RFull(GPRstr(rd)) :: oR;
             aR = iR;
             ik =
               match (aq, rl) {
                 (false, false) => IK_mem_read (Read_plain),
                 (true,  false) => IK_mem_read (Read_RISCV_acquire),
                 (true,  true)  => IK_mem_read (Read_RISCV_strong_acquire),

                 _  => internal_error(__FILE__, __LINE__, "LOAD type not implemented in initial_analysis")
               }
      },
      STORE(imm, rs2, rs1, width, aq, rl) => {
             if (rs2 == 0b00000) then () else iR = RFull(GPRstr(rs2)) :: iR;
             if (rs1 == 0b00000) then () else iR = RFull(GPRstr(rs1)) :: iR;
             if (rs1 == 0b00000) then () else aR = RFull(GPRstr(rs1)) :: aR;
             ik =
               match (aq, rl) {
                 (false, false) => IK_mem_write (Write_plain),
                 (false, true)  => IK_mem_write (Write_RISCV_release),
                 (true,  true)  => IK_mem_write (Write_RISCV_strong_release),

                 _ => internal_error(__FILE__, __LINE__, "STORE type not implemented in initial_analysis")
               }
      },
      ADDIW(imm, rs, rd) => {
             if (rs == 0b00000) then () else iR = RFull(GPRstr(rs)) :: iR;
             if (rd == 0b00000) then () else oR = RFull(GPRstr(rd)) :: oR;
      },
      SHIFTIWOP(imm, rs, rd, op) => {
             if (rs == 0b00000) then () else iR = RFull(GPRstr(rs)) :: iR;
             if (rd == 0b00000) then () else oR = RFull(GPRstr(rd)) :: oR;
      },
      RTYPEW(rs2, rs1, rd, op) => {
             if (rs2 == 0b00000) then () else iR = RFull(GPRstr(rs2)) :: iR;
             if (rs1 == 0b00000) then () else iR = RFull(GPRstr(rs1)) :: iR;
             if (rd == 0b00000) then () else oR = RFull(GPRstr(rd)) :: oR;
      },
      FENCE(pred, succ) => {
             ik =
               match (pred, succ) {
                 (_ : bits(2) @ 0b11, _ : bits(2) @ 0b11) => IK_barrier (Barrier_RISCV_rw_rw),
                 (_ : bits(2) @ 0b10, _ : bits(2) @ 0b11) => IK_barrier (Barrier_RISCV_r_rw),
                 (_ : bits(2) @ 0b10, _ : bits(2) @ 0b10) => IK_barrier (Barrier_RISCV_r_r),
                 (_ : bits(2) @ 0b11, _ : bits(2) @ 0b01) => IK_barrier (Barrier_RISCV_rw_w),
                 (_ : bits(2) @ 0b01, _ : bits(2) @ 0b01) => IK_barrier (Barrier_RISCV_w_w),
                 (_ : bits(2) @ 0b01, _ : bits(2) @ 0b11) => IK_barrier (Barrier_RISCV_w_rw),
                 (_ : bits(2) @ 0b11, _ : bits(2) @ 0b10) => IK_barrier (Barrier_RISCV_rw_r),
                 (_ : bits(2) @ 0b10, _ : bits(2) @ 0b01) => IK_barrier (Barrier_RISCV_r_w),
                 (_ : bits(2) @ 0b01, _ : bits(2) @ 0b10) => IK_barrier (Barrier_RISCV_w_r),


                 (_ : bits(2) @ 0b00, _ : bits(2) @ 0b00) => IK_simple (),

                 _ => internal_error(__FILE__, __LINE__, "barrier type not implemented in initial_analysis")
               };
      },
      FENCE_TSO(pred, succ) => {
             ik =
               match (pred, succ) {
                 (_ : bits(2) @ 0b11, _ : bits(2) @ 0b11) => IK_barrier (Barrier_RISCV_tso),
                 _ => internal_error(__FILE__, __LINE__, "barrier type not implemented in initial_analysis")
               };
      },
     FENCEI() => {
              ik = IK_simple (); // for RMEM, should morally be Barrier_RISCV_i
     },
     LOADRES(aq, rl, rs1, width, rd) => {
            if (rs1 == 0b00000) then () else iR = RFull(GPRstr(rs1)) :: iR;
            if (rd == 0b00000) then () else oR = RFull(GPRstr(rd)) :: oR;
            aR = iR;
            ik = match (aq, rl) {
              (false, false) => IK_mem_read (Read_RISCV_reserved),
              (true,  false) => IK_mem_read (Read_RISCV_reserved_acquire),
              (true,  true)  => IK_mem_read (Read_RISCV_reserved_strong_acquire),
              (false, true)  => internal_error(__FILE__, __LINE__, "LOADRES type not implemented in initial_analysis")
            };
     },
     STORECON(aq, rl, rs2, rs1, width, rd) => {
            if (rs2 == 0b00000) then () else iR = RFull(GPRstr(rs2)) :: iR;
            if (rs1 == 0b00000) then () else iR = RFull(GPRstr(rs1)) :: iR;
            if (rs1 == 0b00000) then () else aR = RFull(GPRstr(rs1)) :: aR;
            if (rd == 0b00000) then () else oR = RFull(GPRstr(rd)) :: oR;
             ik = match (aq, rl) {
               (false, false) => IK_mem_write (Write_RISCV_conditional),
               (false, true)  => IK_mem_write (Write_RISCV_conditional_release),
               (true,  true)  => IK_mem_write (Write_RISCV_conditional_strong_release),

               (true,  false) => internal_error(__FILE__, __LINE__, "STORECON type not implemented in initial_analysis")
             };
      },
      AMO(op, aq, rl, rs2, rs1, width, rd) => {
             if (rs2 == 0b00000) then () else iR = RFull(GPRstr(rs2)) :: iR;
             if (rs1 == 0b00000) then () else iR = RFull(GPRstr(rs1)) :: iR;
             if (rs1 == 0b00000) then () else aR = RFull(GPRstr(rs1)) :: aR;
             if (rd == 0b00000) then () else oR = RFull(GPRstr(rd)) :: oR;
             ik = match (aq, rl) {
               (false, false) => IK_mem_rmw (Read_RISCV_reserved, Write_RISCV_conditional),
               (false, true)  => IK_mem_rmw (Read_RISCV_reserved, Write_RISCV_conditional_release),
               (true,  false) => IK_mem_rmw (Read_RISCV_reserved_acquire,
                                                                       Write_RISCV_conditional),
               (true,  true)  => IK_mem_rmw (Read_RISCV_reserved_acquire,
                                                                       Write_RISCV_conditional_release)
             };
      },
        _ => ()
  };
  (iR,oR,aR,Nias,Dia,ik)
}

$else

function initial_analysis (instr:ast) -> (regfps,regfps,regfps,niafps,diafp,instruction_kind) = {
  iR = [| |] : regfps;
  oR = [| |] : regfps;
  aR = [| |] : regfps;
  ik = IK_simple() : instruction_kind;
  Nias = [| NIAFP_successor() |] : niafps;
  Dia = DIAFP_none() : diafp;

  match instr {
     EBREAK() => (),
     UTYPE(imm, rd, op) => {
	    if (rd == 0b00000) then () else oR = RFull(GPRstr(rd)) :: oR;
     },
     RISCV_JAL(imm, rd) => {
	    if (rd == 0b00000) then () else oR = RFull(GPRstr(rd)) :: oR;
            let offset : bits(64) = sign_extend(imm) in
            Nias = [| NIAFP_concrete_address (PC + offset) |];
            ik = IK_branch();
     },
     RISCV_JALR(imm, rs, rd) => {
            if (rs == 0b00000) then () else iR = RFull(GPRstr(rs)) :: iR;
            if (rd == 0b00000) then () else oR = RFull(GPRstr(rd)) :: oR;
            let offset : bits(64) = sign_extend(imm) in
            Nias = [| NIAFP_indirect_address() |];
            ik = IK_branch();
     },
     BTYPE(imm, rs2, rs1, op) => {
            if (rs2 == 0b00000) then () else iR = RFull(GPRstr(rs2)) :: iR;
            if (rs1 == 0b00000) then () else iR = RFull(GPRstr(rs1)) :: iR;
            ik = IK_branch();
            let offset : bits(64) = sign_extend(imm) in
            Nias = [| NIAFP_concrete_address(PC + offset), NIAFP_successor() |];
      },
      ITYPE(imm, rs, rd, op) => {
            if (rs == 0b00000) then () else iR = RFull(GPRstr(rs)) :: iR;
            if (rd == 0b00000) then () else oR = RFull(GPRstr(rd)) :: oR;
      },
      SHIFTIOP(imm, rs, rd, op) => {
             if (rs == 0b00000) then () else iR = RFull(GPRstr(rs)) :: iR;
             if (rd == 0b00000) then () else oR = RFull(GPRstr(rd)) :: oR;
      },
      RTYPE(rs2, rs1, rd, op) => {
             if (rs2 == 0b00000) then () else iR = RFull(GPRstr(rs2)) :: iR;
             if (rs1 == 0b00000) then () else iR = RFull(GPRstr(rs1)) :: iR;
             if (rd == 0b00000) then () else oR = RFull(GPRstr(rd)) :: oR;
      },
      CSR(csr, rs1, rd, is_imm, op) => {
               let isWrite : bool = match op {
                   CSRRW  => true,
                   _      => if is_imm then unsigned(rs1) != 0 else unsigned(rs1) != 0
               };
               iR = RFull(csr_name(csr)) :: iR;
               if not(is_imm) then {
                  iR = RFull(GPRstr(rs1)) :: iR;
               };
               if isWrite then {
                  oR = RFull(csr_name(csr)) :: oR;
               };
               oR = RFull(GPRstr(rd)) :: oR;
      },
      LOAD(imm, rs, rd, unsign, width, aq, rl) => { /* XXX "unsigned" causes name conflict in lem shallow embedding... */
             if (rs == 0b00000) then () else iR = RFull(GPRstr(rs)) :: iR;
             if (rd == 0b00000) then () else oR = RFull(GPRstr(rd)) :: oR;
             aR = iR;
             ik =
               match (aq, rl) {
                 (false, false) => IK_mem_read (Read_plain),
                 (true,  false) => IK_mem_read (Read_RISCV_acquire),
                 (true,  true)  => IK_mem_read (Read_RISCV_strong_acquire),

                 _  => internal_error(__FILE__, __LINE__, "LOAD type not implemented in initial_analysis")
               }
      },
      STORE(imm, rs2, rs1, width, aq, rl) => {
             if (rs2 == 0b00000) then () else iR = RFull(GPRstr(rs2)) :: iR;
             if (rs1 == 0b00000) then () else iR = RFull(GPRstr(rs1)) :: iR;
             if (rs1 == 0b00000) then () else aR = RFull(GPRstr(rs1)) :: aR;
             ik =
               match (aq, rl) {
                 (false, false) => IK_mem_write (Write_plain),
                 (false, true)  => IK_mem_write (Write_RISCV_release),
                 (true,  true)  => IK_mem_write (Write_RISCV_strong_release),

                 _ => internal_error(__FILE__, __LINE__, "STORE type not implemented in initial_analysis")
               }
      },
      ADDIW(imm, rs, rd) => {
             if (rs == 0b00000) then () else iR = RFull(GPRstr(rs)) :: iR;
             if (rd == 0b00000) then () else oR = RFull(GPRstr(rd)) :: oR;
      },
      SHIFTIWOP(imm, rs, rd, op) => {
             if (rs == 0b00000) then () else iR = RFull(GPRstr(rs)) :: iR;
             if (rd == 0b00000) then () else oR = RFull(GPRstr(rd)) :: oR;
      },
      RTYPEW(rs2, rs1, rd, op) => {
             if (rs2 == 0b00000) then () else iR = RFull(GPRstr(rs2)) :: iR;
             if (rs1 == 0b00000) then () else iR = RFull(GPRstr(rs1)) :: iR;
             if (rd == 0b00000) then () else oR = RFull(GPRstr(rd)) :: oR;
      },
      FENCE(pred, succ) => {
             ik =
               match (pred, succ) {
		 (_ : bits(2) @ 0b11, _ : bits(2) @ 0b11) => IK_barrier (Barrier_RISCV_rw_rw ()),
		 (_ : bits(2) @ 0b10, _ : bits(2) @ 0b11) => IK_barrier (Barrier_RISCV_r_rw ()),
		 (_ : bits(2) @ 0b10, _ : bits(2) @ 0b10) => IK_barrier (Barrier_RISCV_r_r ()),
		 (_ : bits(2) @ 0b11, _ : bits(2) @ 0b01) => IK_barrier (Barrier_RISCV_rw_w ()),
		 (_ : bits(2) @ 0b01, _ : bits(2) @ 0b01) => IK_barrier (Barrier_RISCV_w_w ()),
		 (_ : bits(2) @ 0b01, _ : bits(2) @ 0b11) => IK_barrier (Barrier_RISCV_w_rw ()),
		 (_ : bits(2) @ 0b11, _ : bits(2) @ 0b10) => IK_barrier (Barrier_RISCV_rw_r ()),
		 (_ : bits(2) @ 0b10, _ : bits(2) @ 0b01) => IK_barrier (Barrier_RISCV_r_w ()),
		 (_ : bits(2) @ 0b01, _ : bits(2) @ 0b10) => IK_barrier (Barrier_RISCV_w_r ()),

                 (_ : bits(2) @ 0b00, _ : bits(2) @ 0b00) => IK_simple (),

                 _ => internal_error(__FILE__, __LINE__, "barrier type not implemented in initial_analysis")
               };
      },
      FENCE_TSO(pred, succ) => {
             ik =
               match (pred, succ) {
		 (_ : bits(2) @ 0b11, _ : bits(2) @ 0b11) => IK_barrier (Barrier_RISCV_tso ()),
                 _ => internal_error(__FILE__, __LINE__, "barrier type not implemented in initial_analysis")
               };
      },
     FENCEI() => {
              ik = IK_simple (); // for RMEM, should morally be Barrier_RISCV_i
     },
     LOADRES(aq, rl, rs1, width, rd) => {
            if (rs1 == 0b00000) then () else iR = RFull(GPRstr(rs1)) :: iR;
            if (rd == 0b00000) then () else oR = RFull(GPRstr(rd)) :: oR;
            aR = iR;
            ik = match (aq, rl) {
              (false, false) => IK_mem_read (Read_RISCV_reserved),
              (true,  false) => IK_mem_read (Read_RISCV_reserved_acquire),
              (true,  true)  => IK_mem_read (Read_RISCV_reserved_strong_acquire),
              (false, true)  => internal_error(__FILE__, __LINE__, "LOADRES type not implemented in initial_analysis")
            };
     },
     STORECON(aq, rl, rs2, rs1, width, rd) => {
            if (rs2 == 0b00000) then () else iR = RFull(GPRstr(rs2)) :: iR;
            if (rs1 == 0b00000) then () else iR = RFull(GPRstr(rs1)) :: iR;
            if (rs1 == 0b00000) then () else aR = RFull(GPRstr(rs1)) :: aR;
            if (rd == 0b00000) then () else oR = RFull(GPRstr(rd)) :: oR;
             ik = match (aq, rl) {
               (false, false) => IK_mem_write (Write_RISCV_conditional),
               (false, true)  => IK_mem_write (Write_RISCV_conditional_release),
               (true,  true)  => IK_mem_write (Write_RISCV_conditional_strong_release),

               (true,  false) => internal_error(__FILE__, __LINE__, "STORECON type not implemented in initial_analysis")
             };
      },
      AMO(op, aq, rl, rs2, rs1, width, rd) => {
             if (rs2 == 0b00000) then () else iR = RFull(GPRstr(rs2)) :: iR;
             if (rs1 == 0b00000) then () else iR = RFull(GPRstr(rs1)) :: iR;
             if (rs1 == 0b00000) then () else aR = RFull(GPRstr(rs1)) :: aR;
             if (rd == 0b00000) then () else oR = RFull(GPRstr(rd)) :: oR;
             ik = match (aq, rl) {
               (false, false) => IK_mem_rmw (Read_RISCV_reserved, Write_RISCV_conditional),
               (false, true)  => IK_mem_rmw (Read_RISCV_reserved, Write_RISCV_conditional_release),
               (true,  false) => IK_mem_rmw (Read_RISCV_reserved_acquire,
                                                                       Write_RISCV_conditional),
               (true,  true)  => IK_mem_rmw (Read_RISCV_reserved_acquire,
                                                                       Write_RISCV_conditional_release)
             };
      },
        _ => ()
  };
  (iR,oR,aR,Nias,Dia,ik)
}

$endif
