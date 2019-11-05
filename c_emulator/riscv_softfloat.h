#pragma once

unit softfloat_f32add(mach_bits rm, mach_bits v1, mach_bits v2);
unit softfloat_f32sub(mach_bits rm, mach_bits v1, mach_bits v2);
unit softfloat_f32mul(mach_bits rm, mach_bits v1, mach_bits v2);
unit softfloat_f32div(mach_bits rm, mach_bits v1, mach_bits v2);

unit softfloat_f64add(mach_bits rm, mach_bits v1, mach_bits v2);
unit softfloat_f64sub(mach_bits rm, mach_bits v1, mach_bits v2);
unit softfloat_f64mul(mach_bits rm, mach_bits v1, mach_bits v2);
unit softfloat_f64div(mach_bits rm, mach_bits v1, mach_bits v2);

unit softfloat_f32muladd(mach_bits rm, mach_bits v1, mach_bits v2, mach_bits v3);
unit softfloat_f64muladd(mach_bits rm, mach_bits v1, mach_bits v2, mach_bits v3);

unit softfloat_f32sqrt(mach_bits rm, mach_bits v);
unit softfloat_f64sqrt(mach_bits rm, mach_bits v);
