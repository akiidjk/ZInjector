const std = @import("std");
const lib = @import("lib");
const win = @import("win");
const logger = @import("logger");

pub fn hookInjection(
    dllPath: []const u8,
) anyerror!void {
    const allocator = std.heap.smp_allocator;
    var dll: ?win.HINSTANCE = undefined;

    const isAbs = try lib.isAbsolutePath(dllPath);
    logger.debug("Is ABS {any}", .{isAbs});
    var absPath: []const u8 = undefined;
    if (isAbs) {
        absPath = dllPath;
    } else {
        absPath = try lib.getAbsPath(allocator, dllPath);
    }
    logger.debug("Final abs path {s}", .{absPath});
    defer allocator.free(absPath);

    const dllPathCString = lib.convertToCString(allocator, absPath);
    defer allocator.free(dllPathCString);
    logger.debug("C STRING {s}", .{dllPathCString});
    dll = win.system.library_loader.LoadLibraryA(dllPathCString);
    if (dll == null) {
        logger.err("Erro getting dll {any}", .{win.standard.GetLastError()});
    }

    const hookProc: ?win.HOOKPROC = @ptrCast(win.system.library_loader.GetProcAddress(dll, "spotlessExport"));
    if (hookProc == null) {
        logger.err("Error during getting spotlessExport {any}", .{win.standard.GetLastError()});
        return;
    }

    const hook = win.ui.windows_and_messaging.SetWindowsHookExA(win.ui.windows_and_messaging.WH_KEYBOARD, hookProc, dll, 0); // 0 is like ALL threads (which not very good lol), i will change it soon

    if (hook == null) {
        logger.err("Error during getting the hook {any}", .{win.standard.GetLastError()});
        return;
    }

    std.Thread.sleep(120 * std.time.ns_per_s);

    _ = win.ui.windows_and_messaging.UnhookWindowsHookEx(hook);

    return;
}
