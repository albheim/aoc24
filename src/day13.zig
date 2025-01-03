const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const common = @import("common");
const Vec = common.Vec2(u64);
const mecha = @import("mecha");
const gcd = std.math.gcd;

const coordinate_parser = mecha.combine(.{
    mecha.string("X").discard(),
    mecha.oneOf(.{
        mecha.ascii.char('+'),
        mecha.ascii.char('='),
    }).discard(),
    mecha.int(u64, .{}),
    mecha.string(", Y").discard(),
    mecha.oneOf(.{
        mecha.ascii.char('+'),
        mecha.ascii.char('='),
    }).discard(),
    mecha.int(u64, .{}),
}).map(mecha.toStruct(Vec));

const machines_parser = mecha.combine(.{
    mecha.ascii.not(coordinate_parser).many(.{ .collect = false }).discard(),
    coordinate_parser,
    mecha.ascii.char('\n').opt().discard(),
}).manyN(3, .{}).many(.{
    .separator = mecha.ascii.char('\n').discard(),
    .min = 1,
});

pub fn run(input: []const u8, allocator: Allocator) ![2]u64 {
    const machines = try machines_parser.parse(allocator, input);
    defer allocator.free(machines.value);

    return .{
        try part1(machines.value),
        try part2(machines.value),
    };
}

fn checkLeastCost(a: Vec, b: Vec, c: Vec, limit: ?u64) ?u64 {
    const det: i64 = @as(i64, @intCast(a.x * b.y)) - @as(i64, @intCast(a.y * b.x));
    if (det != 0) {
        const nom_a = @as(i64, @intCast(b.y*c.x)) - @as(i64, @intCast(b.x*c.y));
        const nom_b = @as(i64, @intCast(a.x*c.y)) - @as(i64, @intCast(a.y*c.x));
        if (@rem(nom_a, det) == 0 and @rem(nom_b, det) == 0) {
            const push_a = @divExact(nom_a, det);
            const push_b = @divExact(nom_b, det);
            if (push_a < 0 or push_b < 0) {
                return null;
            }
            if (limit) |val| {
                if (push_a > val or push_b > val) {
                    return null;
                }
            }
            return @intCast(3 * push_a + 1 * push_b);
        }
    }
    return null;
}

fn part1(machines: [][3]Vec) !u64 {
    var total_cost: u64 = 0;
    for (machines) |machine| {
        if (checkLeastCost(machine[0], machine[1], machine[2], 100)) |val| {
            total_cost += val;
        }
    }
    return @intCast(total_cost);
}

fn part2(machines: [][3]Vec) !u64 {
    const target_offset = Vec{ .x = 10000000000000, .y = 10000000000000 };

    var total_cost: u64 = 0;
    for (machines) |machine| {
        if (checkLeastCost(machine[0], machine[1], machine[2].add(target_offset), null)) |val| {
            total_cost += val;
        }
    }
    return @intCast(total_cost);
}

test "Sample" {
    const allocator = testing.allocator;
    const input =
        \\Button A: X+94, Y+34
        \\Button B: X+22, Y+67
        \\Prize: X=8400, Y=5400
        \\
        \\Button A: X+26, Y+66
        \\Button B: X+67, Y+21
        \\Prize: X=12748, Y=12176
        \\
        \\Button A: X+17, Y+86
        \\Button B: X+84, Y+37
        \\Prize: X=7870, Y=6450
        \\
        \\Button A: X+69, Y+23
        \\Button B: X+27, Y+71
        \\Prize: X=18641, Y=10279
    ;
    try testing.expectEqual(.{ 480, 875318608908 }, try run(input, allocator));
}

test "Full" {
    const allocator = testing.allocator;
    const buffer = try allocator.alloc(u8, 20);
    defer allocator.free(buffer);
    const input_path = try std.fmt.bufPrint(buffer, "inputs/{any}.txt", .{ @This() });
    const input = try common.readFile(input_path, allocator);
    defer allocator.free(input);
    try testing.expectEqual(.{ 36250, 83232379451012 }, run(input, allocator));
}
