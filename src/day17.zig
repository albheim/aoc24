const std = @import("std");
const common = @import("common");
const testing = std.testing;
const Tuple = std.meta.Tuple;
const Allocator = std.mem.Allocator;
const parseInt = std.fmt.parseInt;
const mecha = @import("mecha");

const Computer = struct {
    const Self = @This();
    a: u64,
    b: u64,
    c: u64,
    instruction_pointer: u64,
    program: []const u3,

    const OpCode = enum {
        ADV, // Divide A reg by 2^COMBO, truncate to int and store in A.
        BXL, // XOR B with LIT, store in B.
        BST, // COMBO mod 8, store in B.
        JNZ, // If A is zero, do nothing. Else jump to LIT and don't increase instruction pointer.
        BXC, // XOR of B and C, store in B. Reads LIT but ignores it.
        OUT, // COMBO mod 8 to output
        BDV, // Like ADV but stores in B instead.
        CDV, // Like ADV but stores in C instead.
    };

    fn combo(self: Self, val: u3) u64 {
        return switch (val) {
            0...3 => @intCast(val),
            4 => self.a,
            5 => self.b,
            6 => self.c,
            7 => unreachable,
        };
    }

    const ReturnTag = enum {
        HALT,
        VAL,
    };

    const Return = union(ReturnTag) {
        HALT: void,
        VAL: ?u3,
    };

    pub fn step(self: *Self) Return {
        if (self.instruction_pointer >= self.program.len) {
            return .HALT;
        }
        const op: OpCode = @enumFromInt(self.program[self.instruction_pointer]);
        self.instruction_pointer += 1;
        const lit = self.program[self.instruction_pointer];
        self.instruction_pointer += 1;
        switch (op) {
            .ADV => self.a = std.math.shr(u64, self.a, self.combo(lit)),
            .BXL => self.b ^= lit,
            .BST => self.b = self.combo(lit) % 8,
            .JNZ => if (self.a != 0) {
                self.instruction_pointer = lit;
            },
            .BXC => self.b ^= self.c,
            .OUT => return .{ .VAL = @intCast(self.combo(lit) % 8) },
            .BDV => self.b = std.math.shr(u64, self.a, self.combo(lit)),
            .CDV => self.c = std.math.shr(u64, self.a, self.combo(lit)),
        }
        return .{ .VAL = null };
    }
};

const parser = mecha.combine(.{ mecha.string("Register A: ").discard(), mecha.int(u64, .{}), mecha.string("\nRegister B: ").discard(), mecha.int(u64, .{}), mecha.string("\nRegister C: ").discard(), mecha.int(u64, .{}), mecha.mapConst(mecha.string("\n\nProgram: "), @as(u64, 0)), mecha.int(u3, .{}).many(.{ .separator = mecha.ascii.char(',').discard() }) }).map(mecha.toStruct(Computer));

pub fn run(input: []const u8, allocator: Allocator) !Tuple(&.{ []const u8, u64 }) {
    return .{
        try part1(input, allocator),
        try part2(input, allocator),
    };
}

fn part1(input: []const u8, allocator: Allocator) ![]const u8 {
    const result = try parser.parse(allocator, input);
    var computer = result.value;
    defer allocator.free(computer.program);

    var output = std.ArrayList(u8).init(allocator);
    defer output.deinit();

    while (true) {
        switch (computer.step()) {
            .HALT => break,
            .VAL => |val| {
                if (val) |v| {
                    try output.append(@as(u8, v) + '0');
                    try output.append(',');
                }
            },
        }
    }

    // Remove last comma
    if (output.items.len > 0) {
        _ = output.pop();
    }
    return output.toOwnedSlice();
}

fn part2(input: []const u8, allocator: Allocator) !u64 {
    const result = try parser.parse(allocator, input);
    var computer = result.value;
    defer allocator.free(computer.program);

    var output = std.ArrayList(u8).init(allocator);
    defer output.deinit();

    return findARec(&computer, 0, computer.program.len) orelse unreachable;
}

fn findARec(computer: *Computer, a: u64, idx: u64) ?u64 {
    if (idx == 0) {
        return a;
    }
    const new_idx = idx - 1;
    const a_shift = a << 3;
    for (0..8) |i| {
        const new_a = a_shift | i;
        computer.a = new_a;
        computer.instruction_pointer = 0;
        while (true) {
            switch (computer.step()) {
                .HALT => unreachable,
                .VAL => |val| {
                    if (val) |v| {
                        if (v == computer.program[new_idx]) {
                            if (findARec(computer, new_a, new_idx)) |final_a| {
                                return final_a;
                            }
                        }
                        break;
                    }
                },
            }
        }
    }
    return null;
}

test "Sample 1" {
    const allocator = testing.allocator;
    const input =
        \\Register A: 729
        \\Register B: 0
        \\Register C: 0
        \\
        \\Program: 0,1,5,4,3,0
    ;
    const res = try part1(input, allocator);
    try testing.expectEqualStrings("4,6,3,5,6,3,5,2,1,0", res);
    allocator.free(res);
}

test "Sample 2" {
    const allocator = testing.allocator;
    const input =
        \\Register A: 2024
        \\Register B: 0
        \\Register C: 0
        \\
        \\Program: 0,3,5,4,3,0
    ;
    try testing.expectEqual(117440, try part2(input, allocator));
}

test "Full" {
    const allocator = testing.allocator;
    const buffer = try allocator.alloc(u8, 20);
    defer allocator.free(buffer);
    const input_path = try std.fmt.bufPrint(buffer, "inputs/{any}.txt", .{@This()});
    const input = try common.readFile(input_path, allocator);
    defer allocator.free(input);
    const res = try run(input, allocator);
    defer allocator.free(res[0]);
    try testing.expectEqualStrings("7,1,3,4,1,2,6,7,1", res[0]);
    try testing.expectEqual(109019476330651, res[1]);
}
