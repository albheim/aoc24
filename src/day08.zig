const std = @import("std");
const common = @import("common");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const Vec = common.Vec2(i64);

const ParsedData = struct {
    const Self = @This();

    stations: std.AutoHashMap(u8, std.ArrayList(Vec)),
    width: i64,
    height: i64,

    fn parse(input: []const u8, allocator: Allocator) !Self {
        var stations = std.AutoHashMap(u8, std.ArrayList(Vec)).init(allocator);
        var height: u64 = 0;
        var width: u64 = 0;
        var lines = std.mem.splitScalar(u8, input, '\n');
        while (lines.next()) |line| {
            if (line.len == 0) {
                break;
            }
            for (0..line.len) |i| {
                if (line[i] != '.') {
                    const vec = Vec{ .x = @intCast(i), .y = @intCast(height) };
                    if (stations.getPtr(line[i])) |list| {
                        try list.append(vec);
                    } else {
                        var list = std.ArrayList(Vec).init(allocator);
                        try list.append(vec);
                        try stations.put(line[i], list);
                    }
                }
            }
            width = line.len;
            height += 1;
        }

        return ParsedData{
            .stations = stations,
            .width = @intCast(width),
            .height = @intCast(height),
        };
    }

    fn deinit(self: *ParsedData) void {
        var iter = self.stations.valueIterator();
        while (iter.next()) |list| {
            list.deinit();
        }
        self.stations.deinit();
    }
};

pub fn run(input: []const u8, allocator: Allocator) ![2]u64 {
    var data = try ParsedData.parse(input, allocator);
    defer data.deinit();

    return .{
        try part1(data, allocator),
        try part2(data, allocator),
    };
}

fn part1(data: ParsedData, allocator: Allocator) !u64 {
    var antinodes = std.AutoHashMap(Vec, void).init(allocator);
    defer antinodes.deinit();

    var iter = data.stations.iterator();
    while (iter.next()) |entry| {
        const list = entry.value_ptr.items;
        for (0..list.len) |i| {
            for (i + 1..list.len) |j| {
                const diff = list[i].diff(list[j]);
                for ([_]Vec{ list[i].add(diff), list[j].add(diff.scale(-1)) }) |a| {
                    if (a.isInside(data.width, data.height)) {
                        try antinodes.put(a, {});
                    }
                }
            }
        }
    }
    return antinodes.count();
}

fn part2(data: ParsedData, allocator: Allocator) !u64 {
    var antinodes = std.AutoHashMap(Vec, u64).init(allocator);
    defer antinodes.deinit();

    var iter = data.stations.iterator();
    while (iter.next()) |entry| {
        const list = entry.value_ptr.items;
        for (0..list.len) |i| {
            for (i + 1..list.len) |j| {
                var diff = list[i].diff(list[j]);
                const d: i64 = @intCast(std.math.gcd(@abs(diff.x), @abs(diff.y)));
                diff = Vec{ .x = @divFloor(diff.x, d), .y = @divFloor(diff.y, d) };
                var pos = list[i];
                while (pos.isInside(data.width, data.height)) : (pos = pos.add(diff)) {
                    try antinodes.put(pos, 1);
                }
                pos = list[i];
                diff = diff.scale(-1);
                while (pos.isInside(data.width, data.height)) : (pos = pos.add(diff)) {
                    try antinodes.put(pos, 1);
                }
            }
        }
    }

    return antinodes.count();
}

test "Sample" {
    const allocator = testing.allocator;
    const input =
        \\............
        \\........0...
        \\.....0......
        \\.......0....
        \\....0.......
        \\......A.....
        \\............
        \\............
        \\........A...
        \\.........A..
        \\............
        \\............
    ;
    try testing.expectEqual(.{ 14, 34 }, run(input, allocator));
}

test "Full" {
    const allocator = testing.allocator;
    const buffer = try allocator.alloc(u8, 20);
    defer allocator.free(buffer);
    const input_path = try std.fmt.bufPrint(buffer, "inputs/{any}.txt", .{@This()});
    const input = try common.readFile(input_path, allocator);
    defer allocator.free(input);
    try testing.expectEqual(.{ 394, 1277 }, run(input, allocator));
}
