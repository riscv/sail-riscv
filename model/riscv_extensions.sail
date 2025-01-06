/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

scattered enum extension

// Note, these are sorted according to the canonical ordering vaguely described
// in the `Subset Naming Convention` section of the unprivileged spec.

// Integer Multiplication and Division; not Machine!
enum clause extension = Ext_M
// Single-Precision Floating-Point
enum clause extension = Ext_F
// Double-Precision Floating-Point
enum clause extension = Ext_D
// Compressed Instructions
enum clause extension = Ext_C
// Bit Manipulation
enum clause extension = Ext_B
// Vector Operations
enum clause extension = Ext_V
// Supervisor
enum clause extension = Ext_S
// User
enum clause extension = Ext_U

// Cache-Block Management Instructions
enum clause extension = Ext_Zicbom
// Cache-Block Zero Instructions
enum clause extension = Ext_Zicboz
// Base Counters and Timers
enum clause extension = Ext_Zicntr
// Integer Conditional Operations
enum clause extension = Ext_Zicond
// Instruction-Fetch Fence
enum clause extension = Ext_Zifencei
// Hardware Performance Counters
enum clause extension = Ext_Zihpm

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

// Floating-Point in Integer Registers (double precision)
enum clause extension = Ext_Zdinx

// Code Size Reduction: compressed instructions excluding floating point loads and stores
enum clause extension = Ext_Zca
// Code Size Reduction: additional 16-bit aliases
enum clause extension = Ext_Zcb
// Code Size Reduction: compressed double precision floating point loads and stores
enum clause extension = Ext_Zcd
// Code Size Reduction: compressed single precision floating point loads and stores
enum clause extension = Ext_Zcf

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

// Supervisor-mode Timer Interrupts
enum clause extension = Ext_Sstc
// Fine-Grained Address-Translation Cache Invalidation
enum clause extension = Ext_Svinval
