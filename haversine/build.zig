const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    // Generator.
    const exe_gen = b.addExecutable(.{
        .name = "gen",
        .root_source_file = .{ .path = "cmd/gen/gen.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe_gen);
    const run_gen = b.addRunArtifact(exe_gen);
    if (b.args) |args| {
        run_gen.addArgs(args);
    }
    const step_run = b.step("gen", "run the JSON generator");
    step_run.dependOn(&run_gen.step);

    // Haversine.
    const exe_haversine = b.addExecutable(.{
        .name = "haversine",
        .root_source_file = .{ .path = "cmd/haversine/haversine.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe_haversine.addCSourceFile("vendor/yyjson-0.6.0/yyjson.c", &[_][]const u8{
        "-Wall",
        "-Wextra",
        "-Wpedantic",
        "-Werror",
        "-std=c17",
    });
    exe_haversine.addIncludePath("vendor/yyjson-0.6.0");
    b.installArtifact(exe_haversine);
    const run_haversine = b.addRunArtifact(exe_haversine);
    const step_haversine = b.step("haversine", "run the haversine program");
    if (b.args) |args| {
        run_haversine.addArgs(args);
    }
    step_haversine.dependOn(&run_haversine.step);
}
