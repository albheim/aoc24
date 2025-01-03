const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const common = @import("common");
const FlexibleMatrix = common.FlexibleMatrix;
const Vec = common.Vec2(u64);

pub fn run(input: []const u8, allocator: Allocator) ![2]u64 {
    return .{
        try part1(input, allocator),
        try part2(input, allocator),
    };
}

fn search(mat: *FlexibleMatrix(u8), i: u64, j: u64, visited: *std.AutoHashMap(Vec, void)) u64 {
    if (visited.contains(Vec{ .x = i, .y = j })) {
        return 0;
    }
    visited.put(Vec{ .x = i, .y = j }, {}) catch unreachable;
    if (mat.get(i, j) == '9') {
        return 1;
    }
    var found: u64 = 0;
    if (i > 0 and mat.get(i - 1, j) == mat.get(i, j) + 1) {
        found += search(mat, i - 1, j, visited);
    }
    if (j > 0 and mat.get(i, j - 1) == mat.get(i, j) + 1) {
        found += search(mat, i, j - 1, visited);
    }
    if (i + 1 < mat.rowCount() and mat.get(i + 1, j) == mat.get(i, j) + 1) {
        found += search(mat, i + 1, j, visited);
    }
    if (j + 1 < mat.colCount() and mat.get(i, j + 1) == mat.get(i, j) + 1) {
        found += search(mat, i, j + 1, visited);
    }
    return found;
}

fn part1(input: []const u8, allocator: Allocator) !u64 {
    var mat = FlexibleMatrix(u8).init(allocator);
    defer mat.deinit();
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }
        try mat.addRow(line);
    }

    var trails: u64 = 0;
    for (0..mat.colCount()) |i| {
        for (0..mat.rowCount()) |j| {
            if (mat.get(i, j) == '0') {
                var visited = std.AutoHashMap(Vec, void).init(allocator);
                defer visited.deinit();
                trails += search(&mat, i, j, &visited);
            }
        }
    }

    return trails;
}

fn search2(mat: *FlexibleMatrix(u8), i: u64, j: u64, visited: *std.AutoHashMap(Vec, u64)) u64 {
    if (visited.get(Vec{ .x = i, .y = j })) |n| {
        return n;
    }
    if (mat.get(i, j) == '9') {
        return 1;
    }
    var found: u64 = 0;
    if (i > 0 and mat.get(i - 1, j) == mat.get(i, j) + 1) {
        found += search2(mat, i - 1, j, visited);
    }
    if (j > 0 and mat.get(i, j - 1) == mat.get(i, j) + 1) {
        found += search2(mat, i, j - 1, visited);
    }
    if (i + 1 < mat.rowCount() and mat.get(i + 1, j) == mat.get(i, j) + 1) {
        found += search2(mat, i + 1, j, visited);
    }
    if (j + 1 < mat.colCount() and mat.get(i, j + 1) == mat.get(i, j) + 1) {
        found += search2(mat, i, j + 1, visited);
    }
    visited.put(Vec{ .x = i, .y = j }, found) catch unreachable;
    return found;
}

fn part2(input: []const u8, allocator: Allocator) !u64 {
    var mat = FlexibleMatrix(u8).init(allocator);
    defer mat.deinit();
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }
        try mat.addRow(line);
    }

    var trails: u64 = 0;
    for (0..mat.colCount()) |i| {
        for (0..mat.rowCount()) |j| {
            if (mat.get(i, j) == '0') {
                var visited = std.AutoHashMap(Vec, u64).init(allocator);
                defer visited.deinit();
                trails += search2(&mat, i, j, &visited);
            }
        }
    }

    return trails;
}

test "Sample" {
    const allocator = testing.allocator;
    const input =
        \\89010123
        \\78121874
        \\87430965
        \\96549874
        \\45678903
        \\32019012
        \\01329801
        \\10456732
    ;
    try testing.expectEqual(.{ 36, 81 }, run(input, allocator));
}

test "Full" {
    const allocator = testing.allocator;
    const buffer = try allocator.alloc(u8, 20);
    defer allocator.free(buffer);
    const input_path = try std.fmt.bufPrint(buffer, "inputs/{any}.txt", .{@This()});
    const input = try common.readFile(input_path, allocator);
    defer allocator.free(input);
    try testing.expectEqual(.{ 501, 1017 }, run(input, allocator));
}
