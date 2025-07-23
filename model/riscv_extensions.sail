/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

scattered enum extension

// Name of extension.  The current primary consumer of these names is
// the device tree support, which uses lower case.  Since the ISA
// naming strings are case-insensitive anyway, the names are lowercase.
val extensionName : extension <-> string
scattered mapping extensionName

// Function used to determine if an extension is supported in the current configuration.
val hartSupports : extension -> bool
scattered function hartSupports

// Function used to determine if an extension is currently enabled in the model.
// This means an extension is supported, *and* any necessary bits are set in the
// relevant CSRs (misa, mstatus, etc.) to enable its use. It is possible for some
// extensions to be supported in hardware, but temporarily disabled via a CSR, in
// which case this function should return false.
// Note: when adding a new extension, adjust the associated termination measure
// in the file riscv_terminiation.sail, as explained in the comment in
// that file.
val currentlyEnabled : extension -> bool
scattered function currentlyEnabled

// Note, these are sorted according to the canonical ordering vaguely described
// in the `Subset Naming Convention` section of the unprivileged spec.

// Integer Multiplication and Division; not Machine!
enum clause extension = Ext_M
mapping clause extensionName = Ext_M <-> "m"
function clause hartSupports(Ext_M) = config extensions.M.supported
// Atomic Instructions
enum clause extension = Ext_A
mapping clause extensionName = Ext_A <-> "a"
function clause hartSupports(Ext_A) = config extensions.A.supported
// Single-Precision Floating-Point
enum clause extension = Ext_F
mapping clause extensionName = Ext_F <-> "f"
function clause hartSupports(Ext_F) = config extensions.F.supported
// Double-Precision Floating-Point
// TODO: Ideally we'd use `config extensions.D.supported` here but it doesn't
// work due to https://github.com/rems-project/sail/issues/1255
enum clause extension = Ext_D
mapping clause extensionName = Ext_D <-> "d"
function clause hartSupports(Ext_D) = constraint(ext_d_supported) & hartSupports(Ext_F)
// Bit Manipulation
enum clause extension = Ext_B
mapping clause extensionName = Ext_B <-> "b"
function clause hartSupports(Ext_B) = config extensions.B.supported
// Vector Operations
enum clause extension = Ext_V
mapping clause extensionName = Ext_V <-> "v"
function clause hartSupports(Ext_V) = config extensions.V.supported
// Supervisor
enum clause extension = Ext_S
mapping clause extensionName = Ext_S <-> "s"
function clause hartSupports(Ext_S) = config extensions.S.supported
// User
enum clause extension = Ext_U
mapping clause extensionName = Ext_U <-> "u"
function clause hartSupports(Ext_U) = config extensions.U.supported
// Hypervisor
enum clause extension = Ext_H
mapping clause extensionName = Ext_H <-> "h"
function clause hartSupports(Ext_H) = false

// Cache-Block Management Instructions
enum clause extension = Ext_Zicbom
mapping clause extensionName = Ext_Zicbom <-> "zicbom"
function clause hartSupports(Ext_Zicbom) = config extensions.Zicbom.supported
// Cache-Block Zero Instructions
enum clause extension = Ext_Zicboz
mapping clause extensionName = Ext_Zicboz <-> "zicboz"
function clause hartSupports(Ext_Zicboz) = config extensions.Zicboz.supported
// Base Counters and Timers
enum clause extension = Ext_Zicntr
mapping clause extensionName = Ext_Zicntr <-> "zicntr"
function clause hartSupports(Ext_Zicntr) = config extensions.Zicntr.supported
// Integer Conditional Operations
enum clause extension = Ext_Zicond
mapping clause extensionName = Ext_Zicond <-> "zicond"
function clause hartSupports(Ext_Zicond) = config extensions.Zicond.supported
// Extension for Control and Status Register (CSR) Instructions
enum clause extension = Ext_Zicsr
mapping clause extensionName = Ext_Zicsr <-> "zicsr"
function clause hartSupports(Ext_Zicsr) = config extensions.Zicsr.supported
// Instruction-Fetch Fence
enum clause extension = Ext_Zifencei
mapping clause extensionName = Ext_Zifencei <-> "zifencei"
function clause hartSupports(Ext_Zifencei) = config extensions.Zifencei.supported
// Hardware Performance Counters
enum clause extension = Ext_Zihpm
mapping clause extensionName = Ext_Zihpm <-> "zihpm"
function clause hartSupports(Ext_Zihpm) = config extensions.Zihpm.supported
// May-Be-Operations
enum clause extension = Ext_Zimop
mapping clause extensionName = Ext_Zimop <-> "zimop"
function clause hartSupports(Ext_Zimop) = config extensions.Zimop.supported

// Multiplication and Division: Multiplication only
enum clause extension = Ext_Zmmul
mapping clause extensionName = Ext_Zmmul <-> "zmmul"
function clause hartSupports(Ext_Zmmul) = config extensions.Zmmul.supported

// Atomic Memory Operations
enum clause extension = Ext_Zaamo
mapping clause extensionName = Ext_Zaamo <-> "zaamo"
function clause hartSupports(Ext_Zaamo) = config extensions.Zaamo.supported
// Byte and Halfword Atomic Memory Operations
enum clause extension = Ext_Zabha
mapping clause extensionName = Ext_Zabha <-> "zabha"
function clause hartSupports(Ext_Zabha) = config extensions.Zabha.supported
// Atomic Compare-and-Swap (CAS) Instructions
enum clause extension = Ext_Zacas
mapping clause extensionName = Ext_Zacas <-> "zacas"
function clause hartSupports(Ext_Zacas) = config extensions.Zacas.supported
// Load-Reserved/Store-Conditional Instructions
enum clause extension = Ext_Zalrsc
mapping clause extensionName = Ext_Zalrsc <-> "zalrsc"
function clause hartSupports(Ext_Zalrsc) = config extensions.Zalrsc.supported
// Wait-On-Reservation-Set
enum clause extension = Ext_Zawrs
mapping clause extensionName = Ext_Zawrs <-> "zawrs"
function clause hartSupports(Ext_Zawrs) = config extensions.Zawrs.supported

// Additional Floating-Point Instructions
enum clause extension = Ext_Zfa
mapping clause extensionName = Ext_Zfa <-> "zfa"
function clause hartSupports(Ext_Zfa) = config extensions.Zfa.supported
// Half-Precision Floating-Point
enum clause extension = Ext_Zfh
mapping clause extensionName = Ext_Zfh <-> "zfh"
function clause hartSupports(Ext_Zfh) = config extensions.Zfh.supported
// Minimal Half-Precision Floating-Point
enum clause extension = Ext_Zfhmin
mapping clause extensionName = Ext_Zfhmin <-> "zfhmin"
function clause hartSupports(Ext_Zfhmin) = config extensions.Zfhmin.supported
// Floating-Point in Integer Registers (single precision)
enum clause extension = Ext_Zfinx
mapping clause extensionName = Ext_Zfinx <-> "zfinx"
function clause hartSupports(Ext_Zfinx) = config extensions.Zfinx.supported

// Floating-Point in Integer Registers (double precision)
enum clause extension = Ext_Zdinx
mapping clause extensionName = Ext_Zdinx <-> "zdinx"
function clause hartSupports(Ext_Zdinx) = config extensions.Zfinx.supported // TODO: Separate Zfinx and Zdinx supported flags

// Code Size Reduction: compressed instructions excluding floating point loads and stores
enum clause extension = Ext_Zca
mapping clause extensionName = Ext_Zca <-> "zca"
function clause hartSupports(Ext_Zca) = config extensions.Zca.supported
// Code Size Reduction: additional 16-bit aliases
enum clause extension = Ext_Zcb
mapping clause extensionName = Ext_Zcb <-> "zcb"
function clause hartSupports(Ext_Zcb) = config extensions.Zcb.supported
// Code Size Reduction: compressed double precision floating point loads and stores
enum clause extension = Ext_Zcd
mapping clause extensionName = Ext_Zcd <-> "zcd"
function clause hartSupports(Ext_Zcd) = config extensions.Zcd.supported
// Code Size Reduction: compressed single precision floating point loads and stores
enum clause extension = Ext_Zcf
mapping clause extensionName = Ext_Zcf <-> "zcf"
function clause hartSupports(Ext_Zcf) = config extensions.Zcf.supported : bool & (xlen == 32)
// Compressed May-Be-Operations
enum clause extension = Ext_Zcmop
mapping clause extensionName = Ext_Zcmop <-> "zcmop"
function clause hartSupports(Ext_Zcmop) = config extensions.Zcmop.supported
// Compressed Instructions
// C is supported if all of the following are true:
//   - Zca is supported
//   - Zcf is supported if F is supported (on rv32)
//   - Zcd is supported if D is supported
enum clause extension = Ext_C
mapping clause extensionName = Ext_C <-> "c"
function clause hartSupports(Ext_C) = hartSupports(Ext_Zca) & (hartSupports(Ext_Zcf) | not(hartSupports(Ext_F)) | xlen != 32) & (hartSupports(Ext_Zcd) | not(hartSupports(Ext_D)))

// Bit Manipulation: Address generation
enum clause extension = Ext_Zba
mapping clause extensionName = Ext_Zba <-> "zba"
function clause hartSupports(Ext_Zba) = config extensions.Zba.supported
// Bit Manipulation: Basic bit-manipulation
enum clause extension = Ext_Zbb
mapping clause extensionName = Ext_Zbb <-> "zbb"
function clause hartSupports(Ext_Zbb) = config extensions.Zbb.supported
// Bit Manipulation: Carry-less multiplication
enum clause extension = Ext_Zbc
mapping clause extensionName = Ext_Zbc <-> "zbc"
function clause hartSupports(Ext_Zbc) = config extensions.Zbc.supported
// Bit Manipulation: Bit-manipulation for Cryptography
enum clause extension = Ext_Zbkb
mapping clause extensionName = Ext_Zbkb <-> "zbkb"
function clause hartSupports(Ext_Zbkb) = config extensions.Zbkb.supported
// Bit Manipulation: Carry-less multiplication for Cryptography
enum clause extension = Ext_Zbkc
mapping clause extensionName = Ext_Zbkc <-> "zbkc"
function clause hartSupports(Ext_Zbkc) = config extensions.Zbkc.supported
// Bit Manipulation: Crossbar permutations
enum clause extension = Ext_Zbkx
mapping clause extensionName = Ext_Zbkx <-> "zbkx"
function clause hartSupports(Ext_Zbkx) = config extensions.Zbkx.supported
// Bit Manipulation: Single-bit instructions
enum clause extension = Ext_Zbs
mapping clause extensionName = Ext_Zbs <-> "zbs"
function clause hartSupports(Ext_Zbs) = config extensions.Zbs.supported

// Scalar & Entropy Source Instructions: NIST Suite: AES Decryption
enum clause extension = Ext_Zknd
mapping clause extensionName = Ext_Zknd <-> "zknd"
function clause hartSupports(Ext_Zknd) = config extensions.Zknd.supported
// Scalar & Entropy Source Instructions: NIST Suite: AES Encryption
enum clause extension = Ext_Zkne
mapping clause extensionName = Ext_Zkne <-> "zkne"
function clause hartSupports(Ext_Zkne) = config extensions.Zkne.supported
// Scalar & Entropy Source Instructions: NIST Suite: Hash Function Instructions
enum clause extension = Ext_Zknh
mapping clause extensionName = Ext_Zknh <-> "zknh"
function clause hartSupports(Ext_Zknh) = config extensions.Zknh.supported
// Scalar & Entropy Source Instructions: Entropy Source Extension
enum clause extension = Ext_Zkr
mapping clause extensionName = Ext_Zkr <-> "zkr"
function clause hartSupports(Ext_Zkr) = config extensions.Zkr.supported
// Scalar & Entropy Source Instructions: ShangMi Suite: SM4 Block Cipher Instructions
enum clause extension = Ext_Zksed
mapping clause extensionName = Ext_Zksed <-> "zksed"
function clause hartSupports(Ext_Zksed) = config extensions.Zksed.supported
// Scalar & Entropy Source Instructions: ShangMi Suite: SM3 Hash Cipher Instructions
enum clause extension = Ext_Zksh
mapping clause extensionName = Ext_Zksh <-> "zksh"
function clause hartSupports(Ext_Zksh) = config extensions.Zksh.supported
// Data Independent Execution Latency
enum clause extension = Ext_Zkt
mapping clause extensionName = Ext_Zkt <-> "zkt"
function clause hartSupports(Ext_Zkt) = config extensions.Zkt.supported
function clause currentlyEnabled(Ext_Zkt) = hartSupports(Ext_Zkt)

// Floating-Point in Integer Registers (half precision)
enum clause extension = Ext_Zhinx
mapping clause extensionName = Ext_Zhinx <-> "zhinx"
function clause hartSupports(Ext_Zhinx) = config extensions.Zhinx.supported
// Floating-Point in Integer Registers (minimal half precision)
enum clause extension = Ext_Zhinxmin
mapping clause extensionName = Ext_Zhinxmin <-> "zhinxmin"
function clause hartSupports(Ext_Zhinxmin) = config extensions.Zhinxmin.supported

// Vector Basic Bit-manipulation
enum clause extension = Ext_Zvbb
mapping clause extensionName = Ext_Zvbb <-> "zvbb"
function clause hartSupports(Ext_Zvbb) = config extensions.Zvbb.supported
// Vector Carryless Multiplication
enum clause extension = Ext_Zvbc
mapping clause extensionName = Ext_Zvbc <-> "zvbc"
function clause hartSupports(Ext_Zvbc) = config extensions.Zvbc.supported
// Vector Cryptography Bit-manipulation
enum clause extension = Ext_Zvkb
mapping clause extensionName = Ext_Zvkb <-> "zvkb"
function clause hartSupports(Ext_Zvkb) = config extensions.Zvkb.supported
// Vector GCM/GMAC
enum clause extension = Ext_Zvkg
mapping clause extensionName = Ext_Zvkg <-> "zvkg"
function clause hartSupports(Ext_Zvkg) = config extensions.Zvkg.supported
// NIST Suite: Vector AES Block Cipher
enum clause extension = Ext_Zvkned
mapping clause extensionName = Ext_Zvkned <-> "zvkned"
function clause hartSupports(Ext_Zvkned) = config extensions.Zvkned.supported
// NIST Suite: Vector SHA-2 Secure Hash (SHA-256 only)
enum clause extension = Ext_Zvknha
mapping clause extensionName = Ext_Zvknha <-> "zvknha"
function clause hartSupports(Ext_Zvknha) = config extensions.Zvknha.supported
// NIST Suite: Vector SHA-2 Secure Hash (SHA-256 and SHA-512)
enum clause extension = Ext_Zvknhb
mapping clause extensionName = Ext_Zvknhb <-> "zvknhb"
function clause hartSupports(Ext_Zvknhb) = config extensions.Zvknhb.supported
// ShangMi Suite: SM4 Block Cipher
enum clause extension = Ext_Zvksed
mapping clause extensionName = Ext_Zvksed <-> "zvksed"
function clause hartSupports(Ext_Zvksed) = config extensions.Zvksed.supported
// ShangMi Suite: SM3 Secure Hash
enum clause extension = Ext_Zvksh
mapping clause extensionName = Ext_Zvksh <-> "zvksh"
function clause hartSupports(Ext_Zvksh) = config extensions.Zvksh.supported
// Vector Data Independent Execution Latency
enum clause extension = Ext_Zvkt
mapping clause extensionName = Ext_Zvkt <-> "zvkt"
function clause hartSupports(Ext_Zvkt) = config extensions.Zvkt.supported
function clause currentlyEnabled(Ext_Zvkt) = hartSupports(Ext_Zvkt)
// The following extensions are superset/shorthand extensions. They cannot be
// directly configured in the config file and are automatically supported when
// all their required subset extensions are supported.
enum clause extension = Ext_Zvkn
mapping clause extensionName = Ext_Zvkn <-> "zvkn"
function clause hartSupports(Ext_Zvkn) =
  hartSupports(Ext_Zvkned) &
  hartSupports(Ext_Zvknhb) &
  hartSupports(Ext_Zvkb)   &
  hartSupports(Ext_Zvkt)
function clause currentlyEnabled(Ext_Zvkn) = hartSupports(Ext_Zvkn)
// NIST Algorithm Suite with carryless multiply
enum clause extension = Ext_Zvknc
mapping clause extensionName = Ext_Zvknc <-> "zvknc"
function clause hartSupports(Ext_Zvknc) = hartSupports(Ext_Zvkn) & hartSupports(Ext_Zvbc)
function clause currentlyEnabled(Ext_Zvknc) = hartSupports(Ext_Zvknc)
// NIST Algorithm Suite with GCM
enum clause extension = Ext_Zvkng
mapping clause extensionName = Ext_Zvkng <-> "zvkng"
function clause hartSupports(Ext_Zvkng) = hartSupports(Ext_Zvkn) & hartSupports(Ext_Zvkg)
function clause currentlyEnabled(Ext_Zvkng) = hartSupports(Ext_Zvkng)
// ShangMi Algorithm Suite
enum clause extension = Ext_Zvks
mapping clause extensionName = Ext_Zvks <-> "zvks"
function clause hartSupports(Ext_Zvks) =
  hartSupports(Ext_Zvksed) &
  hartSupports(Ext_Zvksh)  &
  hartSupports(Ext_Zvkb)   &
  hartSupports(Ext_Zvkt)
function clause currentlyEnabled(Ext_Zvks) = hartSupports(Ext_Zvks)
// ShangMi Algorithm Suite with carryless multiplication
enum clause extension = Ext_Zvksc
mapping clause extensionName = Ext_Zvksc <-> "zvksc"
function clause hartSupports(Ext_Zvksc) = hartSupports(Ext_Zvks) & hartSupports(Ext_Zvbc)
function clause currentlyEnabled(Ext_Zvksc) = hartSupports(Ext_Zvksc)
// ShangMi Algorithm Suite with GCM
enum clause extension = Ext_Zvksg
mapping clause extensionName = Ext_Zvksg <-> "zvksg"
function clause hartSupports(Ext_Zvksg) = hartSupports(Ext_Zvks) & hartSupports(Ext_Zvkg)
function clause currentlyEnabled(Ext_Zvksg) = hartSupports(Ext_Zvksg)

// Count Overflow and Mode-Based Filtering
enum clause extension = Ext_Sscofpmf
mapping clause extensionName = Ext_Sscofpmf <-> "sscofpmf"
function clause hartSupports(Ext_Sscofpmf) = config extensions.Sscofpmf.supported
// Supervisor-mode Timer Interrupts
enum clause extension = Ext_Sstc
mapping clause extensionName = Ext_Sstc <-> "sstc"
function clause hartSupports(Ext_Sstc) = config extensions.Sstc.supported
// Fine-Grained Address-Translation Cache Invalidation
enum clause extension = Ext_Svinval
mapping clause extensionName = Ext_Svinval <-> "svinval"
function clause hartSupports(Ext_Svinval) = config extensions.Svinval.supported
// NAPOT Translation Contiguity
enum clause extension = Ext_Svnapot
mapping clause extensionName = Ext_Svnapot <-> "svnapot"
function clause hartSupports(Ext_Svnapot) = false // Not supported yet
// Page-Based Memory Types
enum clause extension = Ext_Svpbmt
mapping clause extensionName = Ext_Svpbmt <-> "svpbmt"
function clause hartSupports(Ext_Svpbmt) = false // Not supported yet

// Supervisor-Level Address Translation Modes
enum clause extension = Ext_Svbare
mapping clause extensionName = Ext_Svbare <-> "svbare"
function clause hartSupports(Ext_Svbare) = config extensions.Svbare.supported
enum clause extension = Ext_Sv32
mapping clause extensionName = Ext_Sv32 <-> "sv32"
function clause hartSupports(Ext_Sv32) = config extensions.Sv32.supported : bool & (xlen == 32)
enum clause extension = Ext_Sv39
mapping clause extensionName = Ext_Sv39 <-> "sv39"
function clause hartSupports(Ext_Sv39) = config extensions.Sv39.supported : bool & (xlen == 64)
enum clause extension = Ext_Sv48
mapping clause extensionName = Ext_Sv48 <-> "sv48"
function clause hartSupports(Ext_Sv48) = config extensions.Sv48.supported : bool & (xlen == 64)
enum clause extension = Ext_Sv57
mapping clause extensionName = Ext_Sv57 <-> "sv57"
function clause hartSupports(Ext_Sv57) = config extensions.Sv57.supported : bool & (xlen == 64)

// Cycle and Instret Privilege Mode Filtering
enum clause extension = Ext_Smcntrpmf
mapping clause extensionName = Ext_Smcntrpmf <-> "smcntrpmf"
function clause hartSupports(Ext_Smcntrpmf) = config extensions.Smcntrpmf.supported

let extensions_ordered_for_isa_string = [
  // Single letter extensions.
  Ext_M,
  Ext_A,
  Ext_F,
  Ext_D,
  // Ext_G,
  // Ext_Q,
  Ext_C,
  Ext_B,
  // Ext_P,
  Ext_V,
  Ext_H,
  // S and U are not valid extensions in the device-tree, whereas H is.

  // Z extensions, ordered by category and then alphabetically.
  // Zi
  Ext_Zicbom,
  Ext_Zicboz,
  Ext_Zicntr,
  Ext_Zicond,
  Ext_Zicsr,
  Ext_Zifencei,
  Ext_Zihpm,
  Ext_Zimop,

  // Zm
  Ext_Zmmul,

  // Za
  Ext_Zaamo,
  Ext_Zabha,
  Ext_Zacas,
  Ext_Zalrsc,
  Ext_Zawrs,

  // Zf, Zd, and Zq
  Ext_Zfa,
  Ext_Zfh,
  Ext_Zfhmin,
  Ext_Zfinx,
  Ext_Zdinx,
  Ext_Zhinx,
  Ext_Zhinxmin,

  // Zc
  Ext_Zca,
  Ext_Zcb,
  Ext_Zcd,
  Ext_Zcf,
  Ext_Zcmop,

  // Zb
  Ext_Zba,
  Ext_Zbb,
  Ext_Zbc,
  Ext_Zbkb,
  Ext_Zbkc,
  Ext_Zbkx,
  Ext_Zbs,

  // Zk
  Ext_Zknd,
  Ext_Zkne,
  Ext_Zknh,
  Ext_Zkr,
  Ext_Zksed,
  Ext_Zksh,
  Ext_Zkt,

  // Zv
  Ext_Zvbb,
  Ext_Zvbc,
  Ext_Zvkb,
  Ext_Zvkg,
  Ext_Zvkn,
  Ext_Zvknc,
  Ext_Zvkned,
  Ext_Zvkng,
  Ext_Zvknha,
  Ext_Zvknhb,
  Ext_Zvks,
  Ext_Zvksc,
  Ext_Zvksed,
  Ext_Zvksg,
  Ext_Zvksh,
  Ext_Zvkt,

  // Supervisor extensions, ordered alphabetically.
  Ext_Sscofpmf,
  Ext_Sstc,
  // Ext_Svade,
  // Ext_Svadu,
  Ext_Svinval,
  Ext_Svnapot,
  Ext_Svpbmt,

  // Hypervisor extensions, ordered alphabetically.

  // Machine mode extensions, ordered alphabetically.
  Ext_Smcntrpmf,
]
