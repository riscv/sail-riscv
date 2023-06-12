#pragma once
#include "sail.h"

// The events defined by the platform.  EVENT_DEF_FILE should contain
// a comma separated list of enumerations of event identifiers.

typedef enum {
    E_not_defined = 0,
#ifdef   EVENT_ENUMS
#include EVENT_ENUMS
#endif
    E_last,
} model_event_id;

// Generic event signaller called from the simulator to signal
// detected events.
void riscv_signal_event(model_event_id id);

// Called from the Sail model when hpm_event registers are written.
unit riscv_write_mhpmevent(mach_bits regidx, mach_bits plat_event_id, mach_bits prev_event_id);
