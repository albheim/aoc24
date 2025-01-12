const std = @import("std");
const common = @import("common");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const Vec2 = common.Vec2;

const Player = struct {
    pos: Vec2(i64),
    dir: Vec2(i64),

    pub fn step(self: *Player, map: common.FlexibleMatrix(u8)) bool {
        var pos = self.pos.add(self.dir);
        while (pos.x >= 0 and pos.x < map.colCount() and pos.y >= 0 and pos.y < map.rowCount() and map.get(@intCast(pos.y), @intCast(pos.x)) == '#') {
            const tmp = self.dir.x;
            self.dir.x = -self.dir.y;
            self.dir.y = tmp;
            pos = self.pos.add(self.dir);
        }
        self.pos = pos;
        return pos.x >= 0 and pos.x < map.colCount() and pos.y >= 0 and pos.y < map.rowCount();
    }
};

pub fn run(input: []const u8, allocator: Allocator) ![2]u64 {
    return .{
        try part1(input, allocator),
        try part2(input, allocator),
    };
}

fn part1(input: []const u8, allocator: Allocator) !u64 {
    var map = common.FlexibleMatrix(u8).init(allocator);
    defer map.deinit();

    var lines = std.mem.splitScalar(u8, input, '\n');
    var player = Player{ .pos = .{ .x = 0, .y = 0 }, .dir = .{ .x = 0, .y = 0 } };
    var lineCount: u64 = 0;
    while (lines.next()) |line| : (lineCount += 1) {
        if (line.len == 0) {
            break;
        }
        try map.addRow(line);
        for (0..line.len) |i| {
            switch (line[i]) {
                '^', '>', 'v', '<' => |d| {
                    player.pos.x = @intCast(i);
                    player.pos.y = @intCast(lineCount);
                    player.dir = switch (d) {
                        '^' => .{ .x = 0, .y = -1 },
                        '>' => .{ .x = 1, .y = 0 },
                        'v' => .{ .x = 0, .y = 1 },
                        '<' => .{ .x = -1, .y = 0 },
                        else => unreachable,
                    };
                    break;
                },
                else => {},
            }
        }
    }
    var visited = std.AutoHashMap(Vec2(i64), void).init(allocator);
    defer visited.deinit();

    try visited.put(player.pos, {});
    while (player.step(map)) {
        try visited.put(player.pos, {});
    }

    return visited.count();
}

fn part2(input: []const u8, allocator: Allocator) !u64 {
    var map = common.FlexibleMatrix(u8).init(allocator);
    defer map.deinit();

    var lines = std.mem.splitScalar(u8, input, '\n');
    var player_start = Player{ .pos = .{ .x = 0, .y = 0 }, .dir = .{ .x = 0, .y = 0 } };
    var lineCount: u64 = 0;
    while (lines.next()) |line| : (lineCount += 1) {
        if (line.len == 0) {
            break;
        }
        try map.addRow(line);
        for (0..line.len) |i| {
            switch (line[i]) {
                '^', '>', 'v', '<' => |d| {
                    player_start.pos.x = @intCast(i);
                    player_start.pos.y = @intCast(lineCount);
                    player_start.dir = switch (d) {
                        '^' => .{ .x = 0, .y = -1 },
                        '>' => .{ .x = 1, .y = 0 },
                        'v' => .{ .x = 0, .y = 1 },
                        '<' => .{ .x = -1, .y = 0 },
                        else => unreachable,
                    };
                    break;
                },
                else => {},
            }
        }
    }

    var count: u64 = 0;

    var visited_loop = std.AutoHashMap(Player, void).init(allocator);
    defer visited_loop.deinit();

    var visited = std.AutoHashMap(Vec2(i64), void).init(allocator);
    defer visited.deinit();
    var player = player_start;
    while (player.step(map)) {
        if (visited.get(player.pos)) |_| {
            continue;
        }
        try visited.put(player.pos, {});
        const i: u64 = @intCast(player.pos.y);
        const j: u64 = @intCast(player.pos.x);
        if (map.get(i, j) == '.') {
            map.set(i, j, '#');
            if (try isLoop(map, player_start, &visited_loop)) {
                count += 1;
            }
            map.set(i, j, '.');
        }
    }
    return count;
}

fn isLoop(map: common.FlexibleMatrix(u8), player_start: Player, visited: *std.AutoHashMap(Player, void)) !bool {
    visited.clearRetainingCapacity();
    var player = player_start;
    try visited.put(player, {});
    while (player.step(map)) {
        if (visited.get(player)) |_| {
            return true;
        }
        try visited.put(player, {});
    }
    return false;
}

test "Sample" {
    const allocator = testing.allocator;
    const input =
        \\....#.....
        \\.........#
        \\..........
        \\..#.......
        \\.......#..
        \\..........
        \\.#..^.....
        \\........#.
        \\#.........
        \\......#...
    ;
    try testing.expectEqual(.{ 41, 6 }, run(input, allocator));
}

test "Full" {
    const allocator = testing.allocator;
    const buffer = try allocator.alloc(u8, 20);
    defer allocator.free(buffer);
    const input_path = try std.fmt.bufPrint(buffer, "inputs/{any}.txt", .{@This()});
    const input = try common.readFile(input_path, allocator);
    defer allocator.free(input);
    try testing.expectEqual(.{ 5461, 1836 }, run(input, allocator));
}
