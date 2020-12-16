#include <assert.h>
#include <string.h>
#include "sail.h"
#include "riscv_sail.h"
#include "riscv_hpmevents.h"
#include "riscv_hpmevents_impl.h"

typedef struct {
  // This is the event-id used by the platform software to identify
  // this event, for e.g. by writing this value to the mhpmevent
  // registers.  The model cannot support an event-id of 0.
  mach_bits plat_event_id;
  // the index of the counter register mapped to this event
  mach_bits regidx;
  // how many times this event has been selected (i.e. if more than
  // once, then multiple counters need to be incremented, and the
  // above regidx is not useful)
  int count;
} event_info;

static event_info event_map[E_last];

// If there are multiple counters selected for the same event (e.g. if
// the same event selector is written to more than one hpmevent
// register), then the event_map cannot be used, and we need to use a
// slower path.
static bool usable_event_map;

// A bitmask of unprocessed events that have occurred in this cycle.
// If we have more than 64 events, we will need multiple bitsets.
uint64_t hpm_eventset;

// Events communicated from the simulator
void riscv_signal_event(model_event_id id) {
  hpm_eventset |= 0x1 << id;
}

// Update our event map on every write to the event selector registers.
unit riscv_write_mhpmevent(mach_bits regidx, mach_bits new_event_id, mach_bits prev_event_id) {
  if (new_event_id == prev_event_id) return UNIT;

  for (int eid = 0; eid < E_last; eid++) {
    event_info *ei = &event_map[eid];
    if (ei->plat_event_id == 0) continue;
    // register the new value
    if (ei->plat_event_id == new_event_id) {
      ei->regidx = regidx;
      ei->count++;
    }
    // deregister the old value
    if (ei->plat_event_id == prev_event_id) {
      ei->count--;
      assert(ei->count >= 0);
    }
  }

  // check whether the event map is still usable for a fast path: a
  // max of one counter per event.
  bool usable = true;
  for (int eid = 0; eid < E_last; eid++) {
    if (event_map[eid].count > 1) {
      usable = false;
      break;
    }
  }
  usable_event_map = usable;
}

// Assumes the array is terminated by the entry for E_last.
void init_platform_events(riscv_hpm_event *events) {
  hpm_eventset = 0;
  usable_event_map = true;

  bzero(event_map, sizeof(event_map));
  // Ensure that we have 64 or fewer events.
  riscv_hpm_event *e = events;
  if (!e) return;
  int event_cnt = 0;
  while (e->event != E_last) {
    assert(event_cnt < 64);
    assert(e->event < E_last);
    assert(e->plat_event_id != 0);
    event_info *ei = &event_map[e->event];

    ei->plat_event_id = e->plat_event_id;
    event_cnt++;
    e++;
  }
}

void reset_platform_events(void) {
  for (int eid = 0; eid < E_last; eid++) {
    event_info *ei = &event_map[eid];
    ei->regidx = 0;
    ei->count = 0;
  }
  hpm_eventset = 0;
  usable_event_map = true;
}

static const int nregs = 29;

void increment_hpm_counter(uint64_t regidx) {
  uint64_t counterin = z_get_Counterin_bits(zmcountinhibit);
  int inhibit = 0x1 & (counterin >> (regidx + 3));
  if (!inhibit) {
    uint64_t *cntr = &zmhpmcounters.data[regidx];
    (*cntr)++;
  }
}

static void slow_process_hpm_selector(uint64_t plat_event_id) {
  // check all selector registers
  for (uint64_t idx = 0; idx < nregs; idx++) {
    uint64_t pevid = zmhpmevents.data[idx]; // XXX: Test for RV32
    if (pevid == plat_event_id) {
      increment_hpm_counter(idx);
    }
  }
}

void process_hpm_events(void) {
  uint64_t acc = hpm_eventset;

  for (int eid = 0; eid < E_last; eid++) {
    if (acc & 0x1) {
      event_info *ei = &event_map[eid];
      if (ei->plat_event_id == 0) continue;
      if (usable_event_map) {
        if (ei->count) increment_hpm_counter(ei->regidx);
      } else {
        slow_process_hpm_selector(ei->plat_event_id);
      }
    }
    acc >>= 1;
  }
  hpm_eventset = 0;
}
