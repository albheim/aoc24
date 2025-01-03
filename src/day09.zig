const std = @import("std");
const common = @import("common");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const parseInt = std.fmt.parseInt;

pub fn run(input: []const u8, allocator: Allocator) ![2]u64 {
    return .{
        try part1(input, allocator),
        try part2(input, allocator),
    };
}

fn part1(input: []const u8, allocator: Allocator) !u64 {
    _ = allocator;
    var checksum: u64 = 0;
    var idx: u64 = 0;
    var id_start: u64 = 0;
    var id_end: u64 = (input.len - 1) / 2;
    var avail_end: u64 = input[id_end * 2] - '0';

    while (id_start < id_end) {
        var n = input[id_start * 2] - '0';
        for (0..n) |_| {
            checksum += idx * id_start;
            idx += 1;
        }
        n = input[id_start * 2 + 1] - '0';
        for (0..n) |_| {
            while (avail_end == 0) {
                id_end -= 1;
                avail_end = input[id_end * 2] - '0';
            }
            checksum += idx * id_end;
            idx += 1;
            avail_end -= 1;
        }
        id_start += 1;
    }
    for (0..avail_end) |_| {
        checksum += idx * id_end;
        idx += 1;
    }

    return checksum;
}

const BlockTypeTag = enum {
    empty,
    full,
};

const BlockType = union(BlockTypeTag) {
    empty: void,
    full: u64,
};

const Block = struct {
    block_type: BlockType,
    count: u64,
};

fn part2(input: []const u8, allocator: Allocator) !u64 {
    var list = std.ArrayList(Block).init(allocator);
    defer list.deinit();

    for (0..input.len) |i| {
        const c = input[i];
        if (c == '\n') {
            break;
        }
        if (try std.math.mod(u64, i, 2) == 0) {
            try list.append(Block{ .block_type = BlockType{ .full = i / 2 }, .count = c - '0' });
        } else {
            try list.append(Block{ .block_type = BlockTypeTag.empty, .count = c - '0' });
        }
    }

    var checksum: u64 = 0;
    var idx: u64 = 0;
    var i: u64 = 0;
    while (i < list.items.len) : (i += 1) {
        switch (list.items[i].block_type) {
            .full => |id| {
                for (0..list.items[i].count) |_| {
                    checksum += idx * id;
                    idx += 1;
                }
            },
            .empty => {
                var idx_r = list.items.len - 1;
                while (idx_r > i) {
                    switch (list.items[idx_r].block_type) {
                        .full => |id| {
                            if (list.items[idx_r].count <= list.items[i].count) {
                                for (0..list.items[idx_r].count) |_| {
                                    checksum += idx * id;
                                    idx += 1;
                                }
                                list.items[idx_r].block_type = BlockTypeTag.empty;
                                list.items[i].count -= list.items[idx_r].count;
                            }
                        },
                        .empty => {},
                    }
                    idx_r -= 1;
                }
                for (0..list.items[i].count) |_| {
                    idx += 1;
                }
            },
        }
    }
    return @intCast(checksum);
}

test "Sample" {
    const allocator = testing.allocator;
    const input =
        \\2333133121414131402
    ;
    try testing.expectEqual(.{ 1928, 2858 }, run(input, allocator));
}

test "Full" {
    const allocator = testing.allocator;
    const buffer = try allocator.alloc(u8, 20);
    defer allocator.free(buffer);
    const input_path = try std.fmt.bufPrint(buffer, "inputs/{any}.txt", .{@This()});
    const input = try common.readFile(input_path, allocator);
    defer allocator.free(input);
    try testing.expectEqual(.{ 6398252054886, 6415666220005 }, run(input, allocator));
}
