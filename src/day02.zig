const std = @import("std");
const common = @import("common");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const parseInt = std.fmt.parseInt;

pub fn run(input: []const u8, allocator: Allocator) ![2]u64 {
    const p1 = try part1(input, allocator);
    const p2 = try part2(input, allocator);
    return .{ p1, p2 };
}

fn part1(input: []const u8, allocator: Allocator) !u64 {
    var reports = std.mem.splitScalar(u8, input, '\n');
    var safe_reports: u64 = 0;
    while (reports.next()) |report| {
        var levels_str = std.mem.splitScalar(u8, report, ' ');
        var levels = std.ArrayList(i64).init(allocator);
        defer levels.deinit();
        while (levels_str.next()) |num_str| {
            try levels.append(try parseInt(i64, num_str, 10));
        }
        // Send to level checker
        if (check_levels(levels.items, levels.items.len)) {
            safe_reports += 1;
        }
    }
    return safe_reports;
}

fn part2(input: []const u8, allocator: Allocator) !u64 {
    var reports = std.mem.splitScalar(u8, input, '\n');
    var safe_reports: u64 = 0;
    while (reports.next()) |report| {
        var levels_str = std.mem.splitScalar(u8, report, ' ');
        var levels = std.ArrayList(i64).init(allocator);
        defer levels.deinit();
        while (levels_str.next()) |num_str| {
            try levels.append(try parseInt(i64, num_str, 10));
        }
        // Send to level checker
        if (check_levels(levels.items, levels.items.len)) {
            safe_reports += 1;
        } else {
            // Try removing one element
            for (0..levels.items.len) |i| {
                if (check_levels(levels.items, i)) {
                    safe_reports += 1;
                    break;
                }
            }
        }
    }
    return safe_reports;
}

fn getIdx(idx: u64, removed: u64) u64 {
    if (idx >= removed) {
        return idx + 1;
    }
    return idx;
}

fn check_levels(levels: []const i64, removed: u64) bool {
    var idx = getIdx(0, removed);
    var last = levels[idx];
    var direction: i64 = 0;
    var counter: u64 = 1;
    idx = getIdx(counter, removed);
    while (idx < levels.len) {
        const num = levels[idx];
        const diff = num - last;
        const absdiff = @abs(diff);
        if (absdiff < 1 or absdiff > 3) {
            return false;
        }
        const dir = std.math.sign(diff);
        if (direction == 0) {
            direction = dir;
        } else if (direction != dir) {
            return false;
        }
        last = num;
        counter += 1;
        idx = getIdx(counter, removed);
    }
    return true;
}

test "Sample" {
    const allocator = testing.allocator;
    const input =
        \\7 6 4 2 1
        \\1 2 7 8 9
        \\9 7 6 2 1
        \\1 3 2 4 5
        \\8 6 4 4 1
        \\1 3 6 7 9
    ;
    try testing.expectEqual(.{ 2, 4 }, run(input, allocator));
}

test "Full" {
    const allocator = testing.allocator;
    const buffer = try allocator.alloc(u8, 20);
    defer allocator.free(buffer);
    const input_path = try std.fmt.bufPrint(buffer, "inputs/{any}.txt", .{ @This() });
    const input = try common.readFile(input_path, allocator);
    defer allocator.free(input);
    try testing.expectEqual(.{ 510, 553 }, run(input, allocator));
}
