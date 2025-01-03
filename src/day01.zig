const std = @import("std");
const common = @import("common");
const testing = std.testing;
const sort = std.mem.sort;
const parseInt = std.fmt.parseInt;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn run(input: []const u8, allocator: Allocator) ![2]i64 {
    var as = ArrayList(i64).init(allocator);
    defer as.deinit();
    var bs = ArrayList(i64).init(allocator);
    defer bs.deinit();

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) break;

        var parts = std.mem.tokenizeScalar(u8, line, ' ');
        const a = try parseInt(i64, parts.next().?, 10);
        const b = try parseInt(i64, parts.next().?, 10);

        try as.append(a);
        try bs.append(b);
    }

    sort(i64, as.items, void{}, std.sort.asc(i64));
    sort(i64, bs.items, void{}, std.sort.asc(i64));

    var list_dist: i64 = 0;

    var similatiry_score: i64 = 0;
    var acount = std.AutoHashMap(i64, i64).init(allocator);
    defer acount.deinit();
    var bcount = std.AutoHashMap(i64, i64).init(allocator);
    defer bcount.deinit();

    for (as.items, bs.items) |a, b| {
        list_dist += @intCast(@abs(a - b));

        var aval = acount.get(a) orelse 0;
        aval += 1;
        try acount.put(a, aval);
        var bval = bcount.get(b) orelse 0;
        bval += 1;
        try bcount.put(b, bval);
    }

    var it = acount.iterator();
    while (it.next()) |entry| {
        const key = entry.key_ptr.*;
        const value = entry.value_ptr.*;
        const b = bcount.get(key) orelse 0;
        similatiry_score += b * value * key;
    }

    return .{ list_dist, similatiry_score };
}

test "Sample" {
    const allocator = testing.allocator;
    const input =
        \\3   4
        \\4   3
        \\2   5
        \\1   3
        \\3   9
        \\3   3
    ;
    try testing.expectEqual(.{ 11, 31 }, run(input, allocator));
}

test "Full" {
    const allocator = testing.allocator;
    const buffer = try allocator.alloc(u8, 20);
    defer allocator.free(buffer);
    const input_path = try std.fmt.bufPrint(buffer, "inputs/{any}.txt", .{ @This() });
    const input = try common.readFile(input_path, allocator);
    defer allocator.free(input);
    try testing.expectEqual(.{ 2264607, 19457120 }, run(input, allocator));
}
