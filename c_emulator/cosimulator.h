#pragma once
#include <stdint.h>
#include <memory>
#include <optional>

// currently implemented cosimulators
enum Cosim_type {
  NOP,
  SPIKE,
};

// interface to cosimulator
class cosim_if {
public:
  virtual ~cosim_if() = default;

  // Called to set the DTB.
  virtual void set_dtb(const unsigned char *dtb, size_t dtb_len) = 0;

  // Called to load an ELF program file with an expected_entry location (if
  // non-zero).  This might be called multiple times with different files.
  virtual void init_elf(const char *elf_file, uint64_t expected_entry) = 0;

  // Called to ensure compatible initialization
  // of the model and the cosimulator.
  virtual bool check_init() = 0;

  // Called to ensure compatible states.
  virtual bool check_state() = 0;

  // Called to single-step an execution.
  virtual void step() = 0;

  // Called to tick clock and devices.
  virtual void tick() = 0;

  // Handling exits.
  virtual std::optional<int> has_exited() = 0;

  // Set verbosity.
  virtual void set_verbose(bool) = 0;
};

class cosimulator {
public:
  cosimulator(Cosim_type t, bool is_32bit);
  ~cosimulator();

  cosimulator(const cosimulator &) = delete;
  cosimulator &operator=(const cosimulator &) = delete;

  void set_dtb(const unsigned char *dtb, size_t dtb_len)
  {
    cosim_ptr->set_dtb(dtb, dtb_len);
  }

  void init_elf(const char *elf_file, uint64_t expected_entry)
  {
    cosim_ptr->init_elf(elf_file, expected_entry);
  }

  bool check_init()
  {
    return cosim_ptr->check_init();
  }

  bool check_state()
  {
    return cosim_ptr->check_state();
  }

  void step()
  {
    cosim_ptr->step();
  }

  void tick()
  {
    cosim_ptr->tick();
  }

  std::optional<int> has_exited()
  {
    return cosim_ptr->has_exited();
  }

  void set_verbose(bool enable)
  {
    cosim_ptr->set_verbose(enable);
  }

private:
  std::unique_ptr<cosim_if> cosim_ptr;
};
