const std = @import("std");

pub fn readFile(path: []const u8, allocator: *const std.mem.Allocator) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    const size = try file.getEndPos();
    const buffer = try allocator.alloc(u8, size);
    _ = try file.readAll(buffer);
    return buffer;
}

pub fn abs(a: i64) i64 {
    return if (a < 0) -a else a;
}
