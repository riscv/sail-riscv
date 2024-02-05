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

/*
 * Types used in supporting extensions for page-table walks.
 *
 * There are three types involved:
 *
 * . An accumulator, passed down from the root to the leaves (ext_ptw)
 * . Metadata returned with failed permissions checks (ext_ptw_fail)
 * . Errors embedded within the PTW_Error union
 *
 * Information flow begins with init_ext_ptw (: ext_ptw) being routed,
 * via the translateNN functions and/or walkNN functions, to the
 * checkPTEPermission function, which is the intended point of
 * interaction with extensions.
 *
 * checkPTEPermission will be called repeatedly at each PTE, each call
 * seeing the accumulator state generated by a successful result of
 * the previous call.  On failure, this function is expected to
 * generate, instead, an ext_ptw_fail value as well as a new
 * accumulator value, both of which will be returned to the code
 * calling into translation.
 *
 * If translation ultimately succeeds, the final accumulator state is
 * captured and will be returned to the code calling into translation.
 *
 * If translation ultimately fails, the accumulator at the time of
 * failure and the ext_ptw_fail value are returned to the caller.  The
 * ext_ptw_fail value is used to generate a PTW_Error value by calling
 * ext_get_ptw_error; this allows the extension to generate both novel
 * (e.g., PTW_Ext_Error) and existing (e.g., PTW_Invalid_PTE) PTW_Error
 * values.
 */

type ext_ptw = unit
let init_ext_ptw : ext_ptw = ()

type ext_ptw_fail = unit

/* This type can be used for custom errors for page-table-walks,
 * and values in this type are typically generated from the final
 * result of the ext_ptw at the end of the walk.
 */
type ext_ptw_error = unit /* No extensions for page-table-walk errors */

/* This type supports extensions to the exceptions defined in the ISA. */
type ext_exc_type = unit /* No exception extensions */

/* This type supports extensions to the memory AccessType */
type ext_access_type = unit /* No memory access extensions */

/* Default translation of PTW errors into exception annotations */
function ext_translate_exception(e : ext_ptw_error) -> ext_exc_type =
  e /* type pun because both are unit; extensions may need to override this */

/* Default conversion of extension exceptions to bits */
val ext_exc_type_to_bits : ext_exc_type -> exc_code
function ext_exc_type_to_bits(e) = 0x18 /* First code for a custom extension */

/* Default conversion of extension exceptions to integers */
val num_of_ext_exc_type : ext_exc_type -> {'n, (0 <= 'n < xlen). int('n)}
function num_of_ext_exc_type(e) = 24 /* First code for a custom extension */

/* Default conversion of extension exceptions to strings */
val ext_exc_type_to_str : ext_exc_type -> string
function ext_exc_type_to_str(e) = "extension-exception"
