const std = @import("std");
const common = @import("common");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const splitScalar = std.mem.splitScalar;
const parseInt = std.fmt.parseInt;
const math = std.math;

pub fn run(input: []const u8, allocator: Allocator) ![2]u64 {
    return .{
        try part1(input, allocator),
        try part2(input, allocator),
    };
}

fn part1(input: []const u8, allocator: Allocator) !u64 {
    var numbers = ArrayList(i64).init(allocator);
    defer numbers.deinit();

    var lines = splitScalar(u8, input, '\n');
    var test_values: u64 = 0;
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }
        var items = splitScalar(u8, line, ' ');
        const target_str = items.next().?;
        const target = try parseInt(u64, target_str[0..(target_str.len - 1)], 10);
        try numbers.resize(0);
        while (items.next()) |item| {
            const number = try parseInt(i64, item, 10);
            try numbers.append(number);
        }
        if (solve_eq(@intCast(target), numbers.items)) {
            test_values += target;
        }
    }
    return test_values;
}

fn part2(input: []const u8, allocator: Allocator) !u64 {
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
        const target = try parseInt(u64, target_str[0..(target_str.len - 1)], 10);
        try numbers.resize(0);
        while (items.next()) |item| {
            const number = try parseInt(u64, item, 10);
            try numbers.append(number);
        }
        if (solve_eq2(target, numbers.items)) {
            test_values += target;
        }
    }
    return @intCast(test_values);
}

fn solve_eq(target: i64, numbers: []i64) bool {
    const n = numbers.len;
    if (n == 0) {
        return target == 0;
    }
    if (solve_eq(target - numbers[n - 1], numbers[0 .. n - 1])) {
        return true;
    }
    if (@rem(target, numbers[numbers.len - 1]) == 0) {
        return solve_eq(@divTrunc(target, numbers[numbers.len - 1]), numbers[0 .. n - 1]);
    }
    return false;
}

fn solve_eq2(target: u64, numbers: []u64) bool {
    const n = numbers.len;
    if (n == 0) {
        return target == 0;
    }
    if (target > numbers[n - 1] and solve_eq2(target - numbers[n - 1], numbers[0 .. n - 1])) {
        return true;
    }
    if (@rem(target, numbers[numbers.len - 1]) == 0 and solve_eq2(@divTrunc(target, numbers[numbers.len - 1]), numbers[0 .. n - 1])) {
        return true;
    }
    const mask = math.pow(u64, 10, 1 + math.log10(numbers[n - 1]));
    if (target % mask == numbers[n - 1]) {
        return solve_eq2(@divTrunc(target, mask), numbers[0 .. n - 1]);
    }
    return false;
}

test "Sample" {
    const allocator = testing.allocator;
    const input =
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
    try testing.expectEqual(.{ 3749, 11387 }, run(input, allocator));
}

test "Full" {
    const allocator = testing.allocator;
    const buffer = try allocator.alloc(u8, 20);
    defer allocator.free(buffer);
    const input_path = try std.fmt.bufPrint(buffer, "inputs/{any}.txt", .{@This()});
    const input = try common.readFile(input_path, allocator);
    defer allocator.free(input);
    try testing.expectEqual(.{ 4998764814652, 37598910447546 }, run(input, allocator));
}
