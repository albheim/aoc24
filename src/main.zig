const std = @import("std");
const config = @import("config");

const day_module = @import("day_module");
const common = @import("common");

const tenths = config.day / 10;
const ones = config.day % 10;
const day_nbr =  [2]u8{ tenths + '0', ones + '0' };
const day_data = "inputs/day" ++ day_nbr ++ ".txt";

pub fn main() !void {
    var allocator_type = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = allocator_type.allocator();

    const input = try common.readFile(day_data, allocator);
    defer allocator.free(input);

    const part1 = try day_module.part1(input, allocator);
    const part2 = try day_module.part2(input, allocator);

    std.debug.print("Day {s}\nP1: {d}\nP2: {d}\n", .{ day_nbr, part1, part2 });
}
