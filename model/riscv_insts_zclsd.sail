/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in https://github.com/riscv/sail-riscv/blob/master/LICENCE.       */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*  Modified by NXP on 11/06/2024 for zilsd support                   					 */
/*=======================================================================================*/


enum clause extension = Ext_Zclsd
function clause extensionEnabled(Ext_Zclsd) = sys_enable_zclsd() & extensionEnabled(Ext_Zca) & extensionEnabled(Ext_Zilsd)

union clause ast = ZCLSD_C_LD : (bits(5), cregidx, cregidx)

mapping clause encdec_compressed = ZCLSD_C_LD(i76 @ i53, rs1c_p, rdc_p)
	if extensionEnabled(Ext_Zclsd) & extensionEnabled(Ext_Zca) & extensionEnabled(Ext_Zilsd) & xlen == 32
<-> 0b011 @ i53 : bits(3) @ rs1c_p : bits(3) @ i76 : bits(2) @ rdc_p : bits(3) @ 0b00
	if extensionEnabled(Ext_Zclsd) & extensionEnabled(Ext_Zca) & extensionEnabled(Ext_Zilsd) & xlen == 32

function clause execute(ZCLSD_C_LD(imm, rs1c_p, rdc_p)) = {
	let offset : xlenbits = zero_extend(imm@ 0b000);
	let rs1c_p_idx = creg2reg_idx(rs1c_p);
	let rdc_p_idx = creg2reg_idx(rdc_p);
	let vaddr = X(rs1c_p_idx) + offset;
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
					X(rdc_p_idx) = sign_extend(result);
					X(rdc_p_idx + to_bits(5, 1)) = sign_extend(result1);
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

mapping clause assembly = ZCLSD_C_LD(imm, rs1c_p, rdc_p)
	if extensionEnabled(Ext_Zclsd) & extensionEnabled(Ext_Zca) & extensionEnabled(Ext_Zilsd) & xlen == 32
<-> "c.ld" ^ spc() ^ creg_name(rs1c_p) ^ sep() ^ creg_name(rdc_p) ^ sep() ^ hex_bits_8(imm @ 0b000)
	if extensionEnabled(Ext_Zclsd) & extensionEnabled(Ext_Zca) & extensionEnabled(Ext_Zilsd) & xlen == 32

union clause ast = ZCLSD_C_LDSP : (bits(6), regidx)

mapping clause encdec_compressed = ZCLSD_C_LDSP(i86 @ i55 @ i43, rx)
	if extensionEnabled(Ext_Zclsd) & extensionEnabled(Ext_Zca) & extensionEnabled(Ext_Zilsd) & xlen == 32
<-> 0b011 @ i55 : bits(1) @ rx : bits(5) @ i43 : bits(2) @ i86 : bits(3) @ 0b10
	if extensionEnabled(Ext_Zclsd) & extensionEnabled(Ext_Zca) & extensionEnabled(Ext_Zilsd) & xlen == 32

function clause execute(ZCLSD_C_LDSP(imm, rx)) = {
	let offset : xlenbits = zero_extend(imm@ 0b000);
	let vaddr = X(sp) + offset;
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
					X(rx) = sign_extend(result);
					X(rx + to_bits(5, 1)) = sign_extend(result1);
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

mapping clause assembly = ZCLSD_C_LDSP(imm, rx)
	if extensionEnabled(Ext_Zclsd) & extensionEnabled(Ext_Zca) & extensionEnabled(Ext_Zilsd) & xlen == 32
<-> "c.ldsp" ^ spc() ^ reg_name(rx) ^ sep() ^ hex_bits_9(imm @ 0b000)
	if extensionEnabled(Ext_Zclsd) & extensionEnabled(Ext_Zca) & extensionEnabled(Ext_Zilsd) & xlen == 32

union clause ast = ZCLSD_C_SD : (bits(5), cregidx, cregidx)

mapping clause encdec_compressed = ZCLSD_C_SD(i76 @ i53, rs1c_p, rs2c_p)
	if extensionEnabled(Ext_Zclsd) & extensionEnabled(Ext_Zca) & extensionEnabled(Ext_Zilsd) & xlen == 32
<-> 0b111 @ i53 : bits(3) @ rs1c_p : bits(3) @ i76 : bits(2) @ rs2c_p : bits(3) @ 0b00
	if extensionEnabled(Ext_Zclsd) & extensionEnabled(Ext_Zca) & extensionEnabled(Ext_Zilsd) & xlen == 32

function clause execute(ZCLSD_C_SD(imm, rs1c_p, rs2c_p)) = {
	let offset : xlenbits = zero_extend(imm@ 0b000);
	let rs1c_p_idx = creg2reg_idx(rs1c_p);
	let rs2c_p_idx = creg2reg_idx(rs2c_p);
	let vaddr = X(rs1c_p_idx) + offset;
	if check_misaligned(vaddr, DOUBLE)
	then {handle_mem_exception(vaddr, E_SAMO_Addr_Align()); RETIRE_FAIL}
	else match translateAddr(vaddr, Read(Data)) {
	TR_Failure(e, _) => {handle_mem_exception(vaddr, e); RETIRE_FAIL},
	TR_Address(paddr, _) =>
		match mem_write_ea(paddr, 4, false, false, false) {
		MemValue(_) => {
			let result : MemoryOpResult(bool) = mem_write_value(paddr, 4, X(rs2c_p_idx), false, false, false) in
			match result {
				MemValue(true) =>{
				match translateAddr(vaddr+4, Write(Data)) {
				TR_Failure(e, _) => {handle_mem_exception(vaddr+4, e); RETIRE_FAIL},
				TR_Address(paddr_4, _) =>
					match mem_write_ea(paddr_4, 4, false, false, false) {
						MemValue(_) => {
							let result1 : MemoryOpResult(bool) = mem_write_value(paddr_4, 4, X(rs2c_p_idx+1), false, false, false) in
							match result1 {
								MemValue(true) => {RETIRE_SUCCESS},
								MemValue(false) => {internal_error(__FILE__, __LINE__, "c.sd failed")},
								MemException(e) => {handle_mem_exception(vaddr+4, e); RETIRE_FAIL},
							}
					},
				MemException(e) => {handle_mem_exception(vaddr, e); RETIRE_FAIL},
				}
			}
			},
			MemValue(false) => {internal_error(__FILE__, __LINE__, "c.sd failed")},
			MemException(e) => {handle_mem_exception(vaddr+4, e); RETIRE_FAIL},
			}
		},
		MemException(e) => {handle_mem_exception(vaddr, e); RETIRE_FAIL},
		},
	}
}

mapping clause assembly = ZCLSD_C_SD(imm, rs1c_p, rs2c_p)
	if extensionEnabled(Ext_Zclsd) & extensionEnabled(Ext_Zca) & extensionEnabled(Ext_Zilsd) & xlen == 32
<-> "c.sd" ^ spc() ^ creg_name(rs1c_p) ^ sep() ^ creg_name(rs2c_p) ^ sep() ^ hex_bits_8(imm @ 0b000)
	if extensionEnabled(Ext_Zclsd) & extensionEnabled(Ext_Zca) & extensionEnabled(Ext_Zilsd) & xlen == 32

union clause ast = ZCLSD_C_SDSP : (bits(6), regidx)

mapping clause encdec_compressed = ZCLSD_C_SDSP(i86 @ i53, rs2c)
	if extensionEnabled(Ext_Zclsd) & extensionEnabled(Ext_Zca) & extensionEnabled(Ext_Zilsd) & xlen == 32
<-> 0b111 @ i53 : bits(3) @ i86 : bits(3) @ rs2c : bits(5) @ 0b10
	if extensionEnabled(Ext_Zclsd) & extensionEnabled(Ext_Zca) & extensionEnabled(Ext_Zilsd) & xlen == 32

function clause execute(ZCLSD_C_SDSP(imm, rs2c)) = {
	let offset : xlenbits = zero_extend(imm@ 0b000);
	let vaddr = X(sp) + offset;
	if check_misaligned(vaddr, DOUBLE)
	then {handle_mem_exception(vaddr, E_SAMO_Addr_Align()); RETIRE_FAIL}
	else match translateAddr(vaddr, Read(Data)) {
	TR_Failure(e, _) => {handle_mem_exception(vaddr, e); RETIRE_FAIL},
	TR_Address(paddr, _) =>
		match mem_write_ea(paddr, 4, false, false, false) {
		MemValue(_) => {
			let result : MemoryOpResult(bool) = mem_write_value(paddr, 4, X(rs2c), false, false, false) in
			match result {
				MemValue(true) =>{
				match translateAddr(vaddr+4, Write(Data)) {
				TR_Failure(e, _) => {handle_mem_exception(vaddr+4, e); RETIRE_FAIL},
				TR_Address(paddr_4, _) =>
					match mem_write_ea(paddr_4, 4, false, false, false) {
						MemValue(_) => {
							let value:xlenbits = if  rs2c == zeros() then zeros() else X(rs2c+1) in
							let result1 : MemoryOpResult(bool) = mem_write_value(paddr_4, 4, value, false, false, false) in
							match result1 {
								MemValue(true) => {RETIRE_SUCCESS},
								MemValue(false) => {internal_error(__FILE__, __LINE__, "c.sdsp failed")},
								MemException(e) => {handle_mem_exception(vaddr+4, e); RETIRE_FAIL},
							}
					},
				MemException(e) => {handle_mem_exception(vaddr, e); RETIRE_FAIL},
				}
			}
			},
			MemValue(false) => {internal_error(__FILE__, __LINE__, "c.sdsp failed")},
			MemException(e) => {handle_mem_exception(vaddr+4, e); RETIRE_FAIL},
			}
		},
		MemException(e) => {handle_mem_exception(vaddr, e); RETIRE_FAIL},
		},
	}
}

mapping clause assembly = ZCLSD_C_SDSP(imm, rs2c)
	if extensionEnabled(Ext_Zclsd) & extensionEnabled(Ext_Zca) & extensionEnabled(Ext_Zilsd) & xlen == 32
<-> "c.sdsp" ^ spc() ^ reg_name(rs2c) ^ sep() ^ hex_bits_9(imm @ 0b000)
	if extensionEnabled(Ext_Zclsd) & extensionEnabled(Ext_Zca) & extensionEnabled(Ext_Zilsd) & xlen == 32
