#pragma once

unit softfloat_f16add(mach_bits rm, mach_bits v1, mach_bits v2);
unit softfloat_f16sub(mach_bits rm, mach_bits v1, mach_bits v2);
unit softfloat_f16mul(mach_bits rm, mach_bits v1, mach_bits v2);
unit softfloat_f16div(mach_bits rm, mach_bits v1, mach_bits v2);

unit softfloat_f32add(mach_bits rm, mach_bits v1, mach_bits v2);
unit softfloat_f32sub(mach_bits rm, mach_bits v1, mach_bits v2);
unit softfloat_f32mul(mach_bits rm, mach_bits v1, mach_bits v2);
unit softfloat_f32div(mach_bits rm, mach_bits v1, mach_bits v2);

unit softfloat_f64add(mach_bits rm, mach_bits v1, mach_bits v2);
unit softfloat_f64sub(mach_bits rm, mach_bits v1, mach_bits v2);
unit softfloat_f64mul(mach_bits rm, mach_bits v1, mach_bits v2);
unit softfloat_f64div(mach_bits rm, mach_bits v1, mach_bits v2);

unit softfloat_f16muladd(mach_bits rm, mach_bits v1, mach_bits v2,
                         mach_bits v3);
unit softfloat_f32muladd(mach_bits rm, mach_bits v1, mach_bits v2,
                         mach_bits v3);
unit softfloat_f64muladd(mach_bits rm, mach_bits v1, mach_bits v2,
                         mach_bits v3);

unit softfloat_f16sqrt(mach_bits rm, mach_bits v);
unit softfloat_f32sqrt(mach_bits rm, mach_bits v);
unit softfloat_f64sqrt(mach_bits rm, mach_bits v);

unit softfloat_f16toi32(mach_bits rm, mach_bits v);
unit softfloat_f16toui32(mach_bits rm, mach_bits v);
unit softfloat_f16toi64(mach_bits rm, mach_bits v);
unit softfloat_f16toui64(mach_bits rm, mach_bits v);

unit softfloat_f32toi32(mach_bits rm, mach_bits v);
unit softfloat_f32toui32(mach_bits rm, mach_bits v);
unit softfloat_f32toi64(mach_bits rm, mach_bits v);
unit softfloat_f32toui64(mach_bits rm, mach_bits v);

unit softfloat_f64toi32(mach_bits rm, mach_bits v);
unit softfloat_f64toui32(mach_bits rm, mach_bits v);
unit softfloat_f64toi64(mach_bits rm, mach_bits v);
unit softfloat_f64toui64(mach_bits rm, mach_bits v);

unit softfloat_i32tof16(mach_bits rm, mach_bits v);
unit softfloat_ui32tof16(mach_bits rm, mach_bits v);
unit softfloat_i64tof16(mach_bits rm, mach_bits v);
unit softfloat_ui64tof16(mach_bits rm, mach_bits v);

unit softfloat_i32tof32(mach_bits rm, mach_bits v);
unit softfloat_ui32tof32(mach_bits rm, mach_bits v);
unit softfloat_i64tof32(mach_bits rm, mach_bits v);
unit softfloat_ui64tof32(mach_bits rm, mach_bits v);

unit softfloat_i32tof64(mach_bits rm, mach_bits v);
unit softfloat_ui32tof64(mach_bits rm, mach_bits v);
unit softfloat_i64tof64(mach_bits rm, mach_bits v);
unit softfloat_ui64tof64(mach_bits rm, mach_bits v);

unit softfloat_f16tof32(mach_bits rm, mach_bits v);
unit softfloat_f16tof64(mach_bits rm, mach_bits v);
unit softfloat_f32tof64(mach_bits rm, mach_bits v);

unit softfloat_f32tof16(mach_bits rm, mach_bits v);
unit softfloat_f64tof16(mach_bits rm, mach_bits v);
unit softfloat_f64tof32(mach_bits rm, mach_bits v);

unit softfloat_f16lt(mach_bits v1, mach_bits v2);
unit softfloat_f16lt_quiet(mach_bits v1, mach_bits v2);
unit softfloat_f16le(mach_bits v1, mach_bits v2);
unit softfloat_f16le_quiet(mach_bits v1, mach_bits v2);
unit softfloat_f16eq(mach_bits v1, mach_bits v2);
unit softfloat_f32lt(mach_bits v1, mach_bits v2);
unit softfloat_f32lt_quiet(mach_bits v1, mach_bits v2);
unit softfloat_f32le(mach_bits v1, mach_bits v2);
unit softfloat_f32le_quiet(mach_bits v1, mach_bits v2);
unit softfloat_f32eq(mach_bits v1, mach_bits v2);
unit softfloat_f64lt(mach_bits v1, mach_bits v2);
unit softfloat_f64lt_quiet(mach_bits v1, mach_bits v2);
unit softfloat_f64le(mach_bits v1, mach_bits v2);
unit softfloat_f64le_quiet(mach_bits v1, mach_bits v2);
unit softfloat_f64eq(mach_bits v1, mach_bits v2);

unit softfloat_f16roundToInt(mach_bits rm, mach_bits v, bool exact);
unit softfloat_f32roundToInt(mach_bits rm, mach_bits v, bool exact);
unit softfloat_f64roundToInt(mach_bits rm, mach_bits v, bool exact);
