const std = @import("std");
const win32 = @import("zigwin32/win32.zig");

// These checks aren't ~technically~ required, but they can help a lot to prevent
// weird build configurations from generating invalid executables and prevent
// headaches and wasted debugging.
// comptime {
//     if (builtin.os.tag != .windows) {
//         @compileError("target operating system must be windows");
//     }
//     if (builtin.output_mode != .Lib or builtin.link_mode != .Dynamic) {
//         @compileError("output executable format must be a shared/dynamic library");
//     }
// }

pub fn DllMain(
    hinstDLL: win32.foundation.HINSTANCE,
    fdwReason: win32.foundation.DWORD,
    lpvReserved: win32.foundation.LPVOID,
) callconv(win32.system.system_services.WINAPI) win32.foundation.BOOL {
    _ = lpvReserved;

    if (fdwReason != win32.system.system_services.DLL_PROCESS_ATTACH) {
        return win32.foundation.TRUE;
    }

    const handle_main_thread = win32.system.threading.CreateThread(
        null,
        0,
        win32MainThreadEntrypoint,
        hinstDLL,
        0,
        null,
    ) orelse {
        _ = win32.system.library_loader.FreeLibrary(@ptrCast(hinstDLL));
        return win32.foundation.FALSE;
    };

    if (win32.foundation.CloseHandle(handle_main_thread) == win32.foundation.FALSE) {
        return win32.foundation.FALSE;
    }

    return win32.foundation.TRUE;
}

fn win32MainThreadEntrypoint(param: win32.foundation.LPVOID) callconv(win32.system.system_services.WINAPI) win32.foundation.DWORD {
    win32.system.library_loader.FreeLibraryAndExitThread(@ptrCast(@alignCast(param)), win32MainThread());
    unreachable;
}

fn win32MainThread() win32.foundation.DWORD {
    if (win32.system.console.AllocConsole() == win32.foundation.FALSE) {
        return 1;
    }
    defer _ = win32.system.console.FreeConsole();

    std.debug.print("Hello from the other side~\n", .{});
    std.time.sleep(5 * std.time.ns_per_s);

    return 0;
}
