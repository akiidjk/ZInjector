const std = @import("std");
const win32 = @import("win32");

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
    hinstDLL: std.os.windows.HINSTANCE,
    fdwReason: std.os.windows.DWORD,
    lpvReserved: std.os.windows.LPVOID,
) callconv(.c) std.os.windows.BOOL {
    _ = lpvReserved;

    switch (fdwReason) {
        win32.system.system_services.DLL_PROCESS_ATTACH => {
            _ = win32.ui.windows_and_messaging.MessageBoxA(null, "PALLE ATTACCATE e ESEGUITE", "PALLONE", win32.ui.windows_and_messaging.MB_ICONEXCLAMATION);
        },
        win32.system.system_services.DLL_PROCESS_DETACH => {
            _ = win32.ui.windows_and_messaging.MessageBoxA(null, "PALLE STACCATE", "PALLONE", win32.ui.windows_and_messaging.MB_ICONEXCLAMATION);
        },
        win32.system.system_services.DLL_THREAD_ATTACH => {
            _ = win32.ui.windows_and_messaging.MessageBoxA(null, "PALLINE CREATE", "PALLONE", win32.ui.windows_and_messaging.MB_ICONEXCLAMATION);
        },
        win32.system.system_services.DLL_THREAD_DETACH => {
            _ = win32.ui.windows_and_messaging.MessageBoxA(null, "PALLE TERMINATE", "PALLONE", win32.ui.windows_and_messaging.MB_ICONEXCLAMATION);
        },
        else => {
            return win32.everything.FALSE;
        },
    }

    _ = hinstDLL;
    // if (fdwReason != win32.system.system_services.DLL_PROCESS_ATTACH) {
    //     return win32.everything.TRUE;
    // }

    // const handle_main_thread = win32.system.threading.CreateThread(
    //     null,
    //     0,
    //     win32MainThreadEntrypoint,
    //     hinstDLL,
    //     win32.system.threading.THREAD_CREATION_FLAGS{},
    //     null,
    // ) orelse {
    //     _ = win32.system.library_loader.FreeLibrary(@ptrCast(hinstDLL));
    //     return win32.everything.FALSE;
    // };

    // if (win32.foundation.CloseHandle(handle_main_thread) == win32.everything.FALSE) {
    //     return win32.everything.FALSE;
    // }

    return win32.everything.TRUE;
}

fn win32MainThreadEntrypoint(param: ?std.os.windows.LPVOID) callconv(.c) std.os.windows.DWORD {
    win32.system.library_loader.FreeLibraryAndExitThread(@ptrCast(@alignCast(param)), win32MainThread());
    unreachable;
}

fn win32MainThread() std.os.windows.DWORD {
    if (win32.system.console.AllocConsole() == win32.everything.FALSE) {
        return 1;
    }
    defer _ = win32.system.console.FreeConsole();

    std.debug.print("Hello from the other side~\n", .{});
    std.Thread.sleep(5 * std.time.ns_per_s);

    return 0;
}
