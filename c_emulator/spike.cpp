#include <riscv/mmu.h>
#include <riscv/encoding.h>
#include <fesvr/elfloader.h>
#include "spike.h"
#include "riscv_sail.h"
#include "config_utils.h"
#include "sim_utils.h"

static void check_supported_mem_region(const char *name, uint64_t base,
                                       uint64_t size)
{
  // See spike.cc::{parse_mem_layout, create_mem_region}.
  // Spike realigns memory regions to page boundaries; the Sail model doesn't.
  // If the configured memory regions are not suitably aligned, lockstep
  // execution will most likely fail, so error out.
  auto base_align = base % PGSIZE;
  auto size_align = size % PGSIZE;
  if (base_align != 0 || size_align != 0) {
    fprintf(stderr,
            "The %s memory region is not aligned to a %ld boundary (base "
            "misalign=%ld, size misalign=%ld); cannot configure Spike "
            "in a compatible way.\n",
            name, static_cast<long>(PGSIZE / 1024), base_align, size_align);
    exit(1);
  } else if (!mem_cfg_t::check_if_supported(base, size)) {
    fprintf(stderr,
            "Spike does not support the %s memory region {base = 0x%lX, size = "
            "0x%lX}.\n",
            name, base, size);
    exit(1);
  }
}

std::vector<mem_cfg_t> make_mem_layout()
{
  std::vector<mem_cfg_t> mems;

  // The current Sail config has two memory regions: ROM and RAM.
  // Only the RAM is registered here.  The ROM will be registered
  // later as it needs to be populated with the reset vector with the
  // entry address, and the entry address is available only when we
  // load the ELF file.
  uint64_t ram_base = get_config_uint64({"platform", "ram", "base"});
  uint64_t ram_size = get_config_uint64({"platform", "ram", "size"});

  check_supported_mem_region("RAM", ram_base, ram_size);
  mems.push_back(mem_cfg_t(ram_base, ram_size));

  // Spike also merges overlapping regions and eliminates any
  // contained regions.  Since the Sail configuration validation
  // ensures no overlapping memory regions, the remaining
  // configuration should be compatibile.

  return mems;
}

cfg_t init_spike_cfg()
{
  cfg_t cfg;

  assert(size(cfg.hartids) == 1);
  assert(cfg.hartids[0] == 0);

  // Spike specifies supported privilege levels as one of {"m", "mu", "msu"}.
  bool have_user = get_config_bool({"extensions", "U", "supported"});
  bool have_supervisor = get_config_bool({"extensions", "S", "supported"});
  cfg.priv = (have_user && have_supervisor) ? "msu" : (have_user ? "mu" : "m");

  char *isa = NULL;
  zgenerate_canonical_isa_string(&isa, UNIT);
  cfg.isa = isa;

  cfg.mem_layout = make_mem_layout();

  cfg.misaligned = get_config_bool({"memory", "misaligned", "supported"});

  // Spike sets PMP granularity in bytes [default 4].  The Sail config uses the
  // `G` parameter.
  uint64_t pmpgrain = get_config_uint64({"memory", "pmp", "grain"});
  cfg.pmpgranularity = 1 << (2 + pmpgrain);
  cfg.pmpregions = get_config_uint64({"memory", "pmp", "count"});

  cfg.trigger_count = 0;
  return cfg;
}

spike::spike(bool is_32bit)
    : cfg(init_spike_cfg())
    , hart(NULL)
    , sout(nullptr)
    , memif(this)
    , tohost_addr(0)
    , dtb(NULL)
    , dtb_len(0)
    , registered_reset_rom(false)
    , is_32bit(is_32bit)
    , reg_mask(is_32bit ? 0x00000000FFFFFFFFL : -1L)
    , exited(false)
    , exit_code(0)
    , verbose(false)
{

  hart
      = new processor_t(cfg.isa, cfg.priv, &cfg, this, cfg.hartids[0],
                        /* halt_on_reset */ false, /* log_file */ stdout, sout);
  harts[cfg.hartids[0]] = hart;

  // Enable logging
  hart->set_debug(true);

  // Set PMP config.
  // The model uses the PMP G parameter, while Spike needs the
  // grain where grain = 2^(G+2).
  reg_t pmp_grain = get_config_uint64({"memory", "pmp", "grain"});
  hart->set_pmp_granularity(1 << (pmp_grain + 2));
  hart->set_pmp_num(get_config_uint64({"memory", "pmp", "count"}));

  // Set mmu-type.
  if (get_config_bool({"extensions", "Svbare", "supported"})) {
    hart->set_mmu_capability(IMPL_MMU_SBARE);
  };
  if (get_config_bool({"extensions", "Sv32", "supported"})) {
    hart->set_mmu_capability(IMPL_MMU_SV32);
  };
  if (get_config_bool({"extensions", "Sv39", "supported"})) {
    hart->set_mmu_capability(IMPL_MMU_SV39);
  };
  if (get_config_bool({"extensions", "Sv48", "supported"})) {
    hart->set_mmu_capability(IMPL_MMU_SV48);
  };
  if (get_config_bool({"extensions", "Sv57", "supported"})) {
    hart->set_mmu_capability(IMPL_MMU_SV57);
  };

  // Add the (non-ROM) memory regions to the bus.
  for (const auto mem_cfg : cfg.mem_layout) {
    // If there is an initrd, it needs to be read into the right memory region
    // here.
    bus.add_device(mem_cfg.get_base(), new mem_t(mem_cfg.get_size()));
  }
  // Configure Spike's CLINT.
  {
    uint64_t clock_hz = get_config_uint64({"platform", "clock_frequency"});
    uint64_t insns_per_tick
        = get_config_uint64({"platform", "instructions_per_tick"});
    clint = std::make_shared<clint_t>(this, clock_hz / insns_per_tick, false);

    uint64_t clint_base = get_config_uint64({"platform", "clint", "base"});
    uint64_t clint_size = get_config_uint64({"platform", "clint", "size"});
    if (clint_size != clint->size()) {
      fprintf(stderr,
              "Incompatible sizes for CLINT device: model=%lX  Spike=%lX\n",
              clint_size, clint->size());
      exit(1);
    }
    bus.add_device(clint_base, clint.get());
    devices.push_back(clint);
  }

  // inherited from simif_t
  debug_mmu = new mmu_t(this, cfg.endianness, NULL, cfg.cache_blocksz);

  register_callback_if(this);
}

void spike::add_reset_rom(reg_t entry)
{
  if (registered_reset_rom)
    return;

  std::vector<char> rom = make_reset_rom(is_32bit, entry, dtb, dtb_len);
  std::shared_ptr<rom_device_t> reset_rom(new rom_device_t(rom));
  uint64_t rom_base = get_config_uint64({"platform", "reset_vector"});
  bus.add_device(rom_base, reset_rom.get());
  devices.push_back(reset_rom);
  registered_reset_rom = true;
}

spike::~spike()
{
  remove_callback_if(this);
  delete hart;
  delete debug_mmu;
}

/* simif_t API */

// This should return NULL for MMIO addresses.
char *spike::addr_to_mem(reg_t paddr)
{
  // If paddr corresponds to memory (as opposed to an I/O device),
  // Spike returns a host pointer corresponding to paddr. For these
  // purposes, only memories that include the entire base page
  // surrounding paddr are considered; smaller memories are treated as
  // I/O.
  auto desc = bus.find_device(paddr >> PGSHIFT << PGSHIFT, PGSIZE);
  if (auto mem = dynamic_cast<abstract_mem_t *>(desc.second))
    return mem->contents(paddr - desc.first);
  return NULL;
}

bool spike::mmio_load(reg_t paddr, size_t len, uint8_t *bytes)
{
  if (paddr + len < paddr)
    return false;
  return bus.load(paddr, len, bytes);
}

bool spike::mmio_store(reg_t paddr, size_t len, const uint8_t *bytes)
{
  if (paddr + len < paddr)
    return false;
  return bus.store(paddr, len, bytes);
}

// Callback for processors to let the simulation know they were reset.
void spike::proc_reset([[maybe_unused]] unsigned id)
{
  assert(id == 0);
  // Spike's processor_t calls this from its constructor, which means
  // we're still in our constructor.
}

const char *spike::get_symbol([[maybe_unused]] uint64_t paddr)
{
  return NULL;
}

/* chunked_memif_t API

   `taddr` refers to addresses in the hart memory.
 */

void spike::read_chunk(addr_t taddr, [[maybe_unused]] size_t len, void *dst)
{
  assert(len == 8);
  auto data = debug_mmu->to_target(debug_mmu->load<uint64_t>(taddr));
  memcpy(dst, &data, sizeof(data));
}

void spike::write_chunk(addr_t taddr, [[maybe_unused]] size_t len,
                        const void *src)
{
  assert(len == 8);
  target_endian<uint64_t> data;
  memcpy(&data, src, sizeof(data));
  debug_mmu->store<uint64_t>(taddr, debug_mmu->from_target(data));
}

void spike::clear_chunk(addr_t taddr, size_t len)
{
  std::vector<uint8_t> zeros(chunk_max_size(), 0);
  for (size_t pos = 0; pos < len; pos += chunk_max_size()) {
    write_chunk(taddr + pos, std::min(len - pos, chunk_max_size()),
                zeros.data());
  }
}

/* cosim_if API */

void spike::set_dtb(const unsigned char *dtb, size_t dtb_len)
{
  this->dtb = dtb;
  this->dtb_len = dtb_len;
}

// This might be called multiple times with different files.
void spike::init_elf(const char *elf_file, uint64_t expected_entry)
{
  reg_t load_offset = get_config_uint64({"platform", "ram", "base"});
  reg_t entry;

  std::map<std::string, uint64_t> elf_symbols
      = load_elf(elf_file, &memif, &entry, load_offset);
  for (auto s : elf_symbols) {
    if (addr2symbol.find(s.second) == addr2symbol.end())
      addr2symbol[s.second] = s.first;
  }
  if (elf_symbols.count("tohost") && elf_symbols.count("fromhost")) {
    tohost_addr = elf_symbols["tohost"];
  }
  if (expected_entry && (expected_entry != entry)) {
    fprintf(stderr,
            "Entry in %s is at 0x%lX but was expected to be at 0x%lX.\n",
            elf_file, entry, expected_entry);
    exit(1);
  }
  symbols.merge(elf_symbols);
  add_reset_rom(entry);
}

uint64_t spike::get_csr_unchecked(reg_t csr)
{
  auto csr_entry = hart->get_state()->csrmap.find(csr);
  assert(csr_entry != hart->get_state()->csrmap.end());
  return csr_entry->second->read();
}

bool spike::check_csr(uint64_t csr, const char *csr_name)
{
  uint64_t sail_val = zread_CSR(csr) & reg_mask;
  uint64_t spike_val = get_csr_unchecked(csr) & reg_mask;
  bool chk = sail_val == spike_val;
  if (!chk && verbose) {
    fprintf(stderr,
            "%s mismatch: Sail:0x%0" PRIx64 " Spike:0x%0" PRIx64
            " (xor: 0x%0" PRIx64 ")\n",
            csr_name, sail_val, spike_val, sail_val ^ spike_val);
  }
  return chk;
}

void spike::setup_model()
{
  // Spike's CLINT ticks (with a 0 increment) on initialization and
  // sets MIP.MTIP as 0=mtime>=mtimecmp=0. Setup Sail with the same
  // initial conditions, since Sail's tick does not support a 0
  // increment.
  zmtime = hart->get_state()->time->read();
  zmtimecmp = clint->get_mtimecmp(0);
  zmip = zMk_Minterrupts(get_csr_unchecked(CSR_MIP));

  // Match the default Spike PMP config, which only sets the first
  // entry to permit unprivileged access to all memory.
  zwrite_CSR(CSR_PMPADDR0, get_csr_unchecked(CSR_PMPADDR0));
  zwrite_CSR(CSR_PMPCFG0, get_csr_unchecked(CSR_PMPCFG0));
}

bool spike::check_init()
{
  // Tweak model to match Spike.
  setup_model();

  // Now check for a compatible state.
  bool res = true;

  res &= check_csr(CSR_MISA, "MISA");
  res &= check_csr(CSR_MSTATUS, "MSTATUS");
  if (is_32bit) {
    res &= check_csr(CSR_MSTATUSH, "MSTATUSH");
  }
  res &= check_csr(CSR_MIP, "MIP");
  res &= check_csr(CSR_MIDELEG, "MIDELEG");
  res &= check_csr(CSR_MEDELEG, "MEDELEG");
  res &= check_csr(CSR_MCONFIGPTR, "MCONFIGPTR");
  res &= check_csr(CSR_MENVCFG, "MENVCFG");
  if (is_32bit) {
    res &= check_csr(CSR_MENVCFGH, "MENVCFGH");
  }

  res &= check_csr(CSR_PMPADDR0, "PMPADDR0");
  res &= check_csr(CSR_PMPCFG0, "PMPCFG0");

  res &= check_csr(CSR_FCSR, "FCSR");

  return res;
}

bool spike::check_state()
{
  // TODO: Vector regs.
  bool chk = check_pc() && check_xregs() && check_csrs() && check_fregs()
      && check_time();

  mem_writes.clear();
  mem_reads.clear();
  xreg_writes.clear();
  freg_writes.clear();
  csr_writes.clear();
  csr_reads.clear();
  vreg_writes.clear();
  pc_write = std::nullopt;

  return chk;
}

void spike::step()
{
  hart->step(1);
}

void spike::tick()
{
  for (auto &dev : devices) {
    dev->tick(1);
  }
}

std::optional<int> spike::has_exited()
{
  if (exited) {
    return exit_code;
  }
  return std::nullopt;
}

void spike::set_verbose(bool enable)
{
  verbose = enable;
}

/* callbacks_if API */

void spike::mem_write_callback(const char *, uint64_t paddr, uint64_t width,
                               lbits value)
{
  mem_writes.push_back({paddr, width, value});
}

void spike::mem_read_callback(const char *, uint64_t paddr, uint64_t width,
                              lbits value)
{
  mem_reads.push_back({paddr, width, value});
}

void spike::mem_exception_callback(uint64_t, uint64_t) { }

void spike::xreg_full_write_callback(const_sail_string, unsigned reg,
                                     uint64_t value)
{
  // TODO: check whether reg is assigned already.
  xreg_writes[reg] = value;
}

void spike::freg_write_callback(unsigned reg, uint64_t value)
{
  // TODO: check whether reg is assigned already.
  freg_writes[reg] = value;
}

void spike::csr_full_write_callback(const_sail_string, unsigned reg,
                                    uint64_t value)
{
  // TODO: check whether reg is assigned already.
  csr_writes[reg] = value;
}

void spike::csr_full_read_callback(const_sail_string, unsigned reg,
                                   uint64_t value)
{
  // TODO: check whether reg is assigned already.
  csr_reads[reg] = value;
}

void spike::vreg_write_callback(unsigned reg, lbits value)
{
  vreg_writes[reg] = value;
}

void spike::pc_write_callback(uint64_t value)
{
  pc_write = value;
}

void spike::trap_callback() { }

/* Private API */

bool spike::check_pc()
{
  if (pc_write.has_value()) {
    return check_csr_vals("PC", pc_write.value(), hart->get_state()->pc);
  }
  return true;
}

bool spike::check_xregs()
{
  bool res = true;
  for (auto write : xreg_writes) {
    uint64_t sail_val = write.second & reg_mask;
    uint64_t spike_val = hart->get_state()->XPR[write.first] & reg_mask;
    bool chk = sail_val == spike_val;
    if (!chk && verbose) {
      fprintf(stderr,
              "GPR[0x%0x] mismatch: Sail:0x%0" PRIx64 " Spike:0x%0" PRIx64
              " (xor: 0x%0" PRIx64 ")\n",
              write.first, sail_val, spike_val, sail_val ^ spike_val);
    }
    res &= chk;
  }
  return res;
}

bool spike::check_fregs()
{
  bool res = true, chk;
  for (auto write : freg_writes) {
    uint64_t sail_val = write.second;
    // TODO
    // float128_t spike_val = hart->get_state()->FPR[write.first];
    chk = true; // TODO: (sail_val & reg_mask) == (spike_val & reg_mask);
    if (!chk && verbose) {
      fprintf(stderr, "FPR[0x%0x] mismatch: Sail:0x%0" PRIx64 "\n", write.first,
              sail_val);
    }
    res &= chk;
  }

  res &= check_csr(CSR_FCSR, "FCSR");
  return res;
}

bool spike::check_csrs()
{
  bool res = true;
  for (auto write : csr_writes) {
    bool chk = true;
    auto csr_entry = hart->get_state()->csrmap.find(write.first);
    if (csr_entry != hart->get_state()->csrmap.end()) {
      uint64_t sail_val = write.second & reg_mask;
      uint64_t spike_val = csr_entry->second->read() & reg_mask;
      chk = sail_val == spike_val;
      if (!chk && verbose) {
        fprintf(stderr,
                "CSR[0x%0x] mismatch: Sail:0x%016" PRIx64 " Spike:0x%016" PRIx64
                " (xor:0x%016" PRIx64 ")\n",
                write.first, sail_val, spike_val, sail_val ^ spike_val);
      }
    } else {
      fprintf(stderr, "CSR[0x%0x] not found in Spike.\n", write.first);
      chk = false;
    }
    res &= chk;
  }
  return res;
}

bool spike::check_csr_vals(const char *csr, uint64_t sail, uint64_t spike)
{
  bool chk = (sail & reg_mask) == (spike & reg_mask);
  if (!chk && verbose) {
    fprintf(stderr,
            "CSR %s mismatch: Sail:0x%0" PRIx64 " Spike:0x%0" PRIx64
            " (xor: 0x%0" PRIx64 ")\n",
            csr, sail, spike, sail ^ spike);
  }
  return chk;
}

bool spike::check_time()
{
  bool res = check_csr_vals("MTIME", zmtime, hart->get_state()->time->read());
  res &= check_csr_vals("MTIMECMP", zmtimecmp, clint->get_mtimecmp(0));
  res &= check_csr_vals("MIP", zmip.zbits, get_csr_unchecked(CSR_MIP));

  return res;
}

void spike::update_exited()
{
  uint64_t tohost = memif.read_uint64(tohost_addr).from_le();
  uint8_t dev_cmd = tohost >> 48;
  uint64_t payload = tohost << 16 >> 16;
  if ((dev_cmd == 0) && (payload & 1)) {
    exited = true;
    exit_code = payload >> 1;
  }
}
