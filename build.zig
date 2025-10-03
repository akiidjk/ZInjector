const std = @import("std");

// const exe = b.addExecutable(.{
//     .name = "zinjector",
//     .root_module = b.createModule(.{
//         .root_source_file = b.path("src/main.zig"),
//         .target = target,
//         .optimize = optimize,
//         .link_libc = true,
//         .imports = &.{
//             .{ .name = "ZInjector", .module = mod },
//         },
//     }),
// });
//
//
//     const mod = b.addModule("ZInjector", .{
// .root_source_file = b.path("src/root.zig"),
// .target = target,
// });

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const win64_target = b.resolveTargetQuery(.{ .cpu_arch = .x86_64, .os_tag = .windows });

    const zigwin32 = b.dependency("zigwin32", .{});

    const dll = b.addLibrary(.{
        .name = "evildll",
        .linkage = .dynamic,
        .root_module = b.createModule(.{ .link_libc = true, .root_source_file = b.path("src/evildll.zig"), .target = win64_target, .optimize = optimize, .imports = &.{.{ .name = "win32", .module = zigwin32.module("win32") }} }),
    });

    // b.installArtifact(exe);
    b.installArtifact(dll);
}
