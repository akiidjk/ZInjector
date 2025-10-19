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

pub fn GetHandleProcessByName(name: [:0]const u8) ?*anyopaque {
    var entry: system.diagnostics.tool_help.PROCESSENTRY32 = undefined;
    entry.dwSize = @sizeOf(system.diagnostics.tool_help.PROCESSENTRY32);

    logger.debug("Name: {s}", .{name});

    const snapshot = system.diagnostics.tool_help.CreateToolhelp32Snapshot(system.diagnostics.tool_help.TH32CS_SNAPPROCESS, 0);

    if (system.diagnostics.tool_help.Process32First(snapshot, &entry) == TRUE) {
        while (system.diagnostics.tool_help.Process32Next(snapshot, &entry) == TRUE) {
            const length = std.mem.len(@as([*:0]u8, @ptrCast(&entry.szExeFile)));
            const processName: []u8 = entry.szExeFile[0..length];
            logger.debug("Process founded: {s}", .{processName});
            if (std.mem.eql(u8, processName, name)) {
                const hProcess = threads.OpenProcess(threads.PROCESS_ALL_ACCESS, FALSE, entry.th32ProcessID);
                return hProcess;
            }
        }
    }
    return null;
}
