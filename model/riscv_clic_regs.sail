/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Architectural state for the 'Smclic' fast interrupts extension. */

/* Smclic csrs */
mapping clause csr_name_map = 0x307  <-> "mtvt"
mapping clause csr_name_map = 0x345  <-> "mnxti"
mapping clause csr_name_map = 0xFB1  <-> "mintstatus"
mapping clause csr_name_map = 0x347  <-> "mintthresh"
mapping clause csr_name_map = 0x348  <-> "mscratchcsw"
mapping clause csr_name_map = 0x349  <-> "mscratchcswl"
/* Ssclic csrs */
mapping clause csr_name_map = 0x107  <-> "stvt"
mapping clause csr_name_map = 0x145  <-> "snxti"
mapping clause csr_name_map = 0xDB1  <-> "sintstatus"
mapping clause csr_name_map = 0x147  <-> "sintthresh"
mapping clause csr_name_map = 0x148  <-> "sscratchcsw"
mapping clause csr_name_map = 0x149  <-> "sscratchcswl"
/* Suclic csrs */
mapping clause csr_name_map = 0x107  <-> "utvt"
mapping clause csr_name_map = 0x145  <-> "unxti"
mapping clause csr_name_map = 0xDB1  <-> "uintstatus"
mapping clause csr_name_map = 0x147  <-> "uintthresh"
mapping clause csr_name_map = 0x148  <-> "sscratchcsw"
mapping clause csr_name_map = 0x149  <-> "sscratchcswl"

register inhv         : bits(1) /* internal state of accessing vector table, exception handler will decide which xinhv to set */

register mtvt         : xlenbits
register mintthresh   : ilbits
register mil          : ilbits
register mpil         : ilbits
register minhv        : bits(1)

register stvt         : xlenbits
register sintthresh   : ilbits
register sil          : ilbits
register spil         : ilbits
register sinhv        : bits(1)

register utvt         : xlenbits
register uintthresh   : ilbits
register uil          : ilbits
register upil         : ilbits
register uinhv        : bits(1)

register clicintip_raw      : vector(4096, dec, bits(1))
register clicintip_raw_prev : vector(4096, dec, bits(1))
register clicintip          : vector(4096, dec, bits(1))
register clicintie          : vector(4096, dec, bits(1))
register clicintctl         : vector(4096, dec, ilbits)
register clicintattr        : vector(4096, dec, clicintattr_layout)

bitfield ClicMcause : xlenbits = {
  IsInterrupt : xlen - 1,
  Minhv         : 30,
  ClicMcauseMpp : 29 .. 28,
  ClicMcauseMpie: 27,
  Mpil          : 23 .. 16,
  Exccode       : 11 .. 0
}
register clicmcause : ClicMcause
register clicmstatus : Mstatus

bitfield ClicScause : xlenbits = {
  IsInterrupt : xlen - 1,
  Sinhv         : 30,
  ClicScauseSpp : 28,
  ClicScauseSpie: 27,
  Spil          : 23 .. 16,
  Exccode       : 11 .. 0
}
register clicscause : ClicScause

bitfield ClicUcause : xlenbits = {
  IsInterrupt : xlen - 1,
  Uinhv         : 30,
  ClicUcauseUpie: 27,
  Upil          : 23 .. 16,
  Exccode       : 11 .. 0
}
register clicucause : ClicUcause

bitfield Mintstatus : xlenbits = {
  mil : 31 .. 24,
  sil : 15 .. 8,
  uil : 7 .. 0
}
register mintstatus : Mintstatus
