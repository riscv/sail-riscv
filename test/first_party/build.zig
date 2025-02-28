const std = @import("std");
const Target = @import("std").Target;

// List of tests (src/<testname>.c files).
const TESTS = [_][]const u8{
    "test_hello_world",
    "test_max_pmp",
};

// Construct the build graph in `b` (this doesn't actually build anything itself).
pub fn build(b: *std.Build) void {
    const features = Target.riscv.Feature;
    var cpu_features = Target.Cpu.Feature.Set.empty;

    // TODO: We'll need to think about how we test different configurations of the model.
    // I'm thinking the best thing to do would be to embed metadata in each test.c
    // file that describes the configurations it should be built for and run on, since
    // not all tests apply to all configs. E.g. `test_max_pmp.c` makes no sense without PMP.
    cpu_features.addFeature(@intFromEnum(features.i));
    cpu_features.addFeature(@intFromEnum(features.m));
    cpu_features.addFeature(@intFromEnum(features.a));
    cpu_features.addFeature(@intFromEnum(features.f));
    cpu_features.addFeature(@intFromEnum(features.zifencei));
    cpu_features.addFeature(@intFromEnum(features.zicsr));
    // cpu_features.addFeature(@intFromEnum(features.d));

    const target = b.resolveTargetQuery(.{
        .cpu_arch = .riscv32,
        // Note, this is really the default Environment (usually the
        // 4th component of the target triple). Calling it the ABI is wrong.
        .abi = .none,
        .os_tag = .freestanding,
        .cpu_features_add = cpu_features,
    });

    const optimize = b.standardOptimizeOption(.{});

    // Module for common support (crt0.S etc).
    const common_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
    });

    common_mod.addCSourceFile(.{ .file = b.path("src/common/crt0.S") });
    common_mod.addCSourceFile(.{ .file = b.path("src/common/nanoprintf.c") });
    common_mod.addCSourceFile(.{ .file = b.path("src/common/runtime.c") });

    for (TESTS) |name| {
        var buf: [512]u8 = undefined;
        const test_path = std.fmt.bufPrint(&buf, "src/{s}.c", .{name}) catch std.debug.panic("Test path too long: {s}", .{name});

        const exe_mod = b.createModule(.{
            .target = target,
            .optimize = optimize,
        });

        exe_mod.addImport("common", common_mod);

        exe_mod.addCSourceFile(.{ .file = b.path(test_path) });

        const exe_name = std.fmt.bufPrint(&buf, "{s}.elf", .{name}) catch std.debug.panic("Test path too long: {s}", .{name});

        const exe = b.addExecutable(.{
            .name = exe_name,
            .root_module = exe_mod,
        });

        exe.setLinkerScript(b.path("src/common/link.ld"));

        b.installArtifact(exe);
    }
}
