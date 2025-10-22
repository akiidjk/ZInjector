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
pub fn isAbsolutePath(path: []const u8) !bool {
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

pub fn getAbsPath(alloc: std.mem.Allocator, path: []const u8) ![]u8 {
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

pub fn convertToCString(allocator: std.mem.Allocator, string: []const u8) [:0]const u8 {
    const fixedString = allocator.dupeZ(u8, string) catch |err| switch (err) {
        error.OutOfMemory => {
            return "";
        },
    };
    return fixedString;
}

// Xor plaintext with classic single bytes so each bytes is xored with a key of one byte
pub fn xorSingleBytes(allocator: std.mem.Allocator, plaintext: []const u8, key: u8) ![]u8 {
    const ciphertext = try allocator.alloc(u8, plaintext.len);
    var i: u32 = 0;
    for (plaintext) |char| {
        ciphertext[i] = char ^ key;
        i += 1;
    }
    return ciphertext;
}

test "Xor test" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var msg = "Ciao";
    var key: u8 = 0x4;
    var ciphertext = try xorSingleBytes(allocator, msg, key);

    defer allocator.free(ciphertext);
    _ = try testing.expectEqualStrings(
        "Gmek",
        ciphertext,
    );

    msg = "Gmek";
    key = 0x4;
    ciphertext = try xorSingleBytes(allocator, msg, key);
    _ = try testing.expectEqualStrings(
        "Ciao",
        ciphertext,
    );

    msg = "Ciao";
    key = 0x0;
    ciphertext = try xorSingleBytes(allocator, msg, key);
    _ = try testing.expectEqualStrings(
        "Ciao",
        ciphertext,
    );
}

// Xor plaintext with another string
pub fn xorMultiBytes(allocator: std.mem.Allocator, plaintext: []const u8, key: []const u8) ![]u8 {
    const ciphertext = try allocator.alloc(u8, plaintext.len);
    var i: u32 = 0;
    for (plaintext) |char| {
        ciphertext[i] = char ^ key[i % key.len];
        i += 1;
    }
    return ciphertext;
}

test "Text xor multibytes" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var msg: [:0]const u8 = "Prova";
    var key: [:0]const u8 = "Pippo";
    var ciphertext = try xorMultiBytes(allocator, msg, key);

    defer allocator.free(ciphertext);

    const expected1 = &[_]u8{ 0x00, 0x1b, 0x1f, 0x06, 0x0e };
    _ = try testing.expect(std.mem.eql(u8, expected1, ciphertext));

    msg = "ProvaProvaProvaProva";
    key = "Pippo";
    ciphertext = try xorMultiBytes(allocator, msg, key);

    const expected2 = &[_]u8{
        0x00, 0x1b, 0x1f, 0x06, 0x0e,
        0x00, 0x1b, 0x1f, 0x06, 0x0e,
        0x00, 0x1b, 0x1f, 0x06, 0x0e,
        0x00, 0x1b, 0x1f, 0x06, 0x0e,
    };
    _ = try testing.expect(std.mem.eql(u8, expected2, ciphertext));

    msg = "Ale";
    key = "PippoPippo";
    ciphertext = try xorMultiBytes(allocator, msg, key);

    const expected3 = &[_]u8{ 0x11, 0x05, 0x15 };
    _ = try testing.expect(std.mem.eql(u8, expected3, ciphertext));
}
