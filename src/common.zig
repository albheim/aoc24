const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub fn readFile(path: []const u8, allocator: Allocator) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    const size = try file.getEndPos();
    const buffer = try allocator.alloc(u8, size);
    _ = try file.readAll(buffer);
    return buffer;
}

pub fn Vec2(comptime T: type) type {
    return struct {
        const Self = @This();

        x: T,
        y: T,

        pub fn add(self: Self, other: Self) Self {
            return Self {
                .x = self.x + other.x,
                .y = self.y + other.y,
            };
        }

        pub fn diff(self: Self, other: Self) Self {
            return Self {
                .x = self.x - other.x,
                .y = self.y - other.y,
            };
        }

        pub fn scale(self: Self, scalar: T) Self {
            return Self {
                .x = self.x * scalar,
                .y = self.y * scalar,
            };
        }

        pub fn isInside(self: Self, width: T, height: T) bool {
            return self.x >= 0 and self.x < width and self.y >= 0 and self.y < height;
        }
    };
}

pub fn FlexibleMatrix(comptime T: type) type {
    return struct {
        const Self = @This();

        data: ArrayList(T),
        rows: usize,
        cols: usize,

        pub fn init(allocator: Allocator) Self {
            return Self {
                .data = ArrayList(T).init(allocator),
                .rows = 0,
                .cols = 0,
            };
        }

        pub fn deinit(self: *Self) void {
            self.data.deinit();
        }

        pub fn rowCount(self: Self) usize {
            return self.rows;
        }

        pub fn colCount(self: Self) usize {
            return self.cols;
        }

        pub fn setCols(self: *Self, ncols: usize) void {
            self.cols = ncols;
        }

        pub fn addRow(self: *Self, items: []const T) !void {
            if (self.cols == 0) {
                self.cols = items.len;
            } else if (self.cols != items.len) {
                return std.debug.panic("Row length does not match matrix column count", .{});
            }
            try self.data.appendSlice(items);
            self.rows += 1;
        }

        pub fn get(self: Self, row: usize, col: usize) !T {
            if (col >= self.cols or row >= self.rows) {
                return std.debug.panic("Column index out of bounds", .{});
            }
            return self.data.items[row * self.cols + col];
        }
    };
}
