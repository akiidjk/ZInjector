const win32 = @import("win32");
const std = @import("std");
const logger = @import("logger");

pub const system = win32.system;
pub const threads = system.threading;
pub const mem = system.memory;
pub const standard = win32.foundation;
pub const services = win32.system.system_services;
pub const ui = win32.ui;

pub const FALSE = win32.everything.FALSE;
pub const TRUE = win32.everything.TRUE;
pub const INFINITE = win32.everything.INFINITE;

// Function signature
pub const WriteProcessMemory = system.diagnostics.debug.WriteProcessMemory;
pub const GetModuleHandleA = system.library_loader.GetModuleHandleA;
pub const GetProcAddress = system.library_loader.GetProcAddress;
pub const CreateToolhelp32Snapshot = system.diagnostics.tool_help.CreateToolhelp32Snapshot;
pub const Thread32First = system.diagnostics.tool_help.Thread32First;
pub const Thread32Next = system.diagnostics.tool_help.Thread32Next;
pub const GetThreadContext = system.diagnostics.debug.GetThreadContext;
pub const SetThreadContext = system.diagnostics.debug.SetThreadContext;

// Win constant/types
pub const THREADENTRY32 = system.diagnostics.tool_help.THREADENTRY32;
pub const TH32CS_SNAPTHREAD = system.diagnostics.tool_help.TH32CS_SNAPTHREAD;
pub const CONTEXT = system.diagnostics.debug.CONTEXT;
pub const CONTEXT_AMD64 = 0x100000;
pub const CONTEXT_INTEGER = (CONTEXT_AMD64 | 0x2);
pub const CONTEXT_FLOATING_POINT = (CONTEXT_AMD64 | 0x8);
pub const CONTEXT_CONTROL = (CONTEXT_AMD64 | 0x1);
pub const CONTEXT_FULL = (CONTEXT_CONTROL | CONTEXT_INTEGER | CONTEXT_FLOATING_POINT);
pub const CONTEXT_ALL: u32 = 0x001003FF;

pub const HANDLE = std.os.windows.HANDLE;
pub const DWORD = std.os.windows.DWORD;
pub const PVOID = std.os.windows.PVOID;
pub const HMODULE = std.os.windows.HMODULE;
pub const HINSTANCE = std.os.windows.HINSTANCE;
pub const HOOKPROC = ui.windows_and_messaging.HOOKPROC;

pub fn GetHandleProcessByName(name: [:0]const u8) ?*anyopaque {
    const allocator = std.heap.smp_allocator;
    var entry: system.diagnostics.tool_help.PROCESSENTRY32 = undefined;
    entry.dwSize = @sizeOf(system.diagnostics.tool_help.PROCESSENTRY32);

    const lowerCaseName = std.ascii.allocLowerString(allocator, name) catch |err| switch (err) {
        else => {
            logger.err("Error during toLowerString in lowerCaseName", .{});
            return null;
        },
    };
    defer allocator.free(lowerCaseName);
    logger.debug("Name: {s}", .{lowerCaseName});

    const snapshot = system.diagnostics.tool_help.CreateToolhelp32Snapshot(system.diagnostics.tool_help.TH32CS_SNAPPROCESS, 0);

    if (system.diagnostics.tool_help.Process32First(snapshot, &entry) == TRUE) {
        while (system.diagnostics.tool_help.Process32Next(snapshot, &entry) == TRUE) {
            const length = std.mem.len(@as([*:0]u8, @ptrCast(&entry.szExeFile)));
            const processName: []u8 = std.ascii.allocLowerString(allocator, entry.szExeFile[0..length]) catch |err| switch (err) {
                else => {
                    logger.err("Error during toLowerString in processName", .{});
                    return null;
                },
            };
            defer allocator.free(processName);
            logger.debug("Process founded: {s}", .{processName});
            if (std.mem.eql(u8, processName, lowerCaseName)) {
                const hProcess = threads.OpenProcess(threads.PROCESS_ALL_ACCESS, FALSE, entry.th32ProcessID);
                return hProcess;
            }
        }
    }
    return null;
}
