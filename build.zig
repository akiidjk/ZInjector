const std = @import("std");
const Step = std.Build.Step;

pub fn build(b: *std.Build) void {
    const optimize: std.builtin.OptimizeMode = b.standardOptimizeOption(.{});
    const target: std.Build.ResolvedTarget = b.standardTargetOptions(.{});

    //Deps
    const zigwin32 = b.dependency("zigwin32", .{});
    const zgui = b.dependency("zgui", .{
        .shared = false,
        .with_implot = true,
    });

    // Shared Module
    const loggerModule = b.addModule("logger", .{
        .root_source_file = b.path("src/lib/logger.zig"),
        .target = target,
    });

    const winModule = b.addModule("win", .{ .root_source_file = b.path("src/lib/win.zig"), .target = target, .imports = &.{ .{
        .name = "win32",
        .module = zigwin32.module("win32"),
    }, .{ .name = "logger", .module = loggerModule } } });

    // Dll compilation for windows
    const dll = b.addLibrary(.{
        .name = "evildll",
        .linkage = .dynamic,
        .root_module = b.createModule(.{ .link_libc = true, .root_source_file = b.path("src/dll.zig"), .target = target, .optimize = optimize, .imports = &.{ .{ .name = "win", .module = winModule }, .{ .name = "logger", .module = loggerModule } } }),
    });
    b.installArtifact(dll);

    // Test file build in c for windows
    const testExe = b.addExecutable(.{
        .name = "dll_tester",
        .root_module = b.createModule(.{
            .optimize = optimize,
            .target = target,
            .link_libc = true,
        }),
    });
    testExe.root_module.addCSourceFile(.{ .file = b.path("src/test/dlltester.c") });
    b.installArtifact(testExe);

    // Injector
    const libmod = b.addModule("lib", .{ .root_source_file = b.path("src/lib/root.zig"), .target = target, .imports = &.{.{ .name = "logger", .module = loggerModule }} });

    const injector = b.addExecutable(.{
        .name = "zinjector",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .imports = &.{ .{ .name = "lib", .module = libmod }, .{ .name = "win32", .module = zigwin32.module("win32") }, .{ .name = "win", .module = winModule }, .{ .name = "logger", .module = loggerModule } },
        }),
    });

    injector.root_module.addImport("zgui", zgui.module("root"));
    injector.linkLibrary(zgui.artifact("imgui"));

    { // Needed for glfw/wgpu rendering backend
        const zglfw = b.dependency("zglfw", .{});
        injector.root_module.addImport("zglfw", zglfw.module("root"));
        if (target.result.os.tag == .linux) {
            injector.linkLibrary(zglfw.artifact("glfw"));
        }

        const zpool = b.dependency("zpool", .{});
        injector.root_module.addImport("zpool", zpool.module("root"));

        const zgpu = b.dependency("zgpu", .{});
        injector.root_module.addImport("zgpu", zgpu.module("root"));

        if (target.result.os.tag == .linux) {
            injector.linkLibrary(zgpu.artifact("zdawn"));
        }
    }

    b.installArtifact(injector);

    const lib_test_module = b.addTest(.{
        .root_module = libmod,
    });
    const lib_test = b.addRunArtifact(lib_test_module);
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&lib_test.step);
}
