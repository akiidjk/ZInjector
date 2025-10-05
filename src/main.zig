//! The effective injector main
const std = @import("std");
const ZInjector = @import("ZInjector");
const win32 = @import("win32");

const debug = std.log.debug;
const info = std.log.info;
const war = std.log.warn;
const err = std.log.err;

pub fn main() !void {
    const alloc: std.mem.Allocator = std.heap.page_allocator;
    const argv = try std.process.argsAlloc(alloc);
    const argc = argv.len;

    debug("Args number: {d}", .{argc});

    if (argc != 3) {
        err("usage: {s} <path-to-dll> <PID>", .{argv[0]});
        return;
    }

    const PATH_DLL = argv[1];
    const PID = try std.fmt.parseInt(i32, argv[2], 10);

    debug("DLL: {s}", .{PATH_DLL});
    debug("PID: {d}", .{PID});

    // try ZInjector.bufferedPrint();
}
