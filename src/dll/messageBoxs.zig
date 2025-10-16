//! Evil dll to inject
const std = @import("std");
const win = @import("win");

pub fn DllMain(
    hinstDLL: std.os.windows.HINSTANCE,
    fdwReason: std.os.windows.DWORD,
    lpvReserved: std.os.windows.LPVOID,
) callconv(.c) std.os.windows.BOOL {
    _ = lpvReserved;

    switch (fdwReason) {
        win.services.DLL_PROCESS_ATTACH => {
            _ = win.ui.windows_and_messaging.MessageBoxA(null, "PALLE ATTACCATE e ESEGUITE", "PALLONE", win.ui.windows_and_messaging.MB_ICONEXCLAMATION);
        },
        win.services.DLL_PROCESS_DETACH => {
            _ = win.ui.windows_and_messaging.MessageBoxA(null, "PALLE CRAZY", "PALLONE", win.ui.windows_and_messaging.MB_ICONEXCLAMATION);
        },
        win.services.DLL_THREAD_ATTACH => {
            _ = win.ui.windows_and_messaging.MessageBoxA(null, "PALLINE CREATE", "PALLONE", win.ui.windows_and_messaging.MB_ICONEXCLAMATION);
        },
        win.services.DLL_THREAD_DETACH => {
            _ = win.ui.windows_and_messaging.MessageBoxA(null, "PALLE TERMINATE", "PALLONE", win.ui.windows_and_messaging.MB_ICONEXCLAMATION);
        },
        else => {
            return win.FALSE;
        },
    }

    _ = hinstDLL;

    return win.TRUE;
}
