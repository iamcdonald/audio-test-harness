const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const audio = b.dependency("audio", .{
        .optimize = optimize,
        .target = target,
    });

    const module = b.addModule("audio-test-harness", .{ .root_source_file = b.path("src/AudioTestHarness.zig") });
    module.addImport("audio", audio.module("audio"));
    module.linkLibrary(audio.artifact("portaudio"));

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/AudioTestHarness.zig"),
        .target = target,
        .optimize = optimize,
    });

    lib_unit_tests.root_module.addImport("audio", audio.module("audio"));
    lib_unit_tests.linkLibrary(audio.artifact("portaudio"));

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
