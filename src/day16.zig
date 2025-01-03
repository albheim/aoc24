const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const common = @import("common");
const FlexibleMatrix = common.FlexibleMatrix(u8);
const Vec = common.Vec2(u64);
const Order = std.math.Order;

const Rotation = enum {
    Up,
    Down,
    Left,
    Right,

    pub fn rotate(self: Rotation, turn: Turn) Rotation {
        return switch (turn) {
            .Left => switch (self) {
                .Up => .Left,
                .Down => .Right,
                .Left => .Down,
                .Right => .Up,
            },
            .Right => switch (self) {
                .Up => .Right,
                .Down => .Left,
                .Left => .Up,
                .Right => .Down,
            },
            .None => self,
        };
    }
};

const Turn = enum {
    Left,
    Right,
    None,
};

const Player = struct {
    pos: Vec,
    rot: Rotation,
    cost: u64,
    min_remaining: u64,

    pub fn step(self: Player, turn: Turn) Player {
        // Rotation
        const rot = self.rot.rotate(turn);
        const cost = if (turn == .None) self.cost else self.cost + 1000;
        // Step
        return .{
            .pos = switch (rot) {
                .Up => .{ .x = self.pos.x, .y = self.pos.y - 1 },
                .Down => .{ .x = self.pos.x, .y = self.pos.y + 1 },
                .Left => .{ .x = self.pos.x - 1, .y = self.pos.y },
                .Right => .{ .x = self.pos.x + 1, .y = self.pos.y },
            },
            .rot = rot,
            .cost = cost + 1,
            .min_remaining = 0, // Don't want to calculate this here
        };
    }
};

pub fn run(input: []const u8, allocator: Allocator) ![2]u64 {
    var grid = FlexibleMatrix.init(allocator);
    defer grid.deinit();

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) break;
        try grid.addRow(line);
    }

    return try solve_maze(grid, allocator);
}

fn solve_maze(grid: FlexibleMatrix, allocator: Allocator) ![2]u64 {
    var starting_player = Player{
        .pos = undefined,
        .rot = .Right,
        .cost = 0,
        .min_remaining = undefined,
    };
    var end: Vec = undefined;

    for (0..grid.rowCount()) |y| {
        for (0..grid.colCount()) |x| {
            switch (grid.get(y, x)) {
                'S' => starting_player.pos = .{ .x = x, .y = y },
                'E' => end = .{ .x = x, .y = y },
                else => {},
            }
        }
    }
    starting_player.min_remaining = minDistRemaining(starting_player, end);

    var players = std.PriorityQueue(
        Player, void,
        struct {
            fn f(_: void, a: Player, b: Player) Order {
                const a_tot = a.cost + a.min_remaining;
                const b_tot = b.cost + b.min_remaining;
                if (a_tot < b_tot) {
                    return Order.lt;
                } else if (a_tot > b_tot) {
                    return Order.gt;
                } else if (a.cost < b.cost) {
                    return Order.lt;
                } else if (a.cost > b.cost) {
                    return Order.gt;
                }
                return Order.eq;
            }
        }.f
    ).init(allocator, {});
    defer players.deinit();
    var visited = std.AutoHashMap(struct { pos: Vec, rot: Rotation }, bool).init(allocator);
    defer visited.deinit();

    try players.add(starting_player);
    try visited.put(.{ .pos = starting_player.pos, .rot = starting_player.rot }, true);

    var players_removed = std.ArrayList(Player).init(allocator);
    defer players_removed.deinit();

    while (!players.peek().?.pos.equal(end)) {
        const player = players.remove();
        try players_removed.append(Player{
            .pos = player.pos,
            .rot = player.rot,
            .cost = player.cost,
            .min_remaining = 0, // Don't what this for the check later
        });

        inline for (.{ Turn.Right, Turn.Left, Turn.None}) |turn| {
            var next = player.step(turn);
            // TODO have to separate visited check here
            if (grid.get(next.pos.y, next.pos.x) != '#' and !visited.contains(.{ .pos = next.pos, .rot = next.rot })) {
                next.min_remaining = minDistRemaining(next, end);
                try players.add(next);
                try visited.put(.{ .pos = next.pos, .rot = next.rot }, true);
            }
        }
    }

    var valid = std.AutoHashMap(Player, void).init(allocator);
    defer valid.deinit();

    const min_cost = players.peek().?.cost;

    while (players.peek().?.min_remaining == 0) {
        try valid.put(players.remove(), {});
    }

    while (players_removed.items.len > 0) {
        const player = players_removed.pop();

        // check if player + any step is in valid, if so add to valid
        for ([_]Turn{ Turn.Right, Turn.Left, Turn.None}) |turn| {
            const next = player.step(turn);
            if (valid.contains(next)) {
                try valid.put(player, {});
                break;
            }
        }
    }

    var counter = std.AutoHashMap(Vec, void).init(allocator);
    defer counter.deinit();

    var iter = valid.keyIterator();
    while (iter.next()) |player| {
        try counter.put(player.pos, {});
    }

    return .{ min_cost, counter.count() };
}

fn minDistRemaining(player: Player, end: Vec) u64 {
    const dx = if (end.x > player.pos.x) end.x - player.pos.x else player.pos.x - end.x;
    const dy = if (end.y > player.pos.y) end.y - player.pos.y else player.pos.y - end.y;

    var rotations: u64 = 0;
    switch (player.rot) {
        .Up => {
            if (player.pos.y < end.y) {
                rotations = 2;
            } else if (player.pos.x != end.x) {
                rotations = 1;
            }
        },
        .Down => {
            if (player.pos.y > end.y) {
                rotations = 2;
            } else if (player.pos.x != end.x) {
                rotations = 1;
            }
        },
        .Left => {
            if (player.pos.x < end.x) {
                rotations = 2;
            } else if (player.pos.y != end.y) {
                rotations = 1;
            }
        },
        .Right => {
            if (player.pos.x > end.x) {
                rotations = 2;
            } else if (player.pos.y != end.y) {
                rotations = 1;
            }
        },
    }

    return dx + dy + rotations * 1000;
}

test "Sample 1" {
    const allocator = testing.allocator;
    const input =
        \\###############
        \\#.......#....E#
        \\#.#.###.#.###.#
        \\#.....#.#...#.#
        \\#.###.#####.#.#
        \\#.#.#.......#.#
        \\#.#.#####.###.#
        \\#...........#.#
        \\###.#.#####.#.#
        \\#...#.....#.#.#
        \\#.#.#.###.#.#.#
        \\#.....#...#.#.#
        \\#.###.#.#.#.#.#
        \\#S..#.....#...#
        \\###############
    ;
    try testing.expectEqual(.{ 7036, 45 }, run(input, allocator));
}

test "Sample 2" {
    const allocator = testing.allocator;
    const input =
        \\#################
        \\#...#...#...#..E#
        \\#.#.#.#.#.#.#.#.#
        \\#.#.#.#...#...#.#
        \\#.#.#.#.###.#.#.#
        \\#...#.#.#.....#.#
        \\#.#.#.#.#.#####.#
        \\#.#...#.#.#.....#
        \\#.#.#####.#.###.#
        \\#.#.#.......#...#
        \\#.#.###.#####.###
        \\#.#.#...#.....#.#
        \\#.#.#.#####.###.#
        \\#.#.#.........#.#
        \\#.#.#.#########.#
        \\#S#.............#
        \\#################
    ;
    try testing.expectEqual(.{ 11048, 64 }, run(input, allocator));
}

test "Full" {
    const allocator = testing.allocator;
    const buffer = try allocator.alloc(u8, 20);
    defer allocator.free(buffer);
    const input_path = try std.fmt.bufPrint(buffer, "inputs/{any}.txt", .{ @This() });
    const input = try common.readFile(input_path, allocator);
    defer allocator.free(input);
    try testing.expectEqual(.{ 135512, 541 }, run(input, allocator));
}
