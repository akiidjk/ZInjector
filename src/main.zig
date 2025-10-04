//! The effective injector main
const std = @import("std");
const ZInjector = @import("ZInjector");
const win32 = @import("win32");

const debug = std.log.debug;
const info = std.log.info;
const war = std.log.warn;
const err = std.log.err;

pub fn main() !void {
    debug("Viva il dux.\n", .{});

    // try ZInjector.bufferedPrint();
}
