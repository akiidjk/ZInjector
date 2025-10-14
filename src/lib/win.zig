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
