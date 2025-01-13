const std = @import("std");
const common = @import("common");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const Vec = common.Vec2(i64);

pub fn run(input: []const u8, allocator: Allocator) ![2]u64 {
    const path = try parse(input, allocator);
    defer allocator.free(path);
    return .{
        try solve(path, 2, 100),
        try solve(path, 20, 100),
    };
}

fn parse(input: []const u8, allocator: Allocator) ![]Vec {
    var path_tiles = std.AutoHashMap(Vec, i64).init(allocator);
    defer path_tiles.deinit();

    var lines = std.mem.splitScalar(u8, input, '\n');
    var row: i64 = 0;
    var col: i64 = 0;
    var start: Vec = undefined;
    var end: Vec = undefined;

    while (lines.next()) |line| : (row += 1) {
        if (line.len == 0) break;

        col = 0;
        for (line) |c| {
            switch (c) {
                'S' => {
                    try path_tiles.put(.{ .x = col, .y = row }, 0);
                    start = .{ .x = col, .y = row };
                },
                'E' => {
                    try path_tiles.put(.{ .x = col, .y = row }, -1);
                    end = .{ .x = col, .y = row };
                },
                '.' => {
                    try path_tiles.put(.{ .x = col, .y = row }, -1);
                },
                '#' => {},
                else => unreachable,
            }
            col += 1;
        }
    }

    var path = std.ArrayList(Vec).init(allocator);
    defer path.deinit();
    try path.append(start);
    var curr = start;
    var count: i64 = 0;
    while (!curr.equal(end)) {
        for ([4]Vec{ .{ .x = -1, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 1 } }) |dir| {
            const next = curr.add(dir);
            if (path_tiles.get(next)) |v| {
                if (v == -1) {
                    count += 1;
                    try path_tiles.put(next, count);
                    try path.append(next);
                    curr = next;
                    break;
                }
            }
        }
    }

    return path.toOwnedSlice();
}

fn solve(path: []Vec, cheat_length: i64, threshold: u64) !u64 {
    // TODO can make this more efficient for large mazes by only checking within cheat_length l1 radius of each point
    var counter: u64 = 0;
    for (0..path.len) |i| {
        for (i..path.len) |j| {
            const dist = path[i].diff(path[j]).l1norm();
            const cheat = @as(i64, @intCast(j - i)) - dist;
            if (dist <= cheat_length and cheat >= threshold) {
                counter += 1;
            }
        }
    }
    return counter;
}

test "Sample" {
    const allocator = testing.allocator;
    const input =
        \\###############
        \\#...#...#.....#
        \\#.#.#.#.#.###.#
        \\#S#...#.#.#...#
        \\#######.#.#.###
        \\#######.#.#...#
        \\#######.#.###.#
        \\###..E#...#...#
        \\###.#######.###
        \\#...###...#...#
        \\#.#####.#.###.#
        \\#.#...#.#.#...#
        \\#.#.#.#.#.#.###
        \\#...#...#...###
        \\###############
    ;
    const path = try parse(input, allocator);
    defer allocator.free(path);
    try testing.expectEqual(5, solve(path, 2, 20));
    try testing.expectEqual(285, solve(path, 20, 50));
}

test "Full" {
    const allocator = testing.allocator;
    const buffer = try allocator.alloc(u8, 20);
    defer allocator.free(buffer);
    const input_path = try std.fmt.bufPrint(buffer, "inputs/{any}.txt", .{@This()});
    const input = try common.readFile(input_path, allocator);
    defer allocator.free(input);
    try testing.expectEqual(.{ 1384, 1008542 }, run(input, allocator));
}
