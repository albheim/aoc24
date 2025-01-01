const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const common = @import("common");
const FlexibleMatrix = common.FlexibleMatrix(u8);
const Vec = common.Vec2(i64);

const Day15Errors = error{
    InvalidTile,
    InvalidMove,
};

const up = Vec{ .x = 0, .y = -1 };
const down = Vec{ .x = 0, .y = 1 };
const left = Vec{ .x = -1, .y = 0 };
const right = Vec{ .x = 1, .y = 0 };

fn step(grid: FlexibleMatrix, pos: Vec, dir: Vec) !bool {
    const new_pos = pos.add(dir);
    switch (grid.get(@intCast(new_pos.y), @intCast(new_pos.x))) {
        'O' => {
            const possible = try step(grid, new_pos, dir);
            if (possible) {
                grid.set(@intCast(new_pos.y), @intCast(new_pos.x), 'O');
            }
            return possible;
        },
        '#' => return false,
        '.' => {
            grid.set(@intCast(new_pos.y), @intCast(new_pos.x), 'O');
            return true;
        },
        else => return Day15Errors.InvalidTile,
    }
}

fn run(grid: FlexibleMatrix, moves: std.ArrayList(u8)) !void {
    var pos: Vec = undefined;
    for (0..grid.rowCount()) |y| {
        for (0..grid.colCount()) |x| {
            if (grid.get(@intCast(y), @intCast(x)) == '@') {
                pos.x = @intCast(x);
                pos.y = @intCast(y);
                break;
            }
        }
    }

    for (moves.items) |move| {
        switch (move) {
            'v' => if (try step(grid, pos, down)) {
                grid.set(@intCast(pos.y), @intCast(pos.x), '.');
                pos = pos.add(down);
                grid.set(@intCast(pos.y), @intCast(pos.x), '@');
            },
            '^' => if (try step(grid, pos, up)) {
                grid.set(@intCast(pos.y), @intCast(pos.x), '.');
                pos = pos.add(up);
                grid.set(@intCast(pos.y), @intCast(pos.x), '@');
            },
            '<' => if (try step(grid, pos, left)) {
                grid.set(@intCast(pos.y), @intCast(pos.x), '.');
                pos = pos.add(left);
                grid.set(@intCast(pos.y), @intCast(pos.x), '@');
            },
            '>' => if (try step(grid, pos, right)) {
                grid.set(@intCast(pos.y), @intCast(pos.x), '.');
                pos = pos.add(right);
                grid.set(@intCast(pos.y), @intCast(pos.x), '@');
            },
            else => return Day15Errors.InvalidMove,
        }
    }
}

fn scoreGrid(grid: FlexibleMatrix, box_token: u8) i64 {
    var score: usize = 0;
    for (0..grid.rowCount()) |y| {
        for (0..grid.colCount()) |x| {
            if (grid.get(y, x) == box_token) {
                score += 100 * y + x;
            }
        }
    }
    return @intCast(score);
}


pub fn part1(input: []const u8, allocator: Allocator) !i64 {
    var grid = FlexibleMatrix.init(allocator);
    defer grid.deinit();

    var moves = std.ArrayList(u8).init(allocator);
    defer moves.deinit();

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) break;
        try grid.addRow(line);
    }
    while (lines.next()) |line| {
        if (line.len == 0) break;
        try moves.appendSlice(line);
    }

    try run(grid, moves);

    return scoreGrid(grid, 'O');
}

fn stepupdown(grid: FlexibleMatrix, pos: Vec, dir: Vec, allocator: Allocator) !bool {
    var boxes = std.ArrayList(Vec).init(allocator);
    defer boxes.deinit();
    var added = std.AutoHashMap(Vec, void).init(allocator);
    defer added.deinit();

    var next = pos.add(dir);
    switch (grid.get(@intCast(next.y), @intCast(next.x))) {
        '[' => {
            try boxes.append(next);
            try boxes.append(next.add(right));
        },
        ']' => {
            try boxes.append(next);
            try boxes.append(next.add(left));
        },
        '#' => return false,
        '.' => {},
        else => return Day15Errors.InvalidTile,
    }

    var idx: usize = 0;
    var possible = true;
    var other: Vec = undefined;
    while (idx < boxes.items.len) : (idx += 1) {
        const curr = boxes.items[idx];
        next = curr.add(dir);

        switch (grid.get(@intCast(next.y), @intCast(next.x))) {
            ']' => {
                other = next.add(left);
            },
            '[' => {
                other = next.add(right);
            },
            '#' => {
                possible = false;
                break;
            },
            '.' => continue,
            else => return Day15Errors.InvalidTile,
        }

        if (added.contains(next)) continue;

        try boxes.append(next);
        try boxes.append(other);
        try added.put(next, {});
        try added.put(other, {});
    }

    if (possible) {
        // Move boxes
        var i = boxes.items.len;
        while (i > 0) {
            i -= 1;

            const orig = boxes.items[i];
            const new = orig.add(dir);
            grid.set(@intCast(new.y), @intCast(new.x), grid.get(@intCast(orig.y), @intCast(orig.x)));
            grid.set(@intCast(orig.y), @intCast(orig.x), '.');
        }

        // Move player
        grid.set(@intCast(pos.y), @intCast(pos.x), '.');
        next = pos.add(dir);
        grid.set(@intCast(next.y), @intCast(next.x), '@');
    }
    return possible;
}

fn stepleft(grid: FlexibleMatrix, pos: Vec) !bool {
    switch (grid.get(@intCast(pos.y), @intCast(pos.x))) {
        ']' => {
            const leftside = pos.add(left);
            const new_slot = leftside.add(left);
            const possible = try stepleft(grid, new_slot);
            if (possible) {
                grid.set(@intCast(new_slot.y), @intCast(new_slot.x), '[');
                grid.set(@intCast(leftside.y), @intCast(leftside.x), ']');
            }
            return possible;
        },
        '@' => {
            const new_slot = pos.add(left);
            const possible = try stepleft(grid, new_slot);
            if (possible) {
                grid.set(@intCast(new_slot.y), @intCast(new_slot.x), '@');
                grid.set(@intCast(pos.y), @intCast(pos.x), '.');
            }
            return possible;
        },
        '#' => return false,
        '.' => return true,
        else => return Day15Errors.InvalidTile,
    }
}

fn stepright(grid: FlexibleMatrix, pos: Vec) !bool {
    switch (grid.get(@intCast(pos.y), @intCast(pos.x))) {
        '[' => {
            const rightside = pos.add(right);
            const new_slot = rightside.add(right);
            const possible = try stepright(grid, new_slot);
            if (possible) {
                grid.set(@intCast(new_slot.y), @intCast(new_slot.x), ']');
                grid.set(@intCast(rightside.y), @intCast(rightside.x), '[');
            }
            return possible;
        },
        '@' => {
            const new_slot = pos.add(right);
            const possible = try stepright(grid, new_slot);
            if (possible) {
                grid.set(@intCast(new_slot.y), @intCast(new_slot.x), '@');
                grid.set(@intCast(pos.y), @intCast(pos.x), '.');
            }
            return possible;
        },
        '#' => return false,
        '.' => return true,
        else => return Day15Errors.InvalidTile,
    }
}

fn run2(grid: FlexibleMatrix, moves: std.ArrayList(u8), allocator: Allocator) !void {
    var pos: Vec = undefined;
    for (0..grid.rowCount()) |y| {
        for (0..grid.colCount()) |x| {
            if (grid.get(@intCast(y), @intCast(x)) == '@') {
                pos.x = @intCast(x);
                pos.y = @intCast(y);
                break;
            }
        }
    }

    for (moves.items) |move| {
        switch (move) {
            'v' => if (try stepupdown(grid, pos, down, allocator)) {
                pos = pos.add(down);
            },
            '^' => if (try stepupdown(grid, pos, up, allocator)) {
                pos = pos.add(up);
            },
            '<' => if (try stepleft(grid, pos)) {
                pos = pos.add(left);
            },
            '>' => if (try stepright(grid, pos)) {
                pos = pos.add(right);
            },
            else => return Day15Errors.InvalidMove,
        }
    }
}

pub fn part2(input: []const u8, allocator: Allocator) !i64 {
    var grid = FlexibleMatrix.init(allocator);
    defer grid.deinit();

    var moves = std.ArrayList(u8).init(allocator);
    defer moves.deinit();

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) break;
        for (line) |c| {
            switch (c) {
                '#', '.' => {
                    try grid.addItem(c);
                    try grid.addItem(c);
                },
                '@' => {
                    try grid.addItem('@');
                    try grid.addItem('.');
                },
                'O' => {
                    try grid.addItem('[');
                    try grid.addItem(']');
                },
                else => return std.debug.panic("Invalid character encountered in input", .{}),
            }
        }
        grid.nextRow();
    }

    while (lines.next()) |line| {
        if (line.len == 0) break;
        try moves.appendSlice(line);
    }

    try run2(grid, moves, allocator);

    return scoreGrid(grid, '[');
}

test "Tests" {
    const sample_input_small =
        \\########
        \\#..O.O.#
        \\##@.O..#
        \\#...O..#
        \\#.#.O..#
        \\#...O..#
        \\#......#
        \\########
        \\
        \\<^^>>>vv<v>>v<<
    ;
    const sample_input_large =
        \\##########
        \\#..O..O.O#
        \\#......O.#
        \\#.OO..O.O#
        \\#..O@..O.#
        \\#O#..O...#
        \\#O..O..O.#
        \\#.OO.O.OO#
        \\#....O...#
        \\##########
        \\
        \\<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
        \\vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
        \\><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
        \\<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
        \\^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
        \\^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
        \\>^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^
        \\<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>
        \\^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>
        \\v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^
    ;
    const allocator = testing.allocator;
    try testing.expectEqual(2028, try part1(sample_input_small, allocator));
    try testing.expectEqual(10092, try part1(sample_input_large, allocator));
    try testing.expectEqual(9021, try part2(sample_input_large, allocator));
}
