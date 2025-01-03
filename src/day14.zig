const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const common = @import("common");
const Vec = common.Vec2(i64);
const mecha = @import("mecha");
const builtin = @import("builtin");
const ArrayList = std.ArrayList;

const robots_parser = mecha.combine(.{
    mecha.string("p=").discard(),
    mecha.int(i64, .{})
        .manyN(2, .{
            .separator = mecha.ascii.char(',').discard()
        }).map(mecha.toStruct(Vec)),
    mecha.string(" v=").discard(),
    mecha.int(i64, .{})
        .manyN(2, .{
            .separator = mecha.ascii.char(',').discard()
        }).map(mecha.toStruct(Vec)),
}).map(mecha.toStruct(Robot)).many(.{
    .separator = mecha.ascii.char('\n').discard()
});

const Robot = struct {
    const Self = @This();
    pos: Vec,
    vel: Vec,
};

const Room = struct {
    const Self = @This();
    robots: []Robot,
    width: i64,
    height: i64,

    fn step(self: *Self, n: i64) void {
        for (self.robots) |*robot| {
            robot.pos = Vec{
                .x = @mod(robot.pos.x + n * robot.vel.x, self.width),
                .y = @mod(robot.pos.y + n * robot.vel.y, self.height),
            };
        }
    }

    fn toStr(self: Self, allocator: Allocator) ![]const u8 {
        var str: []u8 = try allocator.alloc(u8, @intCast(self.height * (self.width + 1)));
        var idx: u64 = 0;
        for (0..@intCast(self.height)) |_| {
            for (0..@intCast(self.width)) |_| {
                str[idx] = ' ';
                idx += 1;
            }
            str[idx] = '\n';
            idx += 1;
        }
        for (self.robots) |r| {
            idx = @intCast(r.pos.y * (self.width + 1) + r.pos.x);
            str[idx] = '#';
        }
        return str;
    }

    fn printRoom(self: Self) void {
        for (0..@intCast(self.height)) |y| {
            for (0..@intCast(self.width)) |x| {
                var found = false;
                for (self.robots) |r| {
                    if (r.pos.x == x and r.pos.y == y) {
                        found = true;
                        break;
                    }
                }
                if (found) {
                    print("#", .{});
                } else {
                    print(" ", .{});
                }
            }
            print("\n", .{});
        }
    }

    fn longestRowAndCol(self: Self, rows: ArrayList(ArrayList(bool))) Vec {
        for (0..@intCast(self.height)) |i| {
            for (0..@intCast(self.width)) |j| {
                rows.items[i].items[j] = false;
            }
        }

        for (self.robots) |robot| {
            rows.items[@intCast(robot.pos.y)].items[@intCast(robot.pos.x)] = true;
        }

        var row_len: u64 = 0;
        for (rows.items) |row| {
            var curr: u64 = 0;
            for (row.items) |item| {
                if (item) {
                    curr += 1;
                    if (curr > row_len) {
                        row_len = curr;
                    }
                }
            }
        }
        var col_len: u64 = 0;
        for (0..@intCast(self.width)) |i| {
            var curr: u64 = 0;
            for (0..@intCast(self.height)) |j| {
                if (rows.items[j].items[i]) {
                    curr += 1;
                    if (curr > col_len) {
                        col_len = curr;
                    }
                }
            }
        }

        return .{ .x = @intCast(row_len), .y = @intCast(col_len)};
    }

    fn calculateSafetyFactor(self: Self) u64 {
        var nw: u64 = 0;
        var sw: u64 = 0;
        var ne: u64 = 0;
        var se: u64 = 0;
        const halfwidth = @divExact(self.width - 1, 2);
        const halfheight = @divExact(self.height - 1, 2);
        for (self.robots) |robot| {
            if (robot.pos.x < halfwidth) {
                if (robot.pos.y < halfheight) {
                    nw += 1;
                } else if (robot.pos.y > halfheight) {
                    sw += 1;
                }
            } else if (robot.pos.x > halfwidth) {
                if (robot.pos.y < halfheight) {
                    ne += 1;
                } else if (robot.pos.y > halfheight) {
                    se += 1;
                }
            }
        }
        return nw * ne * sw * se;
    }
};

pub fn run(input: []const u8, allocator: Allocator) ![2]u64 {
    const width = 101;
    const height = 103;
    return .{
        try part1(input, width, height, allocator),
        try part2(input, width, height, allocator),
    };
}

fn part1(input: []const u8, width: i64, height: i64, allocator: Allocator) !u64 {
    const result = try robots_parser.parse(allocator, input);
    defer allocator.free(result.value);
    var room = Room{
        .robots = result.value,
        .width = width,
        .height = height,
    };
    room.step(100);
    return room.calculateSafetyFactor();
}

fn part2(input: []const u8, width: i64, height: i64, allocator: Allocator) !u64 {
    const result = try robots_parser.parse(allocator, input);
    defer allocator.free(result.value);
    var room = Room{
        .robots = result.value,
        .width = width,
        .height = height,
    };
    const min_height = 20;
    const min_width = 20;
    var curr: i64 = 0;
    var steps_w: i64 = -1;
    var steps_h: i64 = -1;


    var rows = ArrayList(ArrayList(bool)).init(allocator);
    defer {
        for (rows.items) |row| {
            row.deinit();
        }
        rows.deinit();
    }

    for (0..@intCast(room.height)) |_| {
        var row = ArrayList(bool).init(allocator);
        for (0..@intCast(room.width)) |_| {
            try row.append(false);
        }
        try rows.append(row);
    }

    // This is the main slow part, takes 7 ms while rest takes around 1 ms
    while (steps_w == -1 or steps_h == -1) : (curr += 1) {
        const wh = room.longestRowAndCol(rows);
        if (wh.x >= min_width) {
            steps_h = curr;
        }
        if (wh.y >= min_height) {
            steps_w = curr;
        }
        room.step(1);
    }

    while (true) {
        if (steps_w < steps_h) {
            room.step(steps_w - curr);
            curr = steps_w;
            steps_w += room.width;
        } else if (steps_h < steps_w) {
            room.step(steps_h - curr);
            curr = steps_h;
            steps_h += room.height;
        } else {
            room.step(steps_w - curr);
            curr = steps_w;
            break;
        }
    }
    return @intCast(curr);
}

test "Sample" {
    const allocator = testing.allocator;
    const input =
        \\p=0,4 v=3,-3
        \\p=6,3 v=-1,-3
        \\p=10,3 v=-1,2
        \\p=2,0 v=2,-1
        \\p=0,0 v=1,3
        \\p=3,0 v=-2,-2
        \\p=7,6 v=-1,-3
        \\p=3,0 v=-1,-2
        \\p=9,3 v=2,3
        \\p=7,3 v=-1,2
        \\p=2,4 v=2,-3
        \\p=9,5 v=-3,-3
    ;
    try testing.expectEqual(12, try part1(input, 11, 7, allocator));
}

test "Full" {
    const allocator = testing.allocator;
    const buffer = try allocator.alloc(u8, 20);
    defer allocator.free(buffer);
    const input_path = try std.fmt.bufPrint(buffer, "inputs/{any}.txt", .{ @This() });
    const input = try common.readFile(input_path, allocator);
    defer allocator.free(input);
    try testing.expectEqual(.{ 222208000, 7623 }, run(input, allocator));
}
