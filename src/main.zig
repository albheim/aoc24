const std = @import("std");
const common = @import("common.zig");

pub fn main() !void {
    var allocator_type = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = allocator_type.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.log.err("Usage: zig build run [--release] -- <day>\n", .{});
        return;
    }

    const day = try std.fmt.parseInt(u8, args[1], 10);
    switch (day) {
        1 => try runDay("inputs/day01.txt", @import("day01.zig"), &allocator),
        else => std.log.err("Unknown day: {}\n", .{day}),
    }
}

fn runDay(inputFile: []const u8, dayModule: anytype, allocator: *const std.mem.Allocator) !void {
    const input = try common.readFile(inputFile, allocator);
    defer allocator.free(input);

    const part1 = try dayModule.part1(input, allocator);
    const part2 = try dayModule.part2(input, allocator);

    std.debug.print("Day results:\nPart 1: {d}\nPart 2: {d}\n", .{ part1, part2 });
}
