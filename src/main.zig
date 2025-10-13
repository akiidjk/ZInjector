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

    if (argc != 3) {
        err("usage: {s} <path-to-dll> <PID>", .{argv[0]});
        return;
    }

    const DLL_PATH = argv[1];
    const PID = try std.fmt.parseInt(u32, argv[2], 10);

    debug("DLL: {s}", .{DLL_PATH});
    debug("PID: {d}", .{PID});

    const hProcess = win32.system.threading.OpenProcess(win32.system.threading.PROCESS_ALL_ACCESS, win32.everything.FALSE, PID);
    if (hProcess == null) {
        err("Failed to handle the process not found or not accesible", .{});
        return;
    }

    const allocatedMem = win32.system.memory.VirtualAllocEx(hProcess, null, DLL_PATH.len + 1, (win32.system.memory.VIRTUAL_ALLOCATION_TYPE{ .COMMIT = 1, .RESERVE = 1 }), win32.system.memory.PAGE_READWRITE);
    if (allocatedMem == null) {
        err("Failed to handle the memory of the process", .{});
        return;
    }
    debug("Allocated memory: {?}", .{allocatedMem});

    _ = win32.system.diagnostics.debug.WriteProcessMemory(hProcess, allocatedMem, DLL_PATH.ptr, DLL_PATH.len + 1, null);

    const kernel32Base = win32.system.library_loader.GetModuleHandleA("kernel32.dll");
    if (kernel32Base == null) {
        err("Failed to handle kernel module", .{});
        return;
    }

    const loadLibraryAddress = win32.system.library_loader.GetProcAddress(kernel32Base, "LoadLibraryA");

    const hTread = win32.system.threading.CreateRemoteThread(hProcess, null, 0, @ptrCast(loadLibraryAddress), allocatedMem, 0, null);
    if (hTread == null) {
        err("Failed to create remote thread", .{});
    }

    _ = win32.system.threading.WaitForSingleObject(hTread, win32.everything.INFINITE);
    _ = win32.foundation.CloseHandle(hProcess);
}
