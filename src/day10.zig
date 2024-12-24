const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const common = @import("common");
const FlexibleMatrix = common.FlexibleMatrix;
const Vec = common.Vec2(usize);

fn search(mat: *FlexibleMatrix(u8), i: usize, j: usize, visited: *std.AutoHashMap(Vec, bool)) usize {
    if (visited.get(Vec{ .x=i, .y=j })) |_| {
        return 0;
    }
    visited.put(Vec{ .x=i, .y=j}, true) catch unreachable;
    if (mat.get(i, j) == '9') {
        return 1;
    }
    var found: usize = 0;
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

pub fn part1(input: []const u8, allocator: Allocator) !i64 {
    var mat = FlexibleMatrix(u8).init(allocator);
    defer mat.deinit();
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }
        try mat.addRow(line);
    }

    var trails: usize = 0;
    for (0..mat.colCount()) |i| {
        for (0..mat.rowCount()) |j| {
            if (mat.get(i, j) == '0') {
                var visited = std.AutoHashMap(Vec, bool).init(allocator);
                defer visited.deinit();
                trails += search(&mat, i, j, &visited);
            }
        }
    }

    return @intCast(trails);
}

fn search2(mat: *FlexibleMatrix(u8), i: usize, j: usize, visited: *std.AutoHashMap(Vec, usize)) usize {
    if (visited.get(Vec{ .x=i, .y=j })) |n| {
        return n;
    }
    if (mat.get(i, j) == '9') {
        return 1;
    }
    var found: usize = 0;
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
    visited.put(Vec{ .x=i, .y=j}, found) catch unreachable;
    return found;
}

pub fn part2(input: []const u8, allocator: Allocator) !i64 {
    var mat = FlexibleMatrix(u8).init(allocator);
    defer mat.deinit();
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }
        try mat.addRow(line);
    }


    var trails: usize = 0;
    for (0..mat.colCount()) |i| {
        for (0..mat.rowCount()) |j| {
            if (mat.get(i, j) == '0') {
                var visited = std.AutoHashMap(Vec, usize).init(allocator);
                defer visited.deinit();
                trails += search2(&mat, i, j, &visited);
            }
        }
    }

    return @intCast(trails);
}

test "Tests" {
    const sample_input =
        \\89010123
        \\78121874
        \\87430965
        \\96549874
        \\45678903
        \\32019012
        \\01329801
        \\10456732
    ;
    const allocator = testing.allocator;
    try testing.expectEqual(36, try part1(sample_input, allocator));
    try testing.expectEqual(81, try part2(sample_input, allocator));
}
