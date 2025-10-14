//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const win32 = @import("win32");
const builtin = @import("builtin");
const logger = @import("logger");
const testing = std.testing;

pub fn bufferedPrint() !void {
    // Stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try stdout.flush(); // Don't forget to flush!
}

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "isAbsolutePath Linux machine" {
    if (comptime builtin.target.os.tag != .linux) return;
    try testing.expectEqual(true, isAbsolutePath("/home/user/pippo"));
    try testing.expectEqual(false, isAbsolutePath("home/user/pippo"));
    try testing.expectEqual(false, isAbsolutePath("./home/user/pippo"));
    try testing.expectEqual(false, isAbsolutePath(""));
}

test "isAbsolutePath Windows machine" {
    if (comptime builtin.target.os.tag != .windows) return;
    try testing.expectEqual(true, isAbsolutePath("C:\\Users\\pippo"));
    try testing.expectEqual(false, isAbsolutePath("Users\\pippo"));
    try testing.expectEqual(false, isAbsolutePath(".\\Users\\pippo"));
    try testing.expectEqual(true, isAbsolutePath("d:\\folder\\file.txt"));
    try testing.expectEqual(false, isAbsolutePath("C:/Users/pippo")); // forward slash invalid
    try testing.expectEqual(false, isAbsolutePath(""));
}

const OsError = error{NotSupported};
pub fn isAbsolutePath(path: [:0]const u8) !bool {
    const os = comptime builtin.target.os.tag;
    var lowerPath: [1024]u8 = undefined;
    _ = std.ascii.lowerString(&lowerPath, path);

    if (os == .windows) {
        if (std.ascii.isAscii(lowerPath[0]) and lowerPath.len > 0 and std.mem.eql(u8, ":\\", lowerPath[1..3])) {
            return true;
        } else {
            return false;
        }
    } else if (os == .linux) {
        if (std.ascii.isAscii(lowerPath[0]) and lowerPath.len > 0 and std.mem.eql(u8, lowerPath[0..1], "/")) {
            return true;
        } else {
            return false;
        }
    } else {
        return OsError.NotSupported;
    }
}

pub fn getAbsPath(alloc: std.mem.Allocator, path: [:0]const u8) ![]u8 {
    const cwd_path = try std.fs.cwd().realpathAlloc(alloc, ".");
    defer alloc.free(cwd_path);

    const abs_path = try std.fs.path.resolve(alloc, &.{
        cwd_path,
        path,
    });

    return abs_path;
}

test "isADigitsString test case" {
    try testing.expect(isADigitsString("1234") == true);
    try testing.expect(isADigitsString("") == false);
    try testing.expect(isADigitsString("    ") == false);
    try testing.expect(isADigitsString("palle") == false);
    try testing.expect(isADigitsString("02312") == true);
}

pub fn isADigitsString(string: [:0]const u8) bool {
    if (string.len <= 0) {
        return false;
    }
    for (string) |char| {
        if (!std.ascii.isDigit(char)) {
            return false;
        }
    }
    return true;
}
