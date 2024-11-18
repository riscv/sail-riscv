/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in https://github.com/riscv/sail-riscv/blob/master/LICENCE.       */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*  Modified by NXP on 11/06/2024 for zilsd support                   					 */
/*=======================================================================================*/


enum clause extension = Ext_Zilsd
function clause extensionEnabled(Ext_Zilsd) = xlen == 32 & sys_enable_zilsd()

union clause ast = ZILSD_LD : (bits(12), regidx, regidx)

mapping clause encdec = ZILSD_LD(i110, rs1, rd)
	if extensionEnabled(Ext_Zilsd) & xlen == 32
<-> i110 : bits(12) @ rs1 : bits(5) @ 0b011 @ rd : bits(5) @ 0b0000011
	if extensionEnabled(Ext_Zilsd) & xlen == 32

function clause execute(ZILSD_LD(imm, rs1, rd)) = {
	let offset : xlenbits = sign_extend(imm);
	let vaddr = X(rs1) + offset;
	if check_misaligned(vaddr, DOUBLE)
	then {handle_mem_exception(vaddr, E_Load_Addr_Align()); RETIRE_FAIL}
	else match translateAddr(vaddr, Read(Data)) {
	TR_Failure(e, _) => {handle_mem_exception(vaddr, e); RETIRE_FAIL},
	TR_Address(paddr, _) =>
		match mem_read(Read(Data), paddr, 4, false, false, false) {
		MemValue(result) => {
			match translateAddr(vaddr+4, Read(Data)) {
			TR_Failure(e, _) => {handle_mem_exception(vaddr+4, e); RETIRE_FAIL},
			TR_Address(paddr_4, _) =>
				match mem_read(Read(Data), paddr_4, 4, false, false, false) {
				MemValue(result1) => {
				    if rd != zeros() then {
					X(rd) = sign_extend(result);
					X(rd + to_bits(5, 1)) = sign_extend(result1);
					};
					RETIRE_SUCCESS
				},
				MemException(e) => {handle_mem_exception(vaddr, e); RETIRE_FAIL},
			}
		}
	},
	MemException(e) => {handle_mem_exception(vaddr, e); RETIRE_FAIL},
	},
}
}

mapping clause assembly = ZILSD_LD(imm, rs1, rd)
	if extensionEnabled(Ext_Zilsd) & xlen == 32
<-> "ld" ^ spc() ^ reg_name(rs1) ^ sep() ^ reg_name(rd) ^ sep() ^ hex_bits_12(imm)
	if extensionEnabled(Ext_Zilsd) & xlen == 32

union clause ast = ZILSD_SD : (bits(12), regidx, regidx)

mapping clause encdec = ZILSD_SD(i40 @ i115, rs2, rs1)
	if extensionEnabled(Ext_Zilsd) & xlen == 32
<-> i115 : bits(7) @ rs2 : bits(5) @ rs1 : bits(5) @ 0b011 @ i40 : bits(5) @ 0b0100011
	if extensionEnabled(Ext_Zilsd) & xlen == 32

function clause execute(ZILSD_SD(imm, rs2, rs1)) = {
	let offset : xlenbits = sign_extend(imm);
	let vaddr = X(rs1) + offset;
	if check_misaligned(vaddr, DOUBLE)
	then {handle_mem_exception(vaddr, E_SAMO_Addr_Align()); RETIRE_FAIL}
	else match translateAddr(vaddr, Read(Data)) {
	TR_Failure(e, _) => {handle_mem_exception(vaddr, e); RETIRE_FAIL},
	TR_Address(paddr, _) =>
		match mem_write_ea(paddr, 4, false, false, false) {
		MemValue(_) => {
			let result : MemoryOpResult(bool) = mem_write_value(paddr, 4, X(rs2), false, false, false) in
			match result {
				MemValue(true) =>{
				match translateAddr(vaddr+4, Write(Data)) {
				TR_Failure(e, _) => {handle_mem_exception(vaddr+4, e); RETIRE_FAIL},
				TR_Address(paddr_4, _) =>
					match mem_write_ea(paddr_4, 4, false, false, false) {
						MemValue(_) => {
							let value:  xlenbits = if rs2 == zeros() then zeros() else X(rs2+1) in
							let result1 : MemoryOpResult(bool) = mem_write_value(paddr_4, 4, value, false, false, false) in
							match result1 {
								MemValue(true) => {RETIRE_SUCCESS},
								MemValue(false) => {internal_error(__FILE__, __LINE__, "sd failed")},
								MemException(e) => {handle_mem_exception(vaddr+4, e); RETIRE_FAIL},
							}
					},
				MemException(e) => {handle_mem_exception(vaddr, e); RETIRE_FAIL},
				}
			}
			},
			MemValue(false) => {internal_error(__FILE__, __LINE__, "sd failed")},
			MemException(e) => {handle_mem_exception(vaddr+4, e); RETIRE_FAIL},
			}
		},
		MemException(e) => {handle_mem_exception(vaddr, e); RETIRE_FAIL},
		},
	}
}

mapping clause assembly = ZILSD_SD(imm, rs2, rs1)
	if extensionEnabled(Ext_Zilsd) & xlen == 32
<-> "sd" ^ spc() ^ reg_name(rs2) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_12(imm)
	if extensionEnabled(Ext_Zilsd) & xlen == 32
