const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const common = @import("common");
const Vec = common.Vec2(usize);
const FlexibleMatrix = common.FlexibleMatrix(u8);

fn check_region(
    mat: *FlexibleMatrix,
    i: usize, j: usize,
    visited: *std.AutoHashMap(Vec, bool)
) struct { usize, usize } {
    if (visited.contains(.{ .x = i, .y = j })) {
        return .{ 0, 0 };
    }
    visited.put(.{ .x = i, .y = j }, true) catch unreachable;
    var sides: usize = 4;
    var area: usize = 1;

    if (i > 0 and mat.get(i - 1, j) == mat.get(i, j)) {
        const res = check_region(mat, i - 1, j, visited);
        area += res[0];
        sides = sides + res[1] - 1;
    }
    if (j > 0 and mat.get(i, j - 1) == mat.get(i, j)) {
        const res = check_region(mat, i, j - 1, visited);
        area += res[0];
        sides = sides + res[1] - 1;
    }
    if (i + 1 < mat.rowCount() and mat.get(i + 1, j) == mat.get(i, j)) {
        const res = check_region(mat, i + 1, j, visited);
        area += res[0];
        sides = sides + res[1] - 1;
    }
    if (j + 1 < mat.colCount() and mat.get(i, j + 1) == mat.get(i, j)) {
        const res = check_region(mat, i, j + 1, visited);
        area += res[0];
        sides = sides + res[1] - 1;
    }

    return .{ area, sides };
}

pub fn part1(input: []const u8, allocator: Allocator) !i64 {
    var mat = FlexibleMatrix.init(allocator);
    defer mat.deinit();
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }
        try mat.addRow(line);
    }

    var visited = std.AutoHashMap(Vec, bool).init(allocator);
    defer visited.deinit();
    var total_price: usize = 0;
    for (0..mat.colCount()) |i| {
        for (0..mat.rowCount()) |j| {
            if (!visited.contains(.{ .x = i, .y = j })) {
                const res = check_region(&mat, i, j, &visited);
                total_price += res[0] * res[1];
            }
        }
    }

    return @intCast(total_price);
}

fn check_region2(
    mat: *FlexibleMatrix,
    p: Vec,
    visited: *std.AutoHashMap(Vec, bool)
) struct { i64, i64 } {
    if (visited.contains(p)) {
        return .{ 0, 0 };
    }
    visited.put(p, true) catch unreachable;
    var corners: i64 = 0;
    var area: i64 = 1;

    const curr = mat.get(p.y, p.x);

    var above = false;
    var below = false;
    var left = false;
    var right = false;
    if (p.y > 0 and mat.get(p.y - 1, p.x) == curr) {
        above = true;
    }
    if (p.x > 0 and mat.get(p.y, p.x - 1) == curr) {
        left = true;
    }
    if (p.y + 1 < mat.rowCount() and mat.get(p.y + 1, p.x) == curr) {
        below = true;
    }
    if (p.x + 1 < mat.colCount() and mat.get(p.y, p.x + 1) == curr) {
        right = true;
    }

    if (above) {
        if (left and mat.get(p.y - 1, p.x - 1) != curr) {
            corners += 1;
        }
        if (right and mat.get(p.y - 1, p.x + 1) != curr) {
            corners += 1;
        }
    } else {
        if (!left) {
            corners += 1;
        }
        if (!right) {
            corners += 1;
        }
    }
    if (below) {
        if (left and mat.get(p.y + 1, p.x - 1) != curr) {
            corners += 1;
        }
        if (right and mat.get(p.y + 1, p.x + 1) != curr) {
            corners += 1;
        }
    } else {
        if (!left) {
            corners += 1;
        }
        if (!right) {
            corners += 1;
        }
    }

    if (above) {
        const res = check_region2(mat, Vec{ .x = p.x, .y = p.y - 1 }, visited);
        area += res[0];
        corners += res[1];
    }
    if (left) {
        const res = check_region2(mat, Vec{ .x = p.x - 1, .y = p.y }, visited);
        area += res[0];
        corners += res[1];
    }
    if (below) {
        const res = check_region2(mat, Vec{ .x = p.x, .y = p.y + 1 }, visited);
        area += res[0];
        corners += res[1];
    }
    if (right) {
        const res = check_region2(mat, Vec{ .x = p.x + 1, .y = p.y }, visited);
        area += res[0];
        corners += res[1];
    }

    return .{ area, corners };
}

pub fn part2(input: []const u8, allocator: Allocator) !i64 {
    var mat = FlexibleMatrix.init(allocator);
    defer mat.deinit();
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }
        try mat.addRow(line);
    }

    var visited = std.AutoHashMap(Vec, bool).init(allocator);
    defer visited.deinit();
    var total_price: i64 = 0;
    for (0..mat.colCount()) |i| {
        for (0..mat.rowCount()) |j| {
            const p = Vec{ .x = j, .y = i };
            if (!visited.contains(p)) {
                const res = check_region2(&mat, p, &visited);
                total_price += res[0] * res[1];
            }
        }
    }

    return total_price;
}

test "Tests" {
    const sample_input =
        \\RRRRIICCFF
        \\RRRRIICCCF
        \\VVRRRCCFFF
        \\VVRCCCJFFF
        \\VVVVCJJCFE
        \\VVIVCCJJEE
        \\VVIIICJJEE
        \\MIIIIIJJEE
        \\MIIISIJEEE
        \\MMMISSJEEE
    ;
    const allocator = testing.allocator;
    try testing.expectEqual(1930, try part1(sample_input, allocator));
    try testing.expectEqual(1206, try part2(sample_input, allocator));
}
