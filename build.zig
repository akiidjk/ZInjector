const std = @import("std");
const Builder = std.build.Builder;
const Step = std.Build.Step;

pub fn build(b: *std.Build) void {
    var optimize: std.builtin.OptimizeMode = undefined;

    const release = b.option(bool, "release", "Set if release or not") orelse false;
    if (release) {
        optimize = b.standardOptimizeOption(.{});
    } else {
        optimize = b.standardOptimizeOption(.{});
    }

    const win64_target = b.resolveTargetQuery(.{ .cpu_arch = .x86_64, .os_tag = .windows });
    const TARGETS = [_]std.Target.Query{
        .{ .cpu_arch = .x86_64, .os_tag = .linux },
        .{ .cpu_arch = .x86_64, .os_tag = .windows },
    };

    // Dll compilation for windows
    const zigwin32 = b.dependency("zigwin32", .{});
    const dll = b.addLibrary(.{
        .name = "evildll",
        .linkage = .dynamic,
        .root_module = b.createModule(.{ .link_libc = true, .root_source_file = b.path("src/dll.zig"), .target = win64_target, .optimize = optimize, .imports = &.{.{ .name = "win32", .module = zigwin32.module("win32") }} }),
    });
    b.installArtifact(dll);

    // Test file build in c for windows
    const testExe = b.addExecutable(.{
        .name = "dll_tester",
        .root_module = b.createModule(.{
            .optimize = optimize,
            .target = win64_target,
            .link_libc = true,
        }),
    });
    testExe.root_module.addCSourceFile(.{ .file = b.path("src/dlltester.c") });
    b.installArtifact(testExe);

    // Injector
    for (TARGETS) |TARGET| {
        const mod = b.addModule("ZInjector", .{
            .root_source_file = b.path("src/root.zig"),
            .target = win64_target,
        });

        const injector = b.addExecutable(.{
            .name = "zinjector",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/main.zig"),
                .target = b.resolveTargetQuery(TARGET),
                .optimize = optimize,
                .link_libc = true,
                .imports = &.{
                    .{ .name = "ZInjector", .module = mod },
                },
            }),
        });

        b.installArtifact(injector);
    }
}
