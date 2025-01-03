const std = @import("std");
const common = @import("common");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const parseInt = std.fmt.parseInt;

pub fn run(input: []const u8, allocator: Allocator) ![2]u64 {
    return .{
        try part1(input, allocator),
        try part2(input, allocator),
    };
}

fn part1(input: []const u8, allocator: Allocator) !u64 {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var rules = std.AutoHashMap(u64, std.ArrayList(u64)).init(allocator);
    defer {
        var iter = rules.valueIterator();
        while (iter.next()) |list| {
            list.deinit();
        }
        rules.deinit();
    }
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }
        var numbers = std.mem.splitScalar(u8, line, '|');
        const a = try parseInt(u64, numbers.next().?, 10);
        const b = try parseInt(u64, numbers.next().?, 10);
        if (rules.getPtr(a)) |list| {
            try list.append(b);
        } else {
            var newList = std.ArrayList(u64).init(allocator);
            try newList.append(b);
            try rules.put(a, newList);
        }
    }
    var sum: u64 = 0;
    var numbersList = std.ArrayList(u64).init(allocator);
    defer numbersList.deinit();
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }
        var numbers = std.mem.splitScalar(u8, line, ',');
        var failed = false;
        numbersList.clearAndFree();
        skipLine: while (numbers.next()) |number| {
            const n = try parseInt(u64, number, 10);
            if (rules.get(n)) |list| {
                for (list.items) |rule| {
                    for (numbersList.items) |prev| {
                        if (prev == rule) {
                            failed = true;
                            break :skipLine;
                        }
                    }
                }
            }
            try numbersList.append(n);
        }
        if (!failed) {
            sum += numbersList.items[(numbersList.items.len - 1) / 2];
        }
    }
    return sum;
}

fn part2(input: []const u8, allocator: Allocator) !u64 {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var rules = std.AutoHashMap(u64, std.ArrayList(u64)).init(allocator);
    defer {
        var iter = rules.valueIterator();
        while (iter.next()) |list| {
            list.deinit();
        }
        rules.deinit();
    }
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }
        var numbers = std.mem.splitScalar(u8, line, '|');
        const a = try parseInt(u64, numbers.next().?, 10);
        const b = try parseInt(u64, numbers.next().?, 10);
        if (rules.getPtr(a)) |list| {
            try list.append(b);
        } else {
            var newList = std.ArrayList(u64).init(allocator);
            try newList.append(b);
            try rules.put(a, newList);
        }
    }
    var sum: u64 = 0;
    var numbersList = std.ArrayList(u64).init(allocator);
    defer numbersList.deinit();
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }
        var numbers = std.mem.splitScalar(u8, line, ',');
        var failed = false;
        numbersList.clearAndFree();
        while (numbers.next()) |number| {
            const n = try parseInt(u64, number, 10);
            var switched = false;
            if (rules.get(n)) |list| {
                done: for (numbersList.items, 0..) |prev, idx| {
                    for (list.items) |rule| {
                        if (prev == rule) {
                            try numbersList.insert(idx, n);
                            failed = true;
                            switched = true;
                            break :done;
                        }
                    }
                }
            }
            if (!switched) {
                try numbersList.append(n);
            }
        }
        if (failed) {
            sum += numbersList.items[(numbersList.items.len - 1) / 2];
        }
    }
    return sum;
}

test "Sample" {
    const allocator = testing.allocator;
    const input =
        \\47|53
        \\97|13
        \\97|61
        \\97|47
        \\75|29
        \\61|13
        \\75|53
        \\29|13
        \\97|29
        \\53|29
        \\61|53
        \\97|53
        \\61|29
        \\47|13
        \\75|47
        \\97|75
        \\47|61
        \\75|61
        \\47|29
        \\75|13
        \\53|13
        \\
        \\75,47,61,53,29
        \\97,61,53,29,13
        \\75,29,13
        \\75,97,47,61,53
        \\61,13,29
        \\97,13,75,29,47
    ;
    try testing.expectEqual(.{ 143, 123 }, run(input, allocator));
}

test "Full" {
    const allocator = testing.allocator;
    const buffer = try allocator.alloc(u8, 20);
    defer allocator.free(buffer);
    const input_path = try std.fmt.bufPrint(buffer, "inputs/{any}.txt", .{@This()});
    const input = try common.readFile(input_path, allocator);
    defer allocator.free(input);
    try testing.expectEqual(.{ 5955, 4030 }, run(input, allocator));
}
