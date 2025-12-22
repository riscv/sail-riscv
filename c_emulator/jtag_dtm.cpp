/* This file is derived from Spike (https://github.com/riscv/riscv-isa-sim)
 * and has the following license:
 *
 * Copyright (c) 2010-2017, The Regents of the University of California
 * (Regents).  All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the Regents nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * IN NO EVENT SHALL REGENTS BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT,
 * SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS,
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
 * REGENTS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  REGENTS SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE. THE SOFTWARE AND ACCOMPANYING DOCUMENTATION, IF ANY, PROVIDED
 * HEREUNDER IS PROVIDED "AS IS". REGENTS HAS NO OBLIGATION TO PROVIDE
 * MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */

#include <stdio.h>
#include "sail_riscv_model.h"
#include "riscv_model_impl.h"
#include "jtag_dtm.h"
#include "remote_bitbang.h"
#include "sail.h"

#ifdef JTAG_LOGGING
#define jtag_log(...) fprintf(stderr, __VA_ARGS__)
#else
#define jtag_log(...)
#endif

jtag_dtm_t::jtag_dtm_t(unsigned required_rti_cycles, ModelImpl *model)
    : required_rti_cycles(required_rti_cycles)
    , model(model)
{
}

void jtag_dtm_t::reset()
{
  _state = JtagState::TestLogicReset;
  busy_stuck = false;
  rti_remaining = 0;
  dmi = 0;
}

void jtag_dtm_t::set_pins(bool tck, bool tms, bool tdi)
{
  const JtagState next[16][2] = {
      // TEST_LOGIC_RESET
      {JtagState::RunTestIdle, JtagState::TestLogicReset},
      // RUN_TEST_IDLE
      {JtagState::RunTestIdle, JtagState::SelectDrScan  },
      // SELECT_DR_SCAN
      {JtagState::CaptureDr,   JtagState::SelectIrScan  },
      // CAPTURE_DR
      {JtagState::ShiftDr,     JtagState::Exit1Dr       },
      // SHIFT_DR
      {JtagState::ShiftDr,     JtagState::Exit1Dr       },
      // EXIT1_DR
      {JtagState::PauseDr,     JtagState::UpdateDr      },
      // PAUSE_DR
      {JtagState::PauseDr,     JtagState::Exit2Dr       },
      // EXIT2_DR
      {JtagState::ShiftDr,     JtagState::UpdateDr      },
      // UPDATE_DR
      {JtagState::RunTestIdle, JtagState::SelectDrScan  },
      // SELECT_IR_SCAN
      {JtagState::CaptureIr,   JtagState::TestLogicReset},
      // CAPTURE_IR
      {JtagState::ShiftIr,     JtagState::Exit1Ir       },
      // SHIFT_IR
      {JtagState::ShiftIr,     JtagState::Exit1Ir       },
      // EXIT1_IR
      {JtagState::PauseIr,     JtagState::UpdateIr      },
      // PAUSE_IR
      {JtagState::PauseIr,     JtagState::Exit2Ir       },
      // EXIT2_IR
      {JtagState::ShiftIr,     JtagState::UpdateIr      },
      // UPDATE_IR
      {JtagState::RunTestIdle, JtagState::SelectDrScan  }
  };

  if (!_tck && tck) {
    // Positive clock edge. TMS and TDI are sampled
    // on the rising edge of TCK by Target.
    switch (_state) {
    case JtagState::ShiftDr:
      dr >>= 1;
      dr |= (uint64_t)_tdi << (dr_length - 1);
      break;
    case JtagState::ShiftIr:
      ir >>= 1;
      ir |= _tdi << (ir_length - 1);
      break;
    default:
      break;
    }
    _state = next[static_cast<int>(_state)][_tms];
  } else {
    // Negative clock edge. TDO is updated.
    switch (_state) {
    case JtagState::RunTestIdle:
      if (rti_remaining > 0) {
        rti_remaining--;
      }
      break;
    case JtagState::TestLogicReset:
      ir = static_cast<uint32_t>(IR::IDCODE);
      break;
    case JtagState::CaptureDr:
      capture_dr();
      break;
    case JtagState::ShiftDr:
      _tdo = dr & 1;
      break;
    case JtagState::UpdateDr:
      update_dr();
      break;
    case JtagState::ShiftIr:
      _tdo = ir & 1;
      break;
    default:
      break;
    }
  }

  jtag_log("state=%2d, tdi=%d, tdo=%d, tms=%d, tck=%d, ir=0x%02x, "
           "dr=0x%lx\n",
           static_cast<int>(_state), _tdi, _tdo, _tms, _tck, ir, dr);

  _tck = tck;
  _tms = tms;
  _tdi = tdi;
}

void jtag_dtm_t::capture_dr()
{
  switch (ir) {
  case static_cast<uint32_t>(IR::IDCODE):
    dr = idcode;
    dr_length = 32;
    break;
  case static_cast<uint32_t>(IR::DTMCONTROL):
    dr = dtmcontrol;
    dr_length = 32;
    break;
  case static_cast<uint32_t>(IR::DBUS):
    if (rti_remaining > 0 || busy_stuck) {
      dr = DMI_OP_STATUS_BUSY;
      busy_stuck = true;
    } else {
      dr = dmi;
    }
    dr_length = abits + 34;
    break;
  case static_cast<uint32_t>(IR::BYPASS):
    dr = bypass;
    dr_length = 1;
    break;
  default:
    jtag_log("Unsupported IR: 0x%x\n", ir);
    break;
  }
  jtag_log("Capture DR; IR=0x%x, DR=0x%lx (%d bits)\n", ir, dr, dr_length);
}

void jtag_dtm_t::update_dr()
{
  jtag_log("Update DR; IR=0x%x, DR=0x%lx (%d bits)\n", ir, dr, dr_length);

  if (ir == static_cast<uint32_t>(IR::DTMCONTROL)) {
    if (dr & DTMCONTROL_DMIRESET) {
      busy_stuck = false;
    }
    if (dr & DTMCONTROL_DMIHARDRESET) {
      reset();
    }
  } else if (ir == static_cast<uint32_t>(IR::BYPASS)) {
    bypass = dr;
  } else if (ir == static_cast<uint32_t>(IR::DBUS) && !busy_stuck) {
    unsigned op = dr & DMI_OP;

    uint32_t data = (dr & DMI_DATA) >> 2;
    sail_int sail_data;
    CREATE(sail_int)(&sail_data);
    CONVERT_OF(sail_int, mach_int)(&sail_data, data);

    uint32_t address = (dr & DMI_ADDRESS) >> 34;
    sail_int sail_address;
    CREATE(sail_int)(&sail_address);
    CONVERT_OF(sail_int, mach_int)(&sail_address, address);

    jtag_log("OP: %u\n", op);

    dmi = dr;

    bool success = true;
    if (op == DMI_OP_READ) {
      // NOTE: If the interface of dmi_read() stays the same, are
      // these struct names always deterministic and don't change?
      // NOTE: The following struct consists of a bool and a sail_int
      struct hart::ztuple_z8z5boolzCz0z5iz9 dmi_read_result;
      CREATE(sail_int)(&dmi_read_result.ztup1);

      model->zdmi_read(&dmi_read_result, sail_address);

      success = dmi_read_result.ztup0;

      if (success) {
        uint32_t value = CONVERT_OF(mach_int, sail_int)(dmi_read_result.ztup1);

        dmi &= ~DMI_DATA;
        dmi |= ((uint64_t)value << 2) & DMI_DATA;
      }
      KILL(sail_int)(&dmi_read_result.ztup1);
    } else if (op == DMI_OP_WRITE) {
      success = model->zdmi_write(sail_address, sail_data);
    }

    if (success) {
      dmi = (dmi & ~0x3) | DMI_OP_STATUS_SUCCESS;
    } else {
      dmi = (dmi & ~0x3) | DMI_OP_STATUS_FAILED;
    }

    jtag_log("dmi=0x%lx\n", dmi);

    rti_remaining = required_rti_cycles;

    KILL(sail_int)(&sail_address);
    KILL(sail_int)(&sail_data);
  }
}
