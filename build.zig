const std = @import("std");
const raySdk = @import("raylib/src/build.zig");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.

// pub fn build(b: *std.Build) void {
//     const targets = [_][]const u8{ "aarch64-macos", "x86_64-macos", "aarch64-linux", "x86_64-linux-gnu", "x86_64-linux-musl", "x86_64-windows" };
//
//     inline for (targets) |target_string| {
//         const target = try std.zig.CrossTarget.parse(.{ .arch_os_abi = target_string });
//         const exe = b.addExecutable(.{
//             .name = "main_" ++ target_string,
//             .root_source_file = .{ .path = "src/main.zig" },
//             .target = target,
//             .optimize = .ReleaseSafe,
//         });
//         b.installArtifact(exe);
//     }
// }

pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // const lib = b.addStaticLibrary(.{
    //     .name = "pixel-edit",
    //     // In this case the main source file is merely a path, however, in more
    //     // complicated build scripts, this could be a generated file.
    //     .root_source_file = .{ .path = "src/root.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    // b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "pixel-edit",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const raylib = raySdk.addRaylib(b, target, optimize, .{
        // Add in optional modules in raylib. These match up to the options struct.
        // https://github.com/raysan5/raylib/blob/bc15c19518968878b68bbfe8eac3fe4297f11770/src/build.zig#L161
        .raudio = true,
        .rmodels = true,
        .rshapes = true,
        .rtext = true,
        .rtextures = true,
        .raygui = true,
        .platform_drm = false,
    });

    exe.addIncludePath(.{ .path = "raylib/src" });
    exe.addIncludePath(.{ .path = "raygui/src" });
    exe.linkLibrary(raylib);

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const lib_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}