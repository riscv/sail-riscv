// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// These functions define the primitives for physical memory access.
// They depend on the XLEN of the architecture.
//
// They also depend on the type of metadata that is read and written
// to physical memory.  For models that do not require this metadata,
// a unit type can be used.

$define CONCURRENCY_INTERFACE_V2
$include <concurrency_interface.sail>

enum write_kind = {
  Write_plain,
  // Note: Write_RISCV_release and Write_RISCV_strong_release are currently
  // unused but removing them may break Isla, and they might be used in future
  // by Zalasr.
  Write_RISCV_release,
  Write_RISCV_strong_release,
  Write_RISCV_conditional,
  Write_RISCV_conditional_release,
  Write_RISCV_conditional_strong_release,
}

enum read_kind = {
  Read_plain,
  Read_ifetch,
  // Note: Read_RISCV_acquire and Read_RISCV_strong_acquire are currently
  // unused but removing them may break Isla, and they might be used in future
  // by Zalasr.
  Read_RISCV_acquire,
  Read_RISCV_strong_acquire,
  Read_RISCV_reserved,
  Read_RISCV_reserved_acquire,
  Read_RISCV_reserved_strong_acquire,
}

union access_kind = {
  AK_Write : write_kind,
  AK_Read : read_kind,
}

// TODO: We currently do not get enough information here to distinguish explicit accesses,
// translation accesses, and atomic accesses.
function ak_is_explicit(_acc : access_kind) -> bool = true
function ak_is_ifetch(acc : access_kind) -> bool = acc == AK_Read(Read_ifetch)
function ak_is_ttw(_acc : access_kind) -> bool = false
function ak_is_relaxed(acc : access_kind) -> bool =
  match acc {
    AK_Write(Write_plain) => true,
    AK_Write(Write_RISCV_conditional) => true,
    AK_Read(Read_plain) => true,
    AK_Read(Read_RISCV_reserved) => true,
    _ => false,
  }
function ak_is_rel_acq_rcsc(acc : access_kind) -> bool =
  match acc {
    AK_Write(Write_RISCV_strong_release) => true,
    AK_Write(Write_RISCV_conditional_strong_release) => true,
    AK_Read(Read_RISCV_strong_acquire) => true,
    AK_Read(Read_RISCV_reserved_strong_acquire) => true,
    _ => false,
  }
function ak_is_rel_acq_rcpc(acc : access_kind) -> bool =
  match acc {
    AK_Write(Write_RISCV_release) => true,
    AK_Write(Write_RISCV_conditional_release) => true,
    AK_Read(Read_RISCV_acquire) => true,
    AK_Read(Read_RISCV_reserved_acquire) => true,
    _ => false,
  }
function ak_is_standalone(acc : access_kind) -> bool =
  match acc {
    AK_Write(Write_plain) => true,
    AK_Write(Write_RISCV_release) => true,
    AK_Write(Write_RISCV_strong_release) => true,
    AK_Read(Read_plain) => true,
    AK_Read(Read_RISCV_acquire) => true,
    AK_Read(Read_RISCV_strong_acquire) => true,
    _ => false,
  }
function ak_is_exclusive(acc : access_kind) -> bool =
  match acc {
    AK_Write(Write_RISCV_conditional) => true,
    AK_Write(Write_RISCV_conditional_release) => true,
    AK_Write(Write_RISCV_conditional_strong_release) => true,
    AK_Read(Read_RISCV_reserved) => true,
    AK_Read(Read_RISCV_reserved_acquire) => true,
    AK_Read(Read_RISCV_reserved_strong_acquire) => true,
    _ => false,
  }
function ak_is_atomic_rmw(_acc : access_kind) -> bool = false

enum barrier_kind = {
  Barrier_RISCV_rw_rw,
  Barrier_RISCV_r_rw,
  Barrier_RISCV_r_r,
  Barrier_RISCV_rw_w,
  Barrier_RISCV_w_w,
  Barrier_RISCV_w_rw,
  Barrier_RISCV_rw_r,
  Barrier_RISCV_r_w,
  Barrier_RISCV_w_r,
  Barrier_RISCV_tso,
  Barrier_RISCV_i,
}

instantiation sail_mem_write with
  'addr_size = physaddrbits_len,
  'addr_space = unit,
  'mem_acc = access_kind,
  'CHERI = false,    // TODO: Provide a way to override this.
  'cap_size_log = 0, // TODO: Provide a way to override this.
  // We don't have a defined type for external aborts, so just use unit here.
  'abort = unit,
  mem_acc_is_explicit = ak_is_explicit,
  mem_acc_is_ifetch = ak_is_ifetch,
  mem_acc_is_ttw = ak_is_ttw,
  mem_acc_is_relaxed = ak_is_relaxed,
  mem_acc_is_rel_acq_rcpc = ak_is_rel_acq_rcpc,
  mem_acc_is_rel_acq_rcsc = ak_is_rel_acq_rcsc,
  mem_acc_is_standalone = ak_is_standalone,
  mem_acc_is_exclusive = ak_is_exclusive,
  mem_acc_is_atomic_rmw = ak_is_atomic_rmw

val write_ram : forall 'n, 0 < 'n <= max_mem_access. (write_kind, physaddr, int('n), bits(8 * 'n), mem_meta) -> bool

function write_ram(wk, Physaddr(addr), width, data, meta) = {
  let request : Mem_request('n, 0, physaddrbits_len, unit, access_kind) = struct {
    access_kind = match wk {
      Write_RISCV_release => internal_error(__FILE__, __LINE__, "Write_RISCV_release is unused"),
      Write_RISCV_strong_release => internal_error(__FILE__, __LINE__, "Write_RISCV_strong_release is unused"),
      _ => AK_Write(wk),
    },
    address = addr,
    address_space = (),
    size = width,
    num_tag = 0,
  };
  // Write out metadata only if the value write succeeds.
  // It is assumed for now that this write always succeeds;
  // there is currently no return value.
  // FIXME: We should convert the external API for all backends
  // (not just for Lem) to consume the value along with the
  // metadata to ensure atomicity.
  match sail_mem_write(request, to_bytes_le(data), []) {
    Ok(_) => {
      __WriteRAM_Meta(addr, width, meta);
      true
    },
    Err() => false,
  }
}

val write_ram_ea : forall 'n, 0 < 'n <= max_mem_access. (write_kind, physaddr, int('n)) -> unit
function write_ram_ea(_wk, Physaddr(_addr), _width) = ()

instantiation sail_mem_read with
  'addr_size = physaddrbits_len,
  'addr_space = unit,
  'mem_acc = access_kind,
  'CHERI = false,    // TODO: Provide a way to override this.
  'cap_size_log = 0, // TODO: Provide a way to override this.
  // We don't have a defined type for external aborts, so just use unit here.
  'abort = unit,
  mem_acc_is_explicit = ak_is_explicit,
  mem_acc_is_ifetch = ak_is_ifetch,
  mem_acc_is_ttw = ak_is_ttw,
  mem_acc_is_relaxed = ak_is_relaxed,
  mem_acc_is_rel_acq_rcpc = ak_is_rel_acq_rcpc,
  mem_acc_is_rel_acq_rcsc = ak_is_rel_acq_rcsc,
  mem_acc_is_standalone = ak_is_standalone,
  mem_acc_is_exclusive = ak_is_exclusive,
  mem_acc_is_atomic_rmw = ak_is_atomic_rmw

val read_ram : forall 'n, 0 < 'n <= max_mem_access.  (read_kind, physaddr, int('n), bool) -> (bits(8 * 'n), mem_meta)
function read_ram(rk, Physaddr(addr), width, read_meta) = {
  let meta = if read_meta then __ReadRAM_Meta(addr, width) else default_meta;
  let request : Mem_request('n, 0, physaddrbits_len, unit, access_kind) = struct {
    access_kind = match rk {
      Read_RISCV_acquire => internal_error(__FILE__, __LINE__, "Read_RISCV_acquire is unused"),
      Read_RISCV_strong_acquire => internal_error(__FILE__, __LINE__, "Read_RISCV_strong_acquire is unused"),
      _ => AK_Read(rk),
    },
    address = addr,
    address_space = (),
    size = width,
    num_tag = 0,
  };
  match sail_mem_read(request) {
    Ok((value, _)) => (from_bytes_le(value), meta),
    Err() => exit(),
  }
}

instantiation sail_barrier with 'barrier = barrier_kind

val __TraceMemoryWrite : forall 'n 'm. (int('n), bits('m), bits(8 * 'n)) -> unit
val __TraceMemoryRead  : forall 'n 'm. (int('n), bits('m), bits(8 * 'n)) -> unit
