//! Evil dll to inject
const std = @import("std");
const win = @import("win");

pub fn DllMain(
    hinstDLL: std.os.windows.HINSTANCE,
    fdwReason: std.os.windows.DWORD,
    lpvReserved: std.os.windows.LPVOID,
) callconv(.c) std.os.windows.BOOL {
    _ = lpvReserved;

    if (fdwReason != win.system.system_services.DLL_PROCESS_ATTACH) {
        return win.TRUE;
    }

    const handle_main_thread = win.threads.CreateThread(
        null,
        0,
        win32MainThreadEntrypoint,
        hinstDLL,
        win.threads.THREAD_CREATION_FLAGS{},
        null,
    ) orelse {
        _ = win.system.library_loader.FreeLibrary(@ptrCast(hinstDLL));
        return win.FALSE;
    };

    if (win.standard.CloseHandle(handle_main_thread) == win.FALSE) {
        return win.FALSE;
    }

    return win.TRUE;
}

fn win32MainThreadEntrypoint(param: ?std.os.windows.LPVOID) callconv(.c) std.os.windows.DWORD {
    win.system.library_loader.FreeLibraryAndExitThread(@ptrCast(@alignCast(param)), win32MainThread());
    unreachable;
}

fn win32MainThread() std.os.windows.DWORD {
    if (win.system.console.AllocConsole() == win.FALSE) {
        return 1;
    }
    defer _ = win.system.console.FreeConsole();
    std.debug.print("Hello from the other side, take a cookie~\n", .{});
    std.Thread.sleep(5 * std.time.ns_per_s);

    return 0;
}
