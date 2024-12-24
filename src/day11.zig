const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const print = std.debug.print;

fn addToKey(map: *std.AutoHashMap(usize, usize), key: usize, val: usize) !void {
    if (map.getPtr(key)) |prev_val| {
        prev_val.* += val;
    } else {
        try map.put(key, val);
    }
}

fn blink(stones: std.AutoHashMap(usize, usize), allocator: Allocator) !std.AutoHashMap(usize, usize) {
    var new_stones = std.AutoHashMap(usize, usize).init(allocator);

    var iter = stones.iterator();
    while (iter.next()) |stone| {
        if (stone.key_ptr.* == 0) {
            try addToKey(&new_stones, 1, stone.value_ptr.*);
            continue;
        }

        const n = std.math.log10(stone.key_ptr.*) + 1;
        if (n % 2 == 0) {
            const mask = try std.math.powi(usize, 10, n / 2);
            try addToKey(&new_stones, stone.key_ptr.* / mask, stone.value_ptr.*);
            try addToKey(&new_stones, stone.key_ptr.* % mask, stone.value_ptr.*);
            continue;
        }
        try addToKey(&new_stones, 2024 * stone.key_ptr.*, stone.value_ptr.*);
    }

    return new_stones;
}

fn blink_n(input: []const u8, allocator: Allocator, n: usize) !i64 {
    var stones = std.AutoHashMap(usize, usize).init(allocator);

    var items = std.mem.splitScalar(u8, std.mem.trim(u8, input, "\n\r\t "), ' ');
    while (items.next()) |item| {
        const id = try std.fmt.parseInt(usize, item, 10);
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

    var tot: usize = 0;
    var iter = stones.valueIterator();
    while (iter.next()) |val| {
        tot += val.*;
    }

    stones.deinit();
    return @intCast(tot);
}

pub fn part1(input: []const u8, allocator: Allocator) !i64 {
    return blink_n(input, allocator, 25);
}

pub fn part2(input: []const u8, allocator: Allocator) !i64 {
    return blink_n(input, allocator, 75);
}

test "Tests" {
    const sample_input =
        \\125 17
    ;
    const allocator = testing.allocator;
    try testing.expectEqual(55312, try part1(sample_input, allocator));
}
