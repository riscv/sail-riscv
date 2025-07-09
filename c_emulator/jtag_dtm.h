#pragma once

#include <cstdint>
#include <memory>

#define DTMCONTROL_VERSION 0xf
#define DTMCONTROL_ABITS (0x3f << 4)
#define DTMCONTROL_DMISTAT (3 << 10)
#define DTMCONTROL_IDLE (7 << 12)
#define DTMCONTROL_DMIRESET (1 << 16)
#define DTMCONTROL_DMIHARDRESET (1 << 17)

#define DTM_DTMCS_ABITS_OFFSET 4ULL

#define DMI_OP 3
#define DMI_DATA (0xffffffffLL << 2)
#define DMI_ADDRESS ((1LL << (abits + 34)) - (1LL << 34))

#define DMI_OP_STATUS_SUCCESS 0
#define DMI_OP_STATUS_RESERVED 1
#define DMI_OP_STATUS_FAILED 2
#define DMI_OP_STATUS_BUSY 3

#define DMI_OP_NOP 0
#define DMI_OP_READ 1
#define DMI_OP_WRITE 2
#define DMI_OP_RESERVED 3

#define DTM_DMI_OP_OFFSET 0ULL
#define DTM_DMI_OP_LENGTH 2ULL
#define DTM_DMI_OP 3ULL

enum class IR { IDCODE = 1, DTMCONTROL = 0x10, DBUS = 0x11, BYPASS = 0x1f };

enum class JtagState {
  TestLogicReset,
  RunTestIdle,
  SelectDrScan,
  CaptureDr,
  ShiftDr,
  Exit1Dr,
  PauseDr,
  Exit2Dr,
  UpdateDr,
  SelectIrScan,
  CaptureIr,
  ShiftIr,
  Exit1Ir,
  PauseIr,
  Exit2Ir,
  UpdateIr
};

class jtag_dtm_t {
  static const unsigned idcode = 0xdeadbeef;

public:
  explicit jtag_dtm_t(unsigned required_rti_cycles);
  void reset();

  void set_pins(bool tck, bool tms, bool tdi);

  bool tdo() const
  {
    return _tdo;
  }

  JtagState state() const
  {
    return _state;
  }

private:
  // The number of Run-Test/Idle cycles required
  // before a DMI access is complete.
  unsigned required_rti_cycles = 0;
  bool _tck = false, _tms = false, _tdi = false, _tdo = false;
  uint32_t ir = 0;
  static const unsigned ir_length = 5;
  uint64_t dr = 0;
  unsigned dr_length = 0;

  // abits must come before dtmcontrol so it can
  // easily be used in the constructor.
  // From RISC-V Debug Spec (both 0.13.2 and 1.0):
  // The DMI uses between 7 and 32 address bits.
  static const unsigned abits = 7;
  uint32_t dtmcontrol = ((abits << DTM_DTMCS_ABITS_OFFSET) | 1);
  uint64_t dmi = DMI_OP_STATUS_SUCCESS << DTM_DMI_OP_OFFSET;
  unsigned bypass = 0;

  // Number of Run-Test/Idle cycles needed before
  // we call this access complete.
  unsigned rti_remaining = 0;
  bool busy_stuck = false;

  JtagState _state = JtagState::TestLogicReset;

  void capture_dr();
  void update_dr();
};

class remote_bitbang_t;

void init_debug_interface(uint16_t rbb_port);
bool is_debug_enabled();
std::shared_ptr<remote_bitbang_t> get_remote_bitbang();
