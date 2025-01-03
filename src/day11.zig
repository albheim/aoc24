const std = @import("std");
const common = @import("common");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const print = std.debug.print;

pub fn run(input: []const u8, allocator: Allocator) ![2]u64 {
    return .{
        try part1(input, allocator),
        try part2(input, allocator),
    };
}

fn addToKey(map: *std.AutoHashMap(u64, u64), key: u64, val: u64) !void {
    if (map.getPtr(key)) |prev_val| {
        prev_val.* += val;
    } else {
        try map.put(key, val);
    }
}

fn blink(stones: std.AutoHashMap(u64, u64), allocator: Allocator) !std.AutoHashMap(u64, u64) {
    var new_stones = std.AutoHashMap(u64, u64).init(allocator);

    var iter = stones.iterator();
    while (iter.next()) |stone| {
        if (stone.key_ptr.* == 0) {
            try addToKey(&new_stones, 1, stone.value_ptr.*);
            continue;
        }

        const n = std.math.log10(stone.key_ptr.*) + 1;
        if (n % 2 == 0) {
            const mask = try std.math.powi(u64, 10, n / 2);
            try addToKey(&new_stones, stone.key_ptr.* / mask, stone.value_ptr.*);
            try addToKey(&new_stones, stone.key_ptr.* % mask, stone.value_ptr.*);
            continue;
        }
        try addToKey(&new_stones, 2024 * stone.key_ptr.*, stone.value_ptr.*);
    }

    return new_stones;
}

fn blink_n(input: []const u8, allocator: Allocator, n: u64) !u64 {
    var stones = std.AutoHashMap(u64, u64).init(allocator);

    var items = std.mem.splitScalar(u8, std.mem.trim(u8, input, "\n\r\t "), ' ');
    while (items.next()) |item| {
        const id = try std.fmt.parseInt(u64, item, 10);
        if (stones.getPtr(id)) |val| {
            val.* += 1;
        } else {
            try stones.put(id, 1);
        }
    }

    for (0..n) |_| {
        const tmp = try blink(stones, allocator);
        stones.deinit();
        stones = tmp;
    }

    var tot: u64 = 0;
    var iter = stones.valueIterator();
    while (iter.next()) |val| {
        tot += val.*;
    }

    stones.deinit();
    return tot;
}

fn part1(input: []const u8, allocator: Allocator) !u64 {
    return blink_n(input, allocator, 25);
}

fn part2(input: []const u8, allocator: Allocator) !u64 {
    return blink_n(input, allocator, 75);
}

test "Sample" {
    const allocator = testing.allocator;
    const input =
        \\125 17
    ;
    try testing.expectEqual(55312, try part1(input, allocator));
}

test "Full" {
    const allocator = testing.allocator;
    const buffer = try allocator.alloc(u8, 20);
    defer allocator.free(buffer);
    const input_path = try std.fmt.bufPrint(buffer, "inputs/{any}.txt", .{ @This() });
    const input = try common.readFile(input_path, allocator);
    defer allocator.free(input);
    try testing.expectEqual(.{ 217812, 259112729857522 }, run(input, allocator));
}
