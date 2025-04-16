/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// Enum with all extensions possibly supported by the model.
scattered enum extension

// Function used to determine if an extension is supported in the current configuration.
val hartSupports : extension -> bool
scattered function hartSupports

// Function used to determine if an extension is currently enabled in the model.
// This means an extension is supported, *and* any necessary bits are set in the
// relevant CSRs (misa, mstatus, etc.) to enable its use. It is possible for some
// extensions to be supported in hardware, but temporarily disabled via a CSR, in
// which case this function should return false.
val currentlyEnabled : extension -> bool
scattered function currentlyEnabled

// Note, these are sorted according to the canonical ordering vaguely described
// in the `Subset Naming Convention` section of the unprivileged spec.

// Integer Multiplication and Division; not Machine!
enum clause extension = Ext_M
function clause hartSupports(Ext_M) = config extensions.M.supported
// Atomic Instructions
enum clause extension = Ext_A
function clause hartSupports(Ext_A) = config extensions.A.supported
// Single-Precision Floating-Point
enum clause extension = Ext_F
function clause hartSupports(Ext_F) = config extensions.FD.supported
// Double-Precision Floating-Point
enum clause extension = Ext_D
function clause hartSupports(Ext_D) = config extensions.FD.supported // TODO: Separate F and D supported flags
// Bit Manipulation
enum clause extension = Ext_B
function clause hartSupports(Ext_B) = config extensions.B.supported
// Vector Operations
enum clause extension = Ext_V
function clause hartSupports(Ext_V) = config extensions.V.supported
// Supervisor
enum clause extension = Ext_S
function clause hartSupports(Ext_S) = config extensions.S.supported
// User
enum clause extension = Ext_U
function clause hartSupports(Ext_U) = config extensions.U.supported

// Cache-Block Management Instructions
enum clause extension = Ext_Zicbom
function clause hartSupports(Ext_Zicbom) = config extensions.Zicbom.supported
// Cache-Block Zero Instructions
enum clause extension = Ext_Zicboz
function clause hartSupports(Ext_Zicboz) = config extensions.Zicboz.supported
// Base Counters and Timers
enum clause extension = Ext_Zicntr
function clause hartSupports(Ext_Zicntr) = config extensions.Zicntr.supported
// Integer Conditional Operations
enum clause extension = Ext_Zicond
function clause hartSupports(Ext_Zicond) = config extensions.Zicond.supported
// Instruction-Fetch Fence
enum clause extension = Ext_Zifencei
function clause hartSupports(Ext_Zifencei) = config extensions.Zifencei.supported
// Hardware Performance Counters
enum clause extension = Ext_Zihpm
function clause hartSupports(Ext_Zihpm) = config extensions.Zihpm.supported
// May-Be-Operations
enum clause extension = Ext_Zimop
function clause hartSupports(Ext_Zimop) = config extensions.Zimop.supported

// Multiplication and Division: Multiplication only
enum clause extension = Ext_Zmmul
function clause hartSupports(Ext_Zmmul) = config extensions.Zmmul.supported

// Atomic Memory Operations
enum clause extension = Ext_Zaamo
function clause hartSupports(Ext_Zaamo) = config extensions.Zaamo.supported
// Byte and Halfword Atomic Memory Operations
enum clause extension = Ext_Zabha
function clause hartSupports(Ext_Zabha) = config extensions.Zabha.supported
// Load-Reserved/Store-Conditional Instructions
enum clause extension = Ext_Zalrsc
function clause hartSupports(Ext_Zalrsc) = config extensions.Zalrsc.supported

// Additional Floating-Point Instructions
enum clause extension = Ext_Zfa
function clause hartSupports(Ext_Zfa) = config extensions.Zfa.supported
// Half-Precision Floating-Point
enum clause extension = Ext_Zfh
function clause hartSupports(Ext_Zfh) = config extensions.Zfh.supported
// Minimal Half-Precision Floating-Point
enum clause extension = Ext_Zfhmin
function clause hartSupports(Ext_Zfhmin) = config extensions.Zfhmin.supported
// Floating-Point in Integer Registers (single precision)
enum clause extension = Ext_Zfinx
function clause hartSupports(Ext_Zfinx) = config extensions.Zfinx.supported

// Floating-Point in Integer Registers (double precision)
enum clause extension = Ext_Zdinx
function clause hartSupports(Ext_Zdinx) = config extensions.Zfinx.supported // TODO: Separate Zfinx and Zdinx supported flags

// Code Size Reduction: compressed instructions excluding floating point loads and stores
enum clause extension = Ext_Zca
function clause hartSupports(Ext_Zca) = config extensions.Zca.supported
// Code Size Reduction: additional 16-bit aliases
enum clause extension = Ext_Zcb
function clause hartSupports(Ext_Zcb) = config extensions.Zcb.supported
// Code Size Reduction: compressed double precision floating point loads and stores
enum clause extension = Ext_Zcd
function clause hartSupports(Ext_Zcd) = config extensions.Zcd.supported
// Code Size Reduction: compressed single precision floating point loads and stores
enum clause extension = Ext_Zcf
function clause hartSupports(Ext_Zcf) = config extensions.Zcf.supported : bool & (xlen == 32)
// Compressed May-Be-Operations
enum clause extension = Ext_Zcmop
function clause hartSupports(Ext_Zcmop) = config extensions.Zcmop.supported
// Compressed Instructions
// C is supported if all of the following are true:
//   - Zca is supported
//   - Zcf is supported if F is supported (on rv32)
//   - Zcd is supported if D is supported
enum clause extension = Ext_C
function clause hartSupports(Ext_C) = hartSupports(Ext_Zca) & (hartSupports(Ext_Zcf) | not(hartSupports(Ext_F)) | xlen != 32) & (hartSupports(Ext_Zcd) | not(hartSupports(Ext_D)))

// Bit Manipulation: Address generation
enum clause extension = Ext_Zba
function clause hartSupports(Ext_Zba) = config extensions.Zba.supported
// Bit Manipulation: Basic bit-manipulation
enum clause extension = Ext_Zbb
function clause hartSupports(Ext_Zbb) = config extensions.Zbb.supported
// Bit Manipulation: Carry-less multiplication
enum clause extension = Ext_Zbc
function clause hartSupports(Ext_Zbc) = config extensions.Zbc.supported
// Bit Manipulation: Bit-manipulation for Cryptography
enum clause extension = Ext_Zbkb
function clause hartSupports(Ext_Zbkb) = config extensions.Zbkb.supported
// Bit Manipulation: Carry-less multiplication for Cryptography
enum clause extension = Ext_Zbkc
function clause hartSupports(Ext_Zbkc) = config extensions.Zbkc.supported
// Bit Manipulation: Crossbar permutations
enum clause extension = Ext_Zbkx
function clause hartSupports(Ext_Zbkx) = config extensions.Zbkx.supported
// Bit Manipulation: Single-bit instructions
enum clause extension = Ext_Zbs
function clause hartSupports(Ext_Zbs) = config extensions.Zbs.supported

// Scalar & Entropy Source Instructions: NIST Suite: AES Decryption
enum clause extension = Ext_Zknd
function clause hartSupports(Ext_Zknd) = config extensions.Zknd.supported
// Scalar & Entropy Source Instructions: NIST Suite: AES Encryption
enum clause extension = Ext_Zkne
function clause hartSupports(Ext_Zkne) = config extensions.Zkne.supported
// Scalar & Entropy Source Instructions: NIST Suite: Hash Function Instructions
enum clause extension = Ext_Zknh
function clause hartSupports(Ext_Zknh) = config extensions.Zknh.supported
// Scalar & Entropy Source Instructions: Entropy Source Extension
enum clause extension = Ext_Zkr
function clause hartSupports(Ext_Zkr) = config extensions.Zkr.supported
// Scalar & Entropy Source Instructions: ShangMi Suite: SM4 Block Cipher Instructions
enum clause extension = Ext_Zksed
function clause hartSupports(Ext_Zksed) = config extensions.Zksed.supported
// Scalar & Entropy Source Instructions: ShangMi Suite: SM3 Hash Cipher Instructions
enum clause extension = Ext_Zksh
function clause hartSupports(Ext_Zksh) = config extensions.Zksh.supported

// Floating-Point in Integer Registers (half precision)
enum clause extension = Ext_Zhinx
function clause hartSupports(Ext_Zhinx) = config extensions.Zhinx.supported

// Vector Basic Bit-manipulation
enum clause extension = Ext_Zvbb
function clause hartSupports(Ext_Zvbb) = config extensions.Zvbb.supported
// Vector Cryptography Bit-manipulation
enum clause extension = Ext_Zvkb
function clause hartSupports(Ext_Zvkb) = config extensions.Zvkb.supported
// Vector Carryless Multiplication
enum clause extension = Ext_Zvbc
function clause hartSupports(Ext_Zvbc) = config extensions.Zvbc.supported

// Count Overflow and Mode-Based Filtering
enum clause extension = Ext_Sscofpmf
function clause hartSupports(Ext_Sscofpmf) = config extensions.Sscofpmf.supported
// Supervisor-mode view of the state-enable extension
enum clause extension = Ext_Ssstateen
function clause hartSupports(Ext_Ssstateen) = config extensions.Ssstateen.supported
// Supervisor-mode Timer Interrupts
enum clause extension = Ext_Sstc
function clause hartSupports(Ext_Sstc) = config extensions.Sstc.supported
// Fine-Grained Address-Translation Cache Invalidation
enum clause extension = Ext_Svinval
function clause hartSupports(Ext_Svinval) = config extensions.Svinval.supported
// NAPOT Translation Contiguity
enum clause extension = Ext_Svnapot
function clause hartSupports(Ext_Svnapot) = false // Not supported yet
// Page-Based Memory Types
enum clause extension = Ext_Svpbmt
function clause hartSupports(Ext_Svpbmt) = false // Not supported yet

// Cycle and Instret Privilege Mode Filtering
enum clause extension = Ext_Smcntrpmf
function clause hartSupports(Ext_Smcntrpmf) = config extensions.Smcntrpmf.supported
// Machine-mode view of the state-enable extension
enum clause extension = Ext_Smstateen
function clause hartSupports(Ext_Smstateen) = config extensions.Smstateen.supported
