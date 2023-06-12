#pragma once
#include <inttypes.h>

#include "riscv_hpmevents.h"

typedef struct {
  // This is a model internal event-id, used to identify the model
  // supported events.
  model_event_id event;

  // This is the event-id used by the platform software to identify
  // this event, for e.g. by writing this value to the mhpmevent
  // registers.  The model cannot support an event-id of 0.
  mach_bits plat_event_id;
} riscv_hpm_event;

// An array containing the set of platform events, defined in
// riscv_platform_events.c
extern riscv_hpm_event platform_events[];

// Register the set of platform-supported events and their software
// identifiers. 'events' should be an array of riscv_event_t structs
// defined in a platform-specific file.  There should be a single
// entry for E_last, and it should be last entry in the array.
//
// For now, only a maximum of 64 events can be registered.
void init_platform_events(riscv_hpm_event *events);

// This is to reset state between test runs.  It does not change the
// registered platform events.
void reset_platform_events(void);

// Called after an instruction executes, to detect and signal any
// platform events.  This is platform-specific code.
void signal_platform_events(void);

// Called from the main simulator loop, after the above function.
// Increments the counters for all the detected and signalled events.
// Each such counter is incremented by one.
void process_hpm_events(void);
