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

/* default fetch address checks */

type ext_fetch_addr_error = unit

/* Since fetch is done in granules, the check function gets two arguments:
 * start_pc: the PC at the start of the current fetch sequence
 * pc:       the PC for the current granule
 *
 * returns:  the *virtual* memory address to use for the fetch.
 *           any address translation errors are reported for pc, not the returned value.
 */
function ext_fetch_check_pc(start_pc : xlenbits, pc : xlenbits) -> Ext_FetchAddr_Check(ext_fetch_addr_error) =
  Ext_FetchAddr_OK(pc)

function ext_handle_fetch_check_error(err : ext_fetch_addr_error) -> unit =
  ()

/* default control address checks */

type ext_control_addr_error = unit

/* these functions return the address to use as the target for
 * the control transfer.  any address translation or other errors
 * are reported for the original value, not the returned value.
 *
 * NOTE: the input value does *not* have bit[0] set to 0, to enable
 * more accurate bounds checking.  There is no constraint on the output
 * value, which will have bit[0] cleared by the caller if needed.
 */

/* the control address is derived from a non-PC register, e.g. in JALR */
function ext_control_check_addr(pc : xlenbits) -> Ext_ControlAddr_Check(ext_control_addr_error) =
  Ext_ControlAddr_OK(pc)

/* the control address is derived from the PC register, e.g. in JAL */
function ext_control_check_pc(pc : xlenbits) -> Ext_ControlAddr_Check(ext_control_addr_error) =
  Ext_ControlAddr_OK(pc)

function ext_handle_control_check_error(err : ext_control_addr_error) -> unit =
  ()


/* The default data address function does not perform any checks so
   just uses unit for error type. */
type ext_data_addr_error = unit

/* Default data addr is just base register + immediate offset (may be zero).
   Extensions might override and add additional checks. */
function ext_data_get_addr(base : regidx, offset : xlenbits, acc : AccessType(ext_access_type), width : xlenbits)
         -> Ext_DataAddr_Check(ext_data_addr_error) =
  let addr = X(base) + offset in
  Ext_DataAddr_OK(addr)

function ext_handle_data_check_error(err : ext_data_addr_error) -> unit =
  ()

/* Default implementations of these hooks permit all accesses.  */
function ext_check_phys_mem_read (access_type, paddr, size, aquire, release, reserved, read_meta) =
  Ext_PhysAddr_OK ()

function ext_check_phys_mem_write(write_kind, paddr, size, data, metadata) =
  Ext_PhysAddr_OK ()
