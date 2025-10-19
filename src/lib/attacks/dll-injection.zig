const std = @import("std");
const lib = @import("lib");
const win = @import("win");
const logger = @import("logger");

pub fn dllInjection(
    pid: ?u32,
    processName: ?[]u8,
    dllPath: []const u8,
) anyerror!void {
    const allocator: std.mem.Allocator = std.heap.page_allocator;

    var hProcess: ?*anyopaque = undefined;
    var abs_path: []const u8 = undefined;
    var tmp: [1024]u8 = undefined;

    const isAbs = try lib.isAbsolutePath(dllPath);
    if (!isAbs) {
        abs_path = try lib.getAbsPath(allocator, dllPath);
    } else {
        abs_path = dllPath;
    }
    defer allocator.free(abs_path);
    if (pid != null) {
        hProcess = win.threads.OpenProcess(win.threads.PROCESS_ALL_ACCESS, win.FALSE, pid.?);
        if (hProcess == null) {
            logger.err("Failed to handle the process by pid not found or not accesible", .{});
            return;
        }
    } else if (processName != null) {
        const processNameString = try std.fmt.bufPrintZ(&tmp, "{s}", .{processName.?});
        hProcess = win.GetHandleProcessByName(processNameString);
        if (hProcess == null) {
            logger.err("Failed to handle the process by name not found or not accesible", .{});
            return;
        }
    } else {
        logger.err("PID and ProcessName not specified error run the binary with --help", .{});
        return;
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

    _ = win.WriteProcessMemory(hProcess, allocatedMem, abs_path.ptr, abs_path.len + 1, null);

    const kernel32Base = win.GetModuleHandleA("kernel32.dll");
    if (kernel32Base == null) {
        logger.err("Failed to handle kernel module", .{});
        return;
    }

    const loadLibraryAddress = win.GetProcAddress(kernel32Base, "LoadLibraryA");

    const hTread = win.threads.CreateRemoteThread(hProcess, null, 0, @ptrCast(loadLibraryAddress), allocatedMem, 0, null);
    if (hTread == null) {
        logger.err("Failed to create remote thread", .{});
    }

    _ = win.threads.WaitForSingleObject(hTread, win.INFINITE);
    _ = win.standard.CloseHandle(hProcess);

    return;
}
