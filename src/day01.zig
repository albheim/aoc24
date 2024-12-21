const std = @import("std");
const common = @import("common");
const testing = std.testing;
const Allocator = std.mem.Allocator;

pub fn part1(input: []const u8, allocator: Allocator) !i64 {
    const parsed_lists = try parse(input, allocator);
    defer parsed_lists[0].deinit();
    defer parsed_lists[1].deinit();

    const as = parsed_lists[0].items;
    const bs = parsed_lists[1].items;
    std.mem.sort(i64, as, void{}, std.sort.asc(i64));
    std.mem.sort(i64, bs, void{}, std.sort.asc(i64));

    var tot: i64 = 0;

    for (as, bs) |a, b| {
        tot += common.abs(a - b);
    }

    return tot;
}

pub fn part2(input: []const u8, allocator: Allocator) !i64 {
    const parsed_lists = try parse(input, allocator);
    defer parsed_lists[0].deinit();
    defer parsed_lists[1].deinit();

    const as = parsed_lists[0].items;
    const bs = parsed_lists[1].items;

    var tot: i64 = 0;
    var acount = std.AutoHashMap(i64, i64).init(allocator);
    var bcount = std.AutoHashMap(i64, i64).init(allocator);
    defer acount.deinit();
    defer bcount.deinit();

    for (as, bs) |a, b| {
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
        tot += b * value * key;
    }

    return tot;
}

fn parse(input: []const u8, allocator: Allocator) ![2]std.ArrayList(i64) {
    var as = std.ArrayList(i64).init(allocator);
    var bs = std.ArrayList(i64).init(allocator);

    var lines = std.mem.split(u8, input, "\n");
    while (lines.next()) |line| {
        var parts = std.mem.tokenizeScalar(u8, line, ' ');
        const aa = parts.next().?;
        const bb = parts.next().?;
        const a = try std.fmt.parseInt(i64, aa, 10);
        const b = try std.fmt.parseInt(i64, bb, 10);

        try as.append(a);
        try bs.append(b);
    }
    return .{ as, bs };
}

test "Testing" {
    const sample_input =
        \\3   4
        \\4   3
        \\2   5
        \\1   3
        \\3   9
        \\3   3
    ;
    const allocator = testing.allocator;
    try testing.expect(try part1(sample_input, allocator) == 11);
    try testing.expect(try part2(sample_input, allocator) == 31);
}
