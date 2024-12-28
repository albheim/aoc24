const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const common = @import("common");
const Vec = common.Vec2(usize);
const mecha = @import("mecha");
const gcd = std.math.gcd;

const coordinate_parser = mecha.combine(.{
    mecha.string("X").discard(),
    mecha.oneOf(.{
        mecha.ascii.char('+'),
        mecha.ascii.char('='),
    }).discard(),
    mecha.int(usize, .{}),
    mecha.string(", Y").discard(),
    mecha.oneOf(.{
        mecha.ascii.char('+'),
        mecha.ascii.char('='),
    }).discard(),
    mecha.int(usize, .{}),
}).map(mecha.toStruct(Vec));

const line_parser = mecha.combine(.{
    mecha.ascii.not(coordinate_parser).many(.{ .collect = false }).discard(),
    coordinate_parser,
    mecha.ascii.char('\n').opt().discard(),
});

const machines_parser = mecha.combine(.{
    mecha.manyN(line_parser, 3, .{}),
}).many(.{
    .separator = mecha.string("\n").discard(),
    .min = 1,
});

fn checkLeastCost(a: Vec, b: Vec, c: Vec, limit: ?usize) ?usize {
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

pub fn part1(input: []const u8, allocator: Allocator) !i64 {
    const machines = try machines_parser.parse(allocator, input);
    defer allocator.free(machines.value);

    var total_cost: usize = 0;
    for (machines.value) |machine| {
        if (checkLeastCost(machine[0], machine[1], machine[2], 100)) |val| {
            total_cost += val;
        }
    }
    return @intCast(total_cost);
}

pub fn part2(input: []const u8, allocator: Allocator) !i64 {
    const machines = try machines_parser.parse(allocator, input);
    defer allocator.free(machines.value);

    const target_offset = Vec{ .x = 10000000000000, .y = 10000000000000 };

    var total_cost: usize = 0;
    for (machines.value) |machine| {
        if (checkLeastCost(machine[0], machine[1], machine[2].add(target_offset), null)) |val| {
            total_cost += val;
        }
    }
    return @intCast(total_cost);
}

test "Tests" {
    const sample_input =
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
    const allocator = testing.allocator;
    try testing.expectEqual(480, try part1(sample_input, allocator));
    try testing.expectEqual(875318608908, try part2(sample_input, allocator));
}
