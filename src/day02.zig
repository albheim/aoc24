const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const common = @import("common");
const parseInt = std.fmt.parseInt;

pub fn part1(input: []const u8, allocator: Allocator) !i64 {
    var reports = std.mem.split(u8, input, "\n");
    var safe_reports: i64 = 0;
    while (reports.next()) |report| {
        var levels_str = std.mem.tokenizeScalar(u8, report, ' ');
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

pub fn part2(input: []const u8, allocator: Allocator) !i64 {
    var reports = std.mem.split(u8, input, "\n");
    var safe_reports: i64 = 0;
    while (reports.next()) |report| {
        var levels_str = std.mem.tokenizeScalar(u8, report, ' ');
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

fn getIdx(idx: usize, removed: usize) usize {
    if (idx >= removed) {
        return idx + 1;
    }
    return idx;
}

fn check_levels(levels: []const i64, removed: usize) bool {
    var idx = getIdx(0, removed);
    var last = levels[idx];
    var direction: i64 = 0;
    var counter: usize = 1;
    idx = getIdx(counter, removed);
    while (idx < levels.len) {
        const num = levels[idx];
        const diff = num - last;
        const absdiff = common.abs(diff);
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

test "Testing" {
    const sample_input =
        \\7 6 4 2 1
        \\1 2 7 8 9
        \\9 7 6 2 1
        \\1 3 2 4 5
        \\8 6 4 4 1
        \\1 3 6 7 9
    ;
    const allocator = testing.allocator;
    try testing.expectEqual(2, try part1(sample_input, allocator));
    try testing.expectEqual(4, try part2(sample_input, allocator));
}
