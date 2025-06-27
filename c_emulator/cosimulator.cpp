#include "cosimulator.h"

#ifdef USE_SPIKE
#include "spike.h"
#endif

class null_sim : public cosim_if {
public:
  null_sim(bool) { };
  void set_dtb(const unsigned char *, size_t) override { };
  void init_elf(const char *, uint64_t) override { };
  bool check_init() override
  {
    return true;
  };
  bool check_state() override
  {
    return true;
  };
  void step() override { };
  void tick() override { };
  std::optional<int> has_exited() override
  {
    return std::nullopt;
  }
  void set_verbose(bool) override { };
};

cosimulator::cosimulator([[maybe_unused]] Cosim_type t, bool is_32bit)
{
#ifdef USE_SPIKE
  switch (t) {
  case Cosim_type::SPIKE:
    cosim_ptr = std::make_unique<spike>(is_32bit);
    break;
  case Cosim_type::NOP:
    cosim_ptr = std::make_unique<null_sim>(is_32bit);
    break;
  }
#else
  cosim_ptr = std::make_unique<null_sim>(is_32bit);
#endif
}

cosimulator::~cosimulator() { }
