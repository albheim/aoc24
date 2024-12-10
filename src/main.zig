const std = @import("std");
const common = @import("common.zig");
const config = @import("config");

const dayModule = switch (config.day) {
    1 => @import("day01.zig"),
    2 => @import("day02.zig"),
    3 => @import("day03.zig"),
    else => {
        std.debug.print("Error: invalid day {d}", .{config.day});
        unreachable;
    },
};

const dayData = "inputs/day" ++ switch (config.day) {
    1 => "01",
    2 => "02",
    3 => "03",
    else => {
        std.debug.print("Error: invalid day {d}", .{config.day});
        unreachable;
    },
} ++ ".txt";

pub fn main() !void {
    var allocator_type = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = allocator_type.allocator();

    const input = try common.readFile(dayData, &allocator);
    defer allocator.free(input);

    const part1 = try dayModule.part1(input, &allocator);
    const part2 = try dayModule.part2(input, &allocator);

    std.debug.print("Day results:\nPart 1: {d}\nPart 2: {d}\n", .{ part1, part2 });
}
