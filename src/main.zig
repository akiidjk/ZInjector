//! The effective injector main
const std = @import("std");
const lib = @import("lib");
const logger = @import("logger");
const win = @import("win");

pub fn main() !void {
    var hProcess: ?*anyopaque = undefined;
    var abs_path: []u8 = undefined;
    const alloc: std.mem.Allocator = std.heap.page_allocator;
    const argv = try std.process.argsAlloc(alloc);
    const argc = argv.len;
    defer alloc.free(argv);

    if (argc < 3) {
        logger.err("usage: {s} <path-to-dll> <PID> or <process-name>", .{argv[0]});
        return;
    }

    const DLL_PATH = argv[1];
    defer alloc.free(abs_path);

    if (lib.isADigitsString(argv[2])) {
        const PID = try std.fmt.parseInt(u32, argv[2], 10);
        hProcess = win.threads.OpenProcess(win.threads.PROCESS_ALL_ACCESS, win.FALSE, PID);
        if (hProcess == null) {
            logger.err("Failed to handle the process not found or not accesible", .{});
            return;
        }
    } else {
        hProcess = win.GetHandleProcessByName(argv[2]);
        if (hProcess == null) {
            logger.err("Failed to handle the process not found or not accesible", .{});
            return;
        }
    }

    const isAbs = try lib.isAbsolutePath(DLL_PATH);
    if (!isAbs) {
        abs_path = try lib.getAbsPath(alloc, DLL_PATH);
    } else {
        abs_path = DLL_PATH;
    }

    //if we encounter a winapi error, print its exit code before exit
    errdefer {
        @setEvalBranchQuota(5000);
        const err = win.standard.GetLastError();
        logger.warn("failed with code 0x{s}: {}\n", .{ @errorFromInt(err), err });
    }

    const allocatedMem = win.mem.VirtualAllocEx(hProcess, null, abs_path.len + 1, (win.mem.VIRTUAL_ALLOCATION_TYPE{ .COMMIT = 1, .RESERVE = 1 }), win.mem.PAGE_READWRITE);
    if (allocatedMem == null) {
        logger.err("Failed to handle the memory of the process", .{});
        return;
    }

    logger.debug("Allocated memory: {?}", .{allocatedMem});

    _ = win.system.diagnostics.debug.WriteProcessMemory(hProcess, allocatedMem, abs_path.ptr, abs_path.len + 1, null);

    const kernel32Base = win.system.library_loader.GetModuleHandleA("kernel32.dll");
    if (kernel32Base == null) {
        logger.err("Failed to handle kernel module", .{});
        return;
    }

    const loadLibraryAddress = win.system.library_loader.GetProcAddress(kernel32Base, "LoadLibraryA");

    const hTread = win.threads.CreateRemoteThread(hProcess, null, 0, @ptrCast(loadLibraryAddress), allocatedMem, 0, null);
    if (hTread == null) {
        logger.err("Failed to create remote thread", .{});
    }

    _ = win.threads.WaitForSingleObject(hTread, win.INFINITE);
    _ = win.standard.CloseHandle(hProcess);
}
