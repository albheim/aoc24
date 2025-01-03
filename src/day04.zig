const std = @import("std");
const common = @import("common");
const testing = std.testing;
const Allocator = std.mem.Allocator;

const target = "XMAS";

pub fn run(input: []const u8, allocator: Allocator) ![2]u64 {
    return .{
        try part1(input, allocator),
        try part2(input, allocator),
    };
}

fn part1(input: []const u8, allocator: Allocator) !u64 {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var rows = std.ArrayList([]const u8).init(allocator);
    defer rows.deinit();
    while (lines.next()) |line| {
        if (line.len > 0) {
            try rows.append(line);
        }
    }
    const data = rows.items;
    var xmases: u64 = 0;
    for (0..data.len) |i| {
        for (0..data[i].len) |j| {
            for ([3]i64{ -1, 0, 1 }) |di| {
                for ([3]i64{ -1, 0, 1 }) |dj| {
                    if (di == 0 and dj == 0) {
                        continue;
                    }
                    if (search(data, .{ @intCast(i), @intCast(j) }, .{ di, dj })) {
                        xmases += 1;
                    }
                }
            }
        }
    }
    return xmases;
}

fn part2(input: []const u8, allocator: Allocator) !u64 {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var rows = std.ArrayList([]const u8).init(allocator);
    defer rows.deinit();
    while (lines.next()) |line| {
        if (line.len > 0) {
            try rows.append(line);
        }
    }
    const data = rows.items;
    var xmases: u64 = 0;
    for (0..(data.len - 2)) |i| {
        for (0..(data[i].len - 2)) |j| {
            if (data[i + 1][j + 1] == 'A' and sAndM(data[i][j], data[i + 2][j + 2]) and sAndM(data[i][j + 2], data[i + 2][j])) {
                xmases += 1;
            }
        }
    }
    return xmases;
}

fn search(data: [][]const u8, position: [2]i64, direction: [2]i64) bool {
    var y = position[0];
    var x = position[1];
    var idx: u64 = 0;
    while (data[@intCast(y)][@intCast(x)] == target[idx]) {
        y += direction[0];
        x += direction[1];
        idx += 1;
        if (idx == target.len or y < 0 or y >= data.len or x < 0 or x >= data[@intCast(y)].len) {
            break;
        }
    }
    return idx == target.len;
}

fn sAndM(a: u8, b: u8) bool {
    return a == 'S' and b == 'M' or a == 'M' and b == 'S';
}

test "Sample" {
    const allocator = testing.allocator;
    const input =
        \\MMMSXXMASM
        \\MSAMXMSMSA
        \\AMXSXMAAMM
        \\MSAMASMSMX
        \\XMASAMXAMM
        \\XXAMMXXAMA
        \\SMSMSASXSS
        \\SAXAMASAAA
        \\MAMMMXMMMM
        \\MXMXAXMASX
    ;
    try testing.expectEqual(.{ 18, 9 }, run(input, allocator));
}

test "Full" {
    const allocator = testing.allocator;
    const buffer = try allocator.alloc(u8, 20);
    defer allocator.free(buffer);
    const input_path = try std.fmt.bufPrint(buffer, "inputs/{any}.txt", .{@This()});
    const input = try common.readFile(input_path, allocator);
    defer allocator.free(input);
    try testing.expectEqual(.{ 2390, 1809 }, run(input, allocator));
}
