const std = @import("std");
const common = @import("common");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const splitScalar = std.mem.splitScalar;
const print = std.debug.print;
const Vec2 = common.Vec2;

const Player = struct {
    pos: Vec2(i64),
    dir: Vec2(i64),

    pub fn step(self: *Player, map: [][]const u8) bool {
        var pos = self.pos.add(self.dir);
        while (pos.x >= 0 and pos.x < map[0].len
                and pos.y >= 0 and pos.y < map.len
                and map[@intCast(pos.y)][@intCast(pos.x)] == '#') {
            const tmp = self.dir.x;
            self.dir.x = -self.dir.y;
            self.dir.y = tmp;
            pos = self.pos.add(self.dir);
        }
        self.pos = pos;
        return pos.x >= 0 and pos.x < map[0].len and pos.y >= 0 and pos.y < map.len;
    }
};

pub fn part1(input: []const u8, allocator: Allocator) !i64 {
    var map = std.ArrayList([]const u8).init(allocator);
    defer map.deinit();

    var lines = splitScalar(u8, input, '\n');
    var player = Player{
        .pos = .{ .x = 0, .y = 0 },
        .dir = .{ .x = 0, .y = 0 }
    };
    var lineCount: usize = 0;
    while (lines.next()) |line| : (lineCount += 1) {
        if (line.len == 0) {
            break;
        }
        try map.append(line);
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
    var visited = std.AutoHashMap(Vec2(i64), usize).init(allocator);
    try visited.put(player.pos, 1);
    defer visited.deinit();
    while (player.step(map.items)) {
        try visited.put(player.pos, 1);
    }

    return visited.count();
}

fn isLoop(map: [][]const u8, player_start: Player, allocator: Allocator) !bool {
    var visited = std.AutoHashMap(Player, usize).init(allocator);
    defer visited.deinit();

    var player = player_start;
    try visited.put(player, 1);
    while (player.step(map)) {
        if (visited.get(player)) |_| {
            return true;
        }
        try visited.put(player, 1);
    }
    return false;
}

pub fn part2(input: []const u8, allocator: Allocator) !i64 {
    var map_lines = std.ArrayList([]const u8).init(allocator);
    defer map_lines.deinit();

    var lines = splitScalar(u8, input, '\n');
    var player_start = Player{
        .pos = .{ .x = 0, .y = 0 },
        .dir = .{ .x = 0, .y = 0 }
    };
    var lineCount: usize = 0;
    while (lines.next()) |line| : (lineCount += 1) {
        if (line.len == 0) {
            break;
        }
        try map_lines.append(line);
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

    var map = map_lines.items;
    var count: i64 = 0;

    var visited = std.AutoHashMap(Vec2(i64), usize).init(allocator);
    defer visited.deinit();
    var player = player_start;
    while (player.step(map)) {
        if (visited.get(player.pos)) |_| {
            continue;
        }
        try visited.put(player.pos, 1);
        const i: usize = @intCast(player.pos.y);
        const j: usize = @intCast(player.pos.x);
        if (map[i][j] == '.') {
            var tmp = try allocator.alloc(u8, map[0].len);
            defer allocator.free(tmp);
            for (0..map[0].len) |k| {
                if (k == j) {
                    tmp[k] = '#';
                } else {
                    tmp[k] = map[i][k];
                }
            }
            const old = map[i];
            map[i] = tmp;
            if (try isLoop(map, player_start, allocator)) {
                count += 1;
            }
            map[i] = old;
        }
    }
    return count;
}

test "Tests" {
    const sample_input =
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
    const allocator = testing.allocator;
    try testing.expectEqual(41, try part1(sample_input, allocator));
    try testing.expectEqual(6, try part2(sample_input, allocator));
}
