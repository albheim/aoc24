const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "aoc24",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // load the mecha dependency from build.zig.zon
    const mecha_package = b.dependency("mecha", .{
        .target = target,
        .optimize = optimize,
    });
    // load the "mecha" module from the package
    const mecha_module = mecha_package.module("mecha");

    // make mecha usable in main
    exe.root_module.addImport("mecha", mecha_module);

    // Add a build option for the day
    const day = b.option(u8, "day", "Which day to compile for.") orelse 1;
    const options = b.addOptions();
    options.addOption(u8, "day", day);
    exe.root_module.addOptions("config", options);

    // Run command
    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Profile command
    const time_run = b.addSystemCommand(&.{ "hyperfine", "./zig-out/bin/aoc24" });
    time_run.step.dependOn(&run_cmd.step);

    const time_step = b.step("time", "Run timing check");
    time_step.dependOn(&time_run.step);

    // Test command
    var buffer: [20]u8 = undefined;
    const test_file = std.fmt.bufPrint(buffer[0..], "src/day{d:0>2}.zig", .{day}) catch unreachable;
    const day_tests = b.addTest(.{
        .root_source_file = b.path(test_file),
        .target = target,
        .optimize = optimize,
    });
    // make mecha module usable in main tests
    day_tests.root_module.addImport("mecha", mecha_module);
    const run_tests = b.addRunArtifact(day_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_tests.step);
}
