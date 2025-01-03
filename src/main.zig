const std = @import("std");
const config = @import("config");
const common = @import("common");
const day_module = @import("day_module");
const Allocator = std.mem.Allocator;

const stdout = std.io.getStdOut().writer();

const day_nbr = common.dayToStr(config.day);
const day_data = "inputs/day" ++ day_nbr ++ ".txt";

pub fn main() !void {
    var allocator_type = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = allocator_type.allocator();

    const input = try common.readFile(day_data, allocator);
    defer allocator.free(input);

    const res = try day_module.run(input, allocator);
    try stdout.print("== Day {s} ==\n", .{day_nbr});
    try printRes("P1", res[0], allocator);
    try printRes("P2", res[1], allocator);
}

fn printRes(step: []const u8, data: anytype, allocator: Allocator) !void {
    if (comptime @TypeOf(data) == []const u8) {
        try stdout.print("{s}: {s}\n", .{ step, data });
        allocator.free(data);
    } else {
        try stdout.print("{s}: {d}\n", .{ step, data });
    }
}
