const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const splitScalar = std.mem.splitScalar;
const ArrayList = std.ArrayList;
const parseInt = std.fmt.parseInt;
const math = std.math;

fn solve(target: i64, numbers: []i64) bool {
    const n = numbers.len;
    if (n == 0) {
        return target == 0;
    }
    if (solve(target - numbers[n - 1], numbers[0..n-1])) {
        return true;
    }
    if (@rem(target, numbers[numbers.len - 1]) == 0) {
        return solve(@divTrunc(target, numbers[numbers.len - 1]), numbers[0..n-1]);
    }
    return false;
}

pub fn part1(input: []const u8, allocator: Allocator) !i64 {
    var numbers = ArrayList(i64).init(allocator);
    defer numbers.deinit();

    var lines = splitScalar(u8, input, '\n');
    var test_values: i64 = 0;
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }
        var items = splitScalar(u8, line, ' ');
        const target_str = items.next().?;
        const target = try parseInt(i64, target_str[0..(target_str.len-1)], 10);
        try numbers.resize(0);
        while (items.next()) |item| {
            const number = try parseInt(i64, item, 10);
            try numbers.append(number);
        }
        if (solve(target, numbers.items)) {
            test_values += target;
        }
    }
    return test_values;
}

fn solve2(target: u64, numbers: []u64) bool {
    const n = numbers.len;
    if (n == 0) {
        return target == 0;
    }
    if (target > numbers[n - 1] and solve2(target - numbers[n - 1], numbers[0..n-1])) {
        return true;
    }
    if (@rem(target, numbers[numbers.len - 1]) == 0
            and solve2(@divTrunc(target, numbers[numbers.len - 1]), numbers[0..n-1])) {
        return true;
    }
    const mask = math.pow(u64, 10, 1 + math.log10(numbers[n - 1]));
    if (target % mask == numbers[n - 1]) {
        return solve2(@divTrunc(target, mask), numbers[0..n-1]);
    }
    return false;
}

pub fn part2(input: []const u8, allocator: Allocator) !i64 {
    var numbers = ArrayList(u64).init(allocator);
    defer numbers.deinit();

    var lines = splitScalar(u8, input, '\n');
    var test_values: u64 = 0;
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }
        var items = splitScalar(u8, line, ' ');
        const target_str = items.next().?;
        const target = try parseInt(u64, target_str[0..(target_str.len-1)], 10);
        try numbers.resize(0);
        while (items.next()) |item| {
            const number = try parseInt(u64, item, 10);
            try numbers.append(number);
        }
        if (solve2(target, numbers.items)) {
            test_values += target;
        }
    }
    return @intCast(test_values);
}

test "Tests" {
    const sample_input =
        \\190: 10 19
        \\3267: 81 40 27
        \\83: 17 5
        \\156: 15 6
        \\7290: 6 8 6 15
        \\161011: 16 10 13
        \\192: 17 8 14
        \\21037: 9 7 18 13
        \\292: 11 6 16 20
    ;
    const allocator = testing.allocator;
    try testing.expectEqual(3749, try part1(sample_input, allocator));
    try testing.expectEqual(11387, try part2(sample_input, allocator));
}
