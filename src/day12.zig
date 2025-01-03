const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const common = @import("common");
const Vec = common.Vec2(u64);
const FlexibleMatrix = common.FlexibleMatrix(u8);

pub fn run(input: []const u8, allocator: Allocator) ![2]u64 {
    return .{
        try part1(input, allocator),
        try part2(input, allocator),
    };
}

fn check_region(
    mat: *FlexibleMatrix,
    i: u64, j: u64,
    visited: *std.AutoHashMap(Vec, void)
) struct { u64, u64 } {
    if (visited.contains(.{ .x = i, .y = j })) {
        return .{ 0, 0 };
    }
    visited.put(.{ .x = i, .y = j }, {}) catch unreachable;
    var sides: u64 = 4;
    var area: u64 = 1;

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

fn part1(input: []const u8, allocator: Allocator) !u64 {
    var mat = FlexibleMatrix.init(allocator);
    defer mat.deinit();
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }
        try mat.addRow(line);
    }

    var visited = std.AutoHashMap(Vec, void).init(allocator);
    defer visited.deinit();
    var total_price: u64 = 0;
    for (0..mat.colCount()) |i| {
        for (0..mat.rowCount()) |j| {
            if (!visited.contains(.{ .x = i, .y = j })) {
                const res = check_region(&mat, i, j, &visited);
                total_price += res[0] * res[1];
            }
        }
    }

    return total_price;
}

fn check_region2(mat: *FlexibleMatrix, p: Vec, visited: *std.AutoHashMap(Vec, void)) [2]u64 {
    if (visited.contains(p)) {
        return .{ 0, 0 };
    }
    visited.put(p, {}) catch unreachable;
    var corners: u64 = 0;
    var area: u64 = 1;

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

fn part2(input: []const u8, allocator: Allocator) !u64 {
    var mat = FlexibleMatrix.init(allocator);
    defer mat.deinit();
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }
        try mat.addRow(line);
    }

    var visited = std.AutoHashMap(Vec, void).init(allocator);
    defer visited.deinit();
    var total_price: u64 = 0;
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

test "Sample" {
    const allocator = testing.allocator;
    const input =
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
    try testing.expectEqual(.{ 1930, 1206 }, try run(input, allocator));
}

test "Full" {
    const allocator = testing.allocator;
    const buffer = try allocator.alloc(u8, 20);
    defer allocator.free(buffer);
    const input_path = try std.fmt.bufPrint(buffer, "inputs/{any}.txt", .{ @This() });
    const input = try common.readFile(input_path, allocator);
    defer allocator.free(input);
    try testing.expectEqual(.{ 1518548, 909564 }, run(input, allocator));
}
