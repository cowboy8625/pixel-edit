const std = @import("std");

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
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const exe = b.addExecutable(.{
        .name = "pixel-edit",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.linkSystemLibrary("raylib");
    exe.linkSystemLibrary("c");

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
