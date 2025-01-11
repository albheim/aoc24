const std = @import("std");
const common = @import("common");
const builtin = @import("builtin");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const Vec = common.Vec2(u64);
const ArrayList = std.ArrayList;
const parseInt = std.fmt.parseInt;
const splitScalar = std.mem.splitScalar;

pub fn run(input: []const u8, allocator: Allocator) !std.meta.Tuple(&.{ u64, []const u8 }) {
    const bytes = try parse(input, allocator);
    defer allocator.free(bytes);

    return .{ try part1(bytes[0..1024], 71, allocator), try part2(bytes, 71, allocator) };
}

fn parse(input: []const u8, allocator: Allocator) ![]Vec {
    var bytes = ArrayList(Vec).init(allocator);

    var lines = splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) break;
        var parts = splitScalar(u8, line, ',');
        try bytes.append(.{
            .x = try parseInt(u64, parts.next().?, 10),
            .y = try parseInt(u64, parts.next().?, 10),
        });
    }
    return bytes.toOwnedSlice();
}

const PartialSolve = struct {
    pos: Vec,
    steps: u64,
    min_remaining: u64,
};

fn dijkstra(bytes: []Vec, side: u64, allocator: Allocator) !?u64 {
    var map = std.AutoHashMap(Vec, void).init(allocator);
    defer map.deinit();
    for (bytes) |byte| {
        try map.put(byte, {});
    }

    var visited = std.AutoHashMap(Vec, void).init(allocator);
    defer visited.deinit();

    var pq = std.PriorityQueue(PartialSolve, void, struct {
        fn lessThan(_: void, a: PartialSolve, b: PartialSolve) std.math.Order {
            if (a.steps + a.min_remaining < b.steps + b.min_remaining) return .lt;
            if (a.steps + a.min_remaining > b.steps + b.min_remaining) return .gt;
            if (a.steps < b.steps) return .gt;
            if (a.steps > b.steps) return .lt;
            return .eq;
        }
    }.lessThan).init(allocator, {});
    defer pq.deinit();

    const start = Vec{ .x = 0, .y = 0 };
    const end = Vec{ .x = side - 1, .y = side - 1 };
    try pq.add(.{ .pos = start, .steps = 0, .min_remaining = end.diff(start).l1norm() });

    while (pq.count() != 0) {
        const curr = pq.remove();
        if (curr.pos.equal(end)) {
            return curr.steps;
        }
        try visited.put(curr.pos, {});
        if (curr.pos.x > 0) {
            const next = Vec{ .x = curr.pos.x - 1, .y = curr.pos.y };
            if (!map.contains(next) and !visited.contains(next)) {
                try pq.add(.{ .pos = next, .steps = curr.steps + 1, .min_remaining = end.diff(next).l1norm() });
            }
        }
        if (curr.pos.x + 1 < side) {
            const next = Vec{ .x = curr.pos.x + 1, .y = curr.pos.y };
            if (!map.contains(next) and !visited.contains(next)) {
                try pq.add(.{ .pos = next, .steps = curr.steps + 1, .min_remaining = end.diff(next).l1norm() });
            }
        }
        if (curr.pos.y > 0) {
            const next = Vec{ .x = curr.pos.x, .y = curr.pos.y - 1 };
            if (!map.contains(next) and !visited.contains(next)) {
                try pq.add(.{ .pos = next, .steps = curr.steps + 1, .min_remaining = end.diff(next).l1norm() });
            }
        }
        if (curr.pos.y + 1 < side) {
            const next = Vec{ .x = curr.pos.x, .y = curr.pos.y + 1 };
            if (!map.contains(next) and !visited.contains(next)) {
                try pq.add(.{ .pos = next, .steps = curr.steps + 1, .min_remaining = end.diff(next).l1norm() });
            }
        }
    }

    return null;
}

fn part1(bytes: []Vec, side: u64, allocator: Allocator) !u64 {
    return try dijkstra(bytes, side, allocator) orelse unreachable;
}

fn part2(bytes: []Vec, side: u64, allocator: Allocator) ![]const u8 {
    var min: u64 = 0;
    var max: u64 = bytes.len - 1;

    while (true) {
        if (min == max) break;
        const mid = (min + max) / 2;
        if (try dijkstra(bytes[0..mid], side, allocator) == null) {
            max = mid - 1;
        } else {
            min = mid + 1;
        }
    }
    return try std.fmt.allocPrint(allocator, "{d},{d}", .{ bytes[min].x, bytes[min].y });
}

test "Sample" {
    const allocator = testing.allocator;
    const input =
        \\5,4
        \\4,2
        \\4,5
        \\3,0
        \\2,1
        \\6,3
        \\2,4
        \\1,5
        \\0,6
        \\3,3
        \\2,6
        \\5,1
        \\1,2
        \\5,5
        \\2,5
        \\6,5
        \\1,4
        \\0,4
        \\6,4
        \\1,1
        \\6,1
        \\1,0
        \\0,5
        \\1,6
        \\2,0
    ;
    const bytes = try parse(input, allocator);
    defer allocator.free(bytes);
    try testing.expectEqual(22, part1(bytes[0..12], 7, allocator));
    const res = try part2(bytes, 7, allocator);
    defer allocator.free(res);
    try testing.expectEqualStrings("6,1", res);
}

test "Full" {
    const allocator = testing.allocator;
    const buffer = try allocator.alloc(u8, 20);
    defer allocator.free(buffer);
    const input_path = try std.fmt.bufPrint(buffer, "inputs/{any}.txt", .{@This()});
    const input = try common.readFile(input_path, allocator);
    defer allocator.free(input);
    const res = try run(input, allocator);
    defer allocator.free(res[1]);
    try testing.expectEqual(302, res[0]);
    try testing.expectEqualStrings("24,32", res[1]);
}
