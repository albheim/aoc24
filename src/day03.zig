const std = @import("std");
const common = @import("common");
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

const exprCombined = mecha.oneOf(.{
    exprMul,
    mecha.string("do()").mapConst([2]i64{ -1, 0 }),
    mecha.string("don't()").mapConst([2]i64{ -2, 0 }),
});

const exprP2 = mecha.combine(.{
    mecha.ascii.not(exprCombined).many(.{ .collect = false }).discard(),
    exprCombined,
}).many(.{});

pub fn run(input: []const u8, allocator: Allocator) ![2]u64 {
    return .{
        try part1(input, allocator),
        try part2(input, allocator),
    };
}

fn part1(input: []const u8, allocator: Allocator) !u64 {
    const parsed = try exprP1.parse(allocator, input);
    defer allocator.free(parsed.value);

    var sum: u64 = 0;
    for (parsed.value) |expr| {
        sum += @intCast(expr[0] * expr[1]);
    }
    return sum;
}

fn part2(input: []const u8, allocator: Allocator) !u64 {
    const parsed = try exprP2.parse(allocator, input);
    defer allocator.free(parsed.value);

    var sum: u64 = 0;
    var on: bool = true;
    for (parsed.value) |expr| {
        if (expr[0] == -1) {
            on = true;
        } else if (expr[0] == -2) {
            on = false;
        } else if (on) {
            sum += @intCast(expr[0] * expr[1]);
        }
    }
    return sum;
}

test "Sample 1" {
    const allocator = testing.allocator;
    const sample_input =
        \\xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))
    ;
    try testing.expectEqual(161, try part1(sample_input, allocator));
}

test "Sample 2" {
    const allocator = testing.allocator;
    const sample_input2 =
        \\xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))
    ;
    try testing.expectEqual(48, try part2(sample_input2, allocator));
}

test "Full" {
    const allocator = testing.allocator;
    const buffer = try allocator.alloc(u8, 20);
    defer allocator.free(buffer);
    const input_path = try std.fmt.bufPrint(buffer, "inputs/{any}.txt", .{ @This() });
    const input = try common.readFile(input_path, allocator);
    defer allocator.free(input);
    try testing.expectEqual(.{ 184122457, 107862689 }, run(input, allocator));
}
