const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const mecha = @import("mecha");
const print = std.debug.print;

const exprMul = mecha.combine(.{
    mecha.string("mul(").discard(),
    mecha.int(i64, .{}).manyN(2, .{ .separator = mecha.string(",").discard() }),
    mecha.string(")").discard(),
});

const exprP1 = mecha.combine(.{
    mecha.ascii.not(exprMul).many(.{ .collect = false }).discard(),
    exprMul,
}).many(.{});

pub fn part1(input: []const u8, allocator: Allocator) !i64 {
    const parsed = try exprP1.parse(allocator, input);
    defer allocator.free(parsed.value);

    var sum: i64 = 0;
    for (parsed.value) |expr| {
        sum += expr[0] * expr[1];
    }
    return sum;
}

const exprCombined = mecha.oneOf(.{
    exprMul,
    mecha.string("do()").mapConst([2]i64{ -1, 0 }),
    mecha.string("don't()").mapConst([2]i64{ -2, 0 }),
});

const exprP2 = mecha.combine(.{
    mecha.ascii.not(exprCombined).many(.{ .collect = false }).discard(),
    exprCombined,
}).many(.{});

pub fn part2(input: []const u8, allocator: Allocator) !i64 {
    const parsed = try exprP2.parse(allocator, input);
    defer allocator.free(parsed.value);

    var sum: i64 = 0;
    var on: bool = true;
    for (parsed.value) |expr| {
        if (expr[0] == -1) {
            on = true;
        } else if (expr[0] == -2) {
            on = false;
        } else if (on) {
            sum += expr[0] * expr[1];
        }
    }
    return sum;
}

test "Tests" {
    const allocator = testing.allocator;
    const sample_input =
        \\xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))
    ;
    try testing.expectEqual(161, try part1(sample_input, allocator));
    const sample_input2 =
        \\xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))
    ;
    try testing.expectEqual(48, try part2(sample_input2, allocator));
}
