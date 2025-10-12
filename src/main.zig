//! The effective injector main
const std = @import("std");
const ZInjector = @import("ZInjector");
const win32 = @import("win32");

const debug = std.log.debug;
const info = std.log.info;
const warn = std.log.warn;
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

    const DLL_PATH = argv[1];
    const PID = try std.fmt.parseInt(u32, argv[2], 10);

    debug("DLL: {s}", .{DLL_PATH});
    debug("PID: {d}", .{PID});

    errdefer {
        @setEvalBranchQuota(5000);
        const errors = win32.foundation.GetLastError();
        warn("failed with code 0x{s}: {any}\n", .{ @tagName(errors), errors });
    }

    const hProcess = win32.system.threading.OpenProcess(win32.system.threading.PROCESS_ALL_ACCESS, win32.everything.FALSE, PID);
    if (hProcess == null) {
        err("Failed to handle the process not found or not accesible", .{});
        return;
    }
    defer _ = win32.foundation.CloseHandle(hProcess);

    const allocatedMem = win32.system.memory.VirtualAllocEx(hProcess, null, DLL_PATH.len, (win32.system.memory.VIRTUAL_ALLOCATION_TYPE{ .COMMIT = 1, .RESERVE = 1 }), win32.system.memory.PAGE_READWRITE);
    if (allocatedMem == null) {
        err("Failed to handle the memory of the process", .{});
        return;
    }
    debug("Allocated memory: {any}", .{allocatedMem});

    if (win32.system.diagnostics.debug.WriteProcessMemory(hProcess, allocatedMem, DLL_PATH.ptr, (DLL_PATH.len + 1) * 2, null) == 0) {
        return error.WPMPathCopyFailed;
    }

    const kernel32Base = win32.system.library_loader.GetModuleHandleA("kernel32.dll");
    if (kernel32Base == null) {
        err("Failed to handle kernel module", .{});
        return;
    }

    const loadLibraryAddress = win32.system.library_loader.GetProcAddress(kernel32Base, "LoadLibraryW");

    const hTread = win32.system.threading.CreateRemoteThread(hProcess, null, 0, @ptrCast(loadLibraryAddress), allocatedMem, 0, null);
    if (hTread == null) {
        err("Failed to create remote thread", .{});
    }

    info("Waiting for loading", .{});
    _ = win32.system.threading.WaitForSingleObject(hTread, win32.everything.INFINITE);
    info("finished the injection", .{});
}
