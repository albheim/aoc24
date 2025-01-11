const std = @import("std");
const common = @import("common");
const testing = std.testing;
const Allocator = std.mem.Allocator;

const print = std.debug.print;

const PatternMatcher = struct {
    const Self = @This();

    children: std.AutoHashMap(u8, PatternMatcher),
    is_leaf: bool,
    allocator: Allocator,

    pub fn init(allocator: Allocator) Self {
        return Self{
            .children = std.AutoHashMap(u8, PatternMatcher).init(allocator),
            .is_leaf = false,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        var iter = self.children.valueIterator();
        while (iter.next()) |child| {
            child.deinit();
        }
        self.children.deinit();
    }

    pub fn addPattern(self: *Self, pattern: []const u8) !void {
        if (pattern.len == 0) {
            self.is_leaf = true;
            return;
        }
        const child = try self.children.getOrPut(pattern[0]);
        if (!child.found_existing) {
            child.value_ptr.* = Self.init(self.allocator);
        }
        try child.value_ptr.addPattern(pattern[1..]);
    }

    fn canMatch(self: Self, origin: Self, string: []const u8, memo: *std.StringHashMap(bool)) bool {
        if (string.len == 0) {
            return self.is_leaf;
        }
        var can_match = false;
        if (self.children.get(string[0])) |child| {
            can_match = child.canMatch(origin, string[1..], memo);
        }
        if (!can_match and self.is_leaf) {
            if (memo.get(string)) |val| {
                return val;
            } else {
                can_match = origin.canMatch(origin, string, memo);
                memo.put(string, can_match) catch unreachable;
            }
        }
        return can_match;
    }

    fn countMatch(self: Self, origin: Self, string: []const u8, memo: *std.StringHashMap(u64)) u64 {
        if (string.len == 0) {
            return if (self.is_leaf) 1 else 0;
        }
        var matches: u64 = 0;
        if (self.children.get(string[0])) |child| {
            matches += child.countMatch(origin, string[1..], memo);
        }
        if (self.is_leaf) {
            if (memo.get(string)) |val| {
                matches += val;
            } else {
                const mat = origin.countMatch(origin, string, memo);
                memo.put(string, mat) catch unreachable;
                matches += mat;
            }
        }
        return matches;
    }
};

pub fn run(input: []const u8, allocator: Allocator) ![2]u64 {
    var lines = std.mem.splitScalar(u8, input, '\n');

    var patterns = PatternMatcher.init(allocator);
    defer patterns.deinit();
    var displays = std.ArrayList([]const u8).init(allocator);
    defer displays.deinit();

    var pattern_line_iter = std.mem.splitSequence(u8, lines.next().?, ", ");
    while (pattern_line_iter.next()) |pattern| {
        try patterns.addPattern(pattern);
    }
    _ = lines.next();
    while (lines.next()) |line| {
        if (line.len == 0) break;
        try displays.append(line);
    }

    return .{ part1(patterns, displays.items, allocator), part2(patterns, displays.items, allocator) };
}

fn part1(patterns: PatternMatcher, displays: []const []const u8, allocator: Allocator) u64 {
    var counter: u64 = 0;
    var memo = std.StringHashMap(bool).init(allocator);
    defer memo.deinit();
    for (displays) |display| {
        //print("\n\nChecking: {s}\n", .{display});
        memo.clearAndFree();
        if (patterns.canMatch(patterns, display, &memo)) {
            //print("Match!\n", .{});
            counter += 1;
        }
    }
    return counter;
}

fn part2(patterns: PatternMatcher, displays: []const []const u8, allocator: Allocator) u64 {
    var counter: u64 = 0;
    var memo = std.StringHashMap(u64).init(allocator);
    defer memo.deinit();
    for (displays) |display| {
        print("Checking {s}\n", .{display});
        memo.clearAndFree();
        const t = patterns.countMatch(patterns, display, &memo);
        print("Found {d}\n", .{t});
        counter += t;
    }
    return counter;
}

test "Sample" {
    const allocator = testing.allocator;
    const input =
        \\r, wr, b, g, bwu, rb, gb, br
        \\
        \\brwrr
        \\bggr
        \\gbbr
        \\rrbgbr
        \\ubwu
        \\bwurrg
        \\brgr
        \\bbrgwb
    ;
    try testing.expectEqual(.{ 6, 16 }, run(input, allocator));
}

test "Full" {
    const allocator = testing.allocator;
    const buffer = try allocator.alloc(u8, 20);
    defer allocator.free(buffer);
    const input_path = try std.fmt.bufPrint(buffer, "inputs/{any}.txt", .{@This()});
    const input = try common.readFile(input_path, allocator);
    defer allocator.free(input);
    try testing.expectEqual(.{ 353, 0 }, run(input, allocator));
}
