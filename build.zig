const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Load the mecha dependency from build.zig.zon and create module
    const mecha_package = b.dependency("mecha", .{
        .target = target,
        .optimize = optimize,
    });
    const mecha_module = mecha_package.module("mecha");

    // Add common module
    const common_module = b.createModule(.{
        .root_source_file = b.path("src/common.zig"),
    });

    // Commands to run all files
    const test_all_step = b.step("test", "Run tests");
    const run_all_step = b.step("run", "Run on real data");
    const time_all_step = b.step("time", "Run timing check");

    // Build all available days
    for (1..26) |day| {
        buildDay(b, day, target, optimize, common_module, mecha_module, test_all_step, run_all_step, time_all_step);
    }
}

fn buildDay(b: *std.Build,
    day: usize,
    target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode,
    common_module: *std.Build.Module, mecha_module: *std.Build.Module,
    test_all_step: *std.Build.Step, run_all_step: *std.Build.Step, time_all_step: *std.Build.Step
) void {
    // Add day option to pass to the main executable
    const options = b.addOptions();
    options.addOption(usize, "day", day);

    // Setup day module module
    const day_module_file = b.fmt("src/day{d:0>2}.zig", .{ day });
    const day_module = b.createModule(.{
        .root_source_file = b.path(day_module_file),
    });
    day_module.addImport("common", common_module);
    day_module.addImport("mecha", mecha_module);

    // Setup executable
    const exe = b.addExecutable(.{
        .name = "aoc24",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("common", common_module);
    exe.root_module.addOptions("config", options);
    exe.root_module.addImport("day_module", day_module);

    // Run command
    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step(b.fmt("run-{d:0>2}", .{ day }), "Run on real data");
    run_step.dependOn(&run_cmd.step);

    // Test command
    const day_tests = b.addTest(.{
        .root_source_file = b.path(day_module_file),
        .target = target,
        .optimize = optimize,
    });
    // make mecha module usable in main tests
    day_tests.root_module.addImport("mecha", mecha_module);
    day_tests.root_module.addImport("common", common_module);
    const run_tests = b.addRunArtifact(day_tests);

    const test_step = b.step(b.fmt("test-{d:0>2}", .{ day }), "Run tests");
    test_step.dependOn(&run_tests.step);

    // Profile command
    const time_run = b.addSystemCommand(&.{ "hyperfine", "--warmup=1" });
    time_run.addFileArg(exe.getEmittedBin());
    time_run.step.dependOn(b.getInstallStep());

    const time_step = b.step(b.fmt("time-{d:0>2}", .{day}), "Run timing check");
    time_step.dependOn(&time_run.step);

    // Add dependencies to the all steps if the day module file exists
    std.fs.cwd().access(day_module_file, .{}) catch return;
    test_all_step.dependOn(&run_tests.step);
    run_all_step.dependOn(&run_cmd.step);
    time_all_step.dependOn(time_step);
}
