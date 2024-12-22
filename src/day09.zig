const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const parseInt = std.fmt.parseInt;

pub fn part1(input: []const u8, allocator: Allocator) !i64 {
    _ = allocator;
    var checksum: usize = 0;
    var idx: usize = 0;
    var id_start: usize = 0;
    var id_end: usize = (input.len - 1) / 2;
    var avail_end: usize = input[id_end * 2] - '0';

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

    return @intCast(checksum);
}

const BlockTypeTag = enum {
    empty,
    full,
};

const BlockType = union(BlockTypeTag) {
    empty: void,
    full: usize,
};

const Block = struct {
    block_type: BlockType,
    count: usize,
};

pub fn part2(input: []const u8, allocator: Allocator) !i64 {
    var list = std.ArrayList(Block).init(allocator);
    defer list.deinit();

    for (0..input.len) |i| {
        const c = input[i];
        if (c == '\n') {
            break;
        }
        if (try std.math.mod(usize, i, 2) == 0) {
            try list.append(Block{ .block_type = BlockType{ .full = i / 2 }, .count = c - '0' });
        } else {
            try list.append(Block{ .block_type = BlockTypeTag.empty, .count = c - '0' });
        }
    }

    var checksum: usize = 0;
    var idx: usize = 0;
    var i: usize = 0;
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
                        .empty => {}
                    }
                    idx_r -= 1;
                }
                for (0..list.items[i].count) |_| {
                    idx += 1;
                }
            }
        }
    }
    return @intCast(checksum);
}

test "Tests" {
    const sample_input =
        \\2333133121414131402
    ;
    const allocator = testing.allocator;
    try testing.expectEqual(1928, try part1(sample_input, allocator));
    try testing.expectEqual(2858, try part2(sample_input, allocator));
}
