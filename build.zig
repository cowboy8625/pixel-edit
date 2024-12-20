const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "pixel-edit",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    //buildLib(b, exe, target, optimize);
    addDependency(b, exe, .{ .target = target, .optimize = optimize });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    //buildLib(b, exe_unit_tests, target, optimize);
    addDependency(b, exe_unit_tests, .{ .target = target, .optimize = optimize });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}

fn addDependency(b: *std.Build, exe: *std.Build.Step.Compile, options: anytype) void {
    // const ziglua = b.dependency("ziglua", options);
    // exe.root_module.addImport("ziglua", ziglua.module("ziglua"));

    // https://github.com/Not-Nik/raylib-zig
    const raylib_dep = b.dependency("raylib-zig", options);
    const raylib = raylib_dep.module("raylib"); // main raylib module
    const raygui = raylib_dep.module("raygui"); // raygui module
    const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library
    exe.root_module.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("raygui", raygui);
}
