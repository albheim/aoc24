const std = @import("std");
const common = @import("common.zig");
const config = @import("config");

const dayModule = switch (config.day) {
    1 => @import("day01.zig"),
    2 => @import("day02.zig"),
    3 => @import("day03.zig"),
    4 => @import("day04.zig"),
    else => {
        std.debug.print("Error: invalid day {d}", .{config.day});
        unreachable;
    },
};

const tenths = config.day / 10;
const ones = config.day % 10;
const dayNbr =  [2]u8{ tenths + '0', ones + '0' };
const dayData = "inputs/day" ++ dayNbr ++ ".txt";

pub fn main() !void {
    var allocator_type = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = allocator_type.allocator();

    const input = try common.readFile(dayData, &allocator);
    defer allocator.free(input);

    const part1 = try dayModule.part1(input, &allocator);
    const part2 = try dayModule.part2(input, &allocator);

    std.debug.print("Part 1: {d}\nPart 2: {d}\n", .{ part1, part2 });
}
