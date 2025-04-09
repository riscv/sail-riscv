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
// Single-Precision Floating-Point
enum clause extension = Ext_F
function clause hartSupports(Ext_F) = config extensions.FD.supported
// Double-Precision Floating-Point
enum clause extension = Ext_D
function clause hartSupports(Ext_D) = config extensions.FD.supported // TODO: Separate F and D supported flags
// Compressed Instructions
enum clause extension = Ext_C
function clause hartSupports(Ext_C) = config extensions.C.supported
// Bit Manipulation
enum clause extension = Ext_B
function clause hartSupports(Ext_B) = config extensions.B.supported
// Vector Operations
enum clause extension = Ext_V
function clause hartSupports(Ext_V) = config extensions.V.supported
// Supervisor
enum clause extension = Ext_S
// User
enum clause extension = Ext_U

// Cache-Block Management Instructions
enum clause extension = Ext_Zicbom
function clause hartSupports(Ext_Zicbom) = config extensions.Zicbom.supported
// Cache-Block Zero Instructions
enum clause extension = Ext_Zicboz
function clause hartSupports(Ext_Zicboz) = config extensions.Zicboz.supported
// Base Counters and Timers
enum clause extension = Ext_Zicntr
// Integer Conditional Operations
enum clause extension = Ext_Zicond
// Instruction-Fetch Fence
enum clause extension = Ext_Zifencei
// Hardware Performance Counters
enum clause extension = Ext_Zihpm
// May-Be-Operations
enum clause extension = Ext_Zimop

// Multiplication and Division: Multiplication only
enum clause extension = Ext_Zmmul

// Atomic Memory Operations
enum clause extension = Ext_Zaamo
// Byte and Halfword Atomic Memory Operations
enum clause extension = Ext_Zabha
// Load-Reserved/Store-Conditional Instructions
enum clause extension = Ext_Zalrsc

// Additional Floating-Point Instructions
enum clause extension = Ext_Zfa
// Half-Precision Floating-Point
enum clause extension = Ext_Zfh
// Minimal Half-Precision Floating-Point
enum clause extension = Ext_Zfhmin
// Floating-Point in Integer Registers (single precision)
enum clause extension = Ext_Zfinx
function clause hartSupports(Ext_Zfinx) = config extensions.Zfinx.supported

// Floating-Point in Integer Registers (double precision)
enum clause extension = Ext_Zdinx

// Code Size Reduction: compressed instructions excluding floating point loads and stores
enum clause extension = Ext_Zca
// Code Size Reduction: additional 16-bit aliases
enum clause extension = Ext_Zcb
function clause hartSupports(Ext_Zcb) = config extensions.Zcb.supported
// Code Size Reduction: compressed double precision floating point loads and stores
enum clause extension = Ext_Zcd
// Code Size Reduction: compressed single precision floating point loads and stores
enum clause extension = Ext_Zcf
// Compressed May-Be-Operations
enum clause extension = Ext_Zcmop

// Bit Manipulation: Address generation
enum clause extension = Ext_Zba
// Bit Manipulation: Basic bit-manipulation
enum clause extension = Ext_Zbb
// Bit Manipulation: Carry-less multiplication
enum clause extension = Ext_Zbc
// Bit Manipulation: Bit-manipulation for Cryptography
enum clause extension = Ext_Zbkb
// Bit Manipulation: Carry-less multiplication for Cryptography
enum clause extension = Ext_Zbkc
// Bit Manipulation: Crossbar permutations
enum clause extension = Ext_Zbkx
// Bit Manipulation: Single-bit instructions
enum clause extension = Ext_Zbs

// Scalar & Entropy Source Instructions: NIST Suite: AES Decryption
enum clause extension = Ext_Zknd
// Scalar & Entropy Source Instructions: NIST Suite: AES Encryption
enum clause extension = Ext_Zkne
// Scalar & Entropy Source Instructions: NIST Suite: Hash Function Instructions
enum clause extension = Ext_Zknh
// Scalar & Entropy Source Instructions: Entropy Source Extension
enum clause extension = Ext_Zkr
// Scalar & Entropy Source Instructions: ShangMi Suite: SM4 Block Cipher Instructions
enum clause extension = Ext_Zksed
// Scalar & Entropy Source Instructions: ShangMi Suite: SM3 Hash Cipher Instructions
enum clause extension = Ext_Zksh

// Floating-Point in Integer Registers (half precision)
enum clause extension = Ext_Zhinx

// Vector Basic Bit-manipulation
enum clause extension = Ext_Zvbb
// Vector Cryptography Bit-manipulation
enum clause extension = Ext_Zvkb
function clause hartSupports(Ext_Zvkb) = config extensions.Zvkb.supported
// Vector Carryless Multiplication
enum clause extension = Ext_Zvbc
function clause hartSupports(Ext_Zvbc) = config extensions.Zvbc.supported

// Count Overflow and Mode-Based Filtering
enum clause extension = Ext_Sscofpmf
// Supervisor-mode Timer Interrupts
enum clause extension = Ext_Sstc
function clause hartSupports(Ext_Sstc) = config extensions.Sstc.supported
// Fine-Grained Address-Translation Cache Invalidation
enum clause extension = Ext_Svinval
function clause hartSupports(Ext_Svinval) = config extensions.Svinval.supported
// NAPOT Translation Contiguity
enum clause extension = Ext_Svnapot
// Page-Based Memory Types
enum clause extension = Ext_Svpbmt

// Cycle and Instret Privilege Mode Filtering
enum clause extension = Ext_Smcntrpmf
