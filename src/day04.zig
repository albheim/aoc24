const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const print = std.debug.print;

const target = "XMAS";

fn search(data: [][]const u8, position: [2]i64, direction: [2]i64) bool {
    var y = position[0];
    var x = position[1];
    var idx: usize = 0;
    while (data[@intCast(y)][@intCast(x)] == target[idx]) {
        y += direction[0];
        x += direction[1];
        idx += 1;
        if (idx == target.len
                or  y < 0 or y >= data.len
                or x < 0 or x >= data[@intCast(y)].len) {
            break;
        }
    }
    return idx == target.len;
}

pub fn part1(input: []const u8, allocator: Allocator) !i64 {
    var lines = std.mem.split(u8, input, "\n");
    var rows = std.ArrayList([]const u8).init(allocator);
    defer rows.deinit();
    while (lines.next()) |line| {
        if (line.len > 0) {
            try rows.append(line);
        }
    }
    const data = rows.items;
    var xmases: i64 = 0;
    for (0..data.len) |i| {
        for (0..data[i].len) |j| {
            for ([3]i64{-1, 0, 1}) |di| {
                for ([3]i64{-1, 0, 1}) |dj| {
                    if (di == 0 and dj == 0) {
                        continue;
                    }
                    if (search(data, .{@intCast(i), @intCast(j)}, .{di, dj})) {
                        xmases += 1;
                    }
                }
            }
        }
    }
    return xmases;
}

fn sAndM(a: u8, b: u8) bool {
    return a == 'S' and b == 'M' or a == 'M' and b == 'S';
}

pub fn part2(input: []const u8, allocator: Allocator) !i64 {
    var lines = std.mem.split(u8, input, "\n");
    var rows = std.ArrayList([]const u8).init(allocator);
    defer rows.deinit();
    while (lines.next()) |line| {
        if (line.len > 0) {
            try rows.append(line);
        }
    }
    const data = rows.items;
    var xmases: i64 = 0;
    for (0..(data.len-2)) |i| {
        for (0..(data[i].len-2)) |j| {
            if (data[i+1][j+1] == 'A'
                    and sAndM(data[i][j], data[i+2][j+2])
                    and sAndM(data[i][j+2], data[i+2][j])) {
                xmases += 1;
            }
        }
    }
    return xmases;
}

test "Tests" {
    const sample_input =
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
    const allocator = testing.allocator;
    try testing.expect(try part1(sample_input, allocator) == 18);
    try testing.expect(try part2(sample_input, allocator) == 9);
}
