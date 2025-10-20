const std = @import("std");
const Step = std.Build.Step;

pub fn build(b: *std.Build) void {
    const optimize: std.builtin.OptimizeMode = b.standardOptimizeOption(.{});
    const target: std.Build.ResolvedTarget = b.standardTargetOptions(.{});

    // Vars
    const ipv4 = b.option([]const u8, "ipv4", "Ip for reverse shell") orelse "127.0.0.1";
    const port = b.option(u32, "port", "Port for reverse shell") orelse 8080;
    const options = b.addOptions();
    options.addOption([]const u8, "ipv4", ipv4);
    options.addOption(u32, "port", port);

    //Deps
    const zigwin32 = b.dependency("zigwin32", .{});
    const cli = b.dependency("cli", .{});

    // Shared Module
    const loggerModule = b.addModule("logger", .{ .root_source_file = b.path("src/lib/logger.zig"), .target = target });

    const winModule = b.addModule("win", .{ .root_source_file = b.path("src/lib/win.zig"), .target = target, .imports = &.{ .{
        .name = "win32",
        .module = zigwin32.module("win32"),
    }, .{ .name = "logger", .module = loggerModule } } });

    // Dll compilation for windows
    const dlls = &[_]struct {
        name: []const u8,
        path: []const u8,
        imports: ?[]const std.Build.Module.Import,
    }{
        .{ .name = "console", .path = "src/dll/console.zig", .imports = &.{ .{ .name = "win", .module = winModule }, .{ .name = "logger", .module = loggerModule } } },
        .{ .name = "messageBoxs", .path = "src/dll/messageBoxs.zig", .imports = &.{ .{ .name = "win", .module = winModule }, .{ .name = "logger", .module = loggerModule } } },
        .{ .name = "reverseShell", .path = "src/dll/reverseShell.zig", .imports = &.{ .{ .name = "win", .module = winModule }, .{ .name = "logger", .module = loggerModule } } },
    };

    for (dlls) |dll| {
        const dllFile = b.addLibrary(.{
            .name = dll.name,
            .linkage = .dynamic,
            .root_module = b.createModule(.{ .link_libc = true, .root_source_file = b.path(dll.path), .target = target, .optimize = optimize, .imports = dll.imports.? }),
        });
        dllFile.root_module.addOptions("reverse_shell_options", options);
        b.installArtifact(dllFile);
    }

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

    // Injector + Attacks

    const libmod = b.addModule("lib", .{ .root_source_file = b.path("src/lib/root.zig"), .target = target, .imports = &.{.{ .name = "logger", .module = loggerModule }} });

    const dll_injection = b.addModule("dll-injection", .{ .root_source_file = b.path("src/lib/attacks/dll-injection.zig"), .target = target, .imports = &.{ .{ .name = "win", .module = winModule }, .{ .name = "logger", .module = loggerModule }, .{ .name = "lib", .module = libmod } } });
    const thread = b.addModule("thread", .{ .root_source_file = b.path("src/lib/attacks/thread.zig"), .target = target, .imports = &.{ .{ .name = "win", .module = winModule }, .{ .name = "logger", .module = loggerModule }, .{ .name = "lib", .module = libmod } } });

    const hijacking = b.addModule("hijacking", .{ .root_source_file = b.path("src/lib/attacks/hijacking.zig"), .target = target, .imports = &.{ .{ .name = "win", .module = winModule }, .{ .name = "logger", .module = loggerModule }, .{ .name = "lib", .module = libmod } } });

    const injector = b.addExecutable(.{
        .name = "zinjector",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .imports = &.{ .{ .name = "lib", .module = libmod }, .{ .name = "win32", .module = zigwin32.module("win32") }, .{ .name = "win", .module = winModule }, .{ .name = "logger", .module = loggerModule }, .{ .name = "cli", .module = cli.module("cli") }, .{ .name = "dll-injection", .module = dll_injection }, .{ .name = "thread", .module = thread }, .{ .name = "hijacking", .module = hijacking } },
        }),
    });

    b.installArtifact(injector);

    const lib_test_module = b.addTest(.{
        .root_module = libmod,
    });
    const lib_test = b.addRunArtifact(lib_test_module);
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&lib_test.step);
}
