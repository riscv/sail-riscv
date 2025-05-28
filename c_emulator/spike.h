#pragma once

#include <tuple>
#include <vector>
#include <map>
#include <optional>
#include <fesvr/memif.h>
#include <riscv/simif.h>
#include <riscv/processor.h>
#include <riscv/devices.h>
#include <riscv/cfg.h>
#include "riscv_callbacks_if.h"
#include "cosimulator.h"

class spike final : public chunked_memif_t,
                    public simif_t,
                    public cosim_if,
                    public callbacks_if {
public:
  spike(bool is_32bit);
  ~spike();

  spike(const spike &) = delete;
  spike &operator=(const spike &) = delete;

  // cosim_if
  void set_dtb(const unsigned char *dtb, size_t dtb_len) override;
  void init_elf(const char *elf_file, uint64_t expected_entry) override;
  bool check_init() override;
  bool check_state() override;
  void step() override;
  void tick() override;
  std::optional<int> has_exited() override;
  void set_verbose(bool enable) override;

  // simif_t API for processor_t to use

  // used for physical memory.
  char *addr_to_mem(reg_t paddr) override;
  // used for MMIO addresses
  bool mmio_load(reg_t paddr, size_t len, uint8_t *bytes) override;
  bool mmio_store(reg_t paddr, size_t len, const uint8_t *bytes) override;
  // Callback for processors to let the simulation know they were reset.
  void proc_reset(unsigned id) override;

  const cfg_t &get_cfg() const override
  {
    return cfg;
  }

  const std::map<size_t, processor_t *> &get_harts() const override
  {
    return harts;
  }

  const char *get_symbol(uint64_t paddr) override;

  // callbacks_if
  void mem_write_callback(const char *type, uint64_t paddr, uint64_t width,
                          lbits value) override;
  void mem_read_callback(const char *type, uint64_t paddr, uint64_t width,
                         lbits value) override;
  void mem_exception_callback(uint64_t paddr,
                              uint64_t num_of_exception) override;
  void xreg_full_write_callback(const_sail_string abi_name, unsigned reg,
                                uint64_t value) override;
  void freg_write_callback(unsigned reg, uint64_t value) override;
  void csr_full_write_callback(const_sail_string csr_name, unsigned reg,
                               uint64_t value) override;
  void csr_full_read_callback(const_sail_string csr_name, unsigned reg,
                              uint64_t value) override;
  void vreg_write_callback(unsigned reg, lbits value) override;
  void pc_write_callback(uint64_t value) override;
  void trap_callback() override;

protected:
  // chunked_memif_t, needed for ELF loading.
  void read_chunk(addr_t taddr, size_t len, void *dst) override;
  void write_chunk(addr_t taddr, size_t len, const void *src) override;
  void clear_chunk(addr_t taddr, size_t len) override;
  size_t chunk_align() override
  {
    return 8;
  }
  size_t chunk_max_size() override
  {
    return 8;
  }

private:
  void add_reset_rom(reg_t entry);
  void setup_model();
  bool check_csr(uint64_t csr, const char *csr_name);
  bool check_csr_vals(const char *csr, uint64_t sail, uint64_t spike);
  bool check_pc();
  bool check_xregs();
  bool check_fregs();
  bool check_csrs();
  bool check_time();
  void update_exited();

  const cfg_t cfg;
  processor_t *hart;
  std::map<size_t, processor_t *> harts;
  // used for spike's debugging messages (and its socket and terminal interface)
  std::ostream sout;
  // interface to memory and mmio
  memif_t memif;
  bus_t bus;
  addr_t tohost_addr;
  // devices to tick
  std::vector<std::shared_ptr<abstract_device_t>> devices;
  std::shared_ptr<clint_t> clint;
  // ELF symbols
  std::map<std::string, uint64_t> symbols;
  std::map<uint64_t, std::string> addr2symbol;
  // DTB
  const unsigned char *dtb;
  size_t dtb_len;
  // whether the ROM has been registered on the bus
  bool registered_reset_rom;
  // model parameters
  bool is_32bit;
  uint64_t reg_mask; // comparison mask
  // model state
  std::vector<std::tuple<uint64_t, uint64_t, lbits>> mem_writes;
  std::vector<std::tuple<uint64_t, uint64_t, lbits>> mem_reads;
  std::map<unsigned, uint64_t> xreg_writes;
  std::map<unsigned, uint64_t> freg_writes;
  std::map<unsigned, uint64_t> csr_writes;
  std::map<unsigned, uint64_t> csr_reads;
  std::map<unsigned, lbits> vreg_writes;
  std::optional<uint64_t> pc_write;
  // other spike state
  bool exited;
  int exit_code;
  // verbosity
  bool verbose;

  // Other private helpers.
  uint64_t get_csr_unchecked(reg_t csr);
};
