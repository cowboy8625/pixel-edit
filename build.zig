const std = @import("std");
const nfd = @import("nfd");

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

    nfd.install(exe);
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

    if (b.option(bool, "install", "install application") orelse false) {
        installApp();
    }
}

fn installApp() void {
    std.debug.print("Installing app\n", .{});
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const env_map = arena.allocator().create(std.process.EnvMap) catch @panic("Unable to allocate memory");
    env_map.* = std.process.getEnvMap(arena.allocator()) catch @panic("Unable to allocate memory");
    defer env_map.deinit();
    const alloc = std.heap.page_allocator;

    const user = env_map.get("USER") orelse @panic("USER not set");
    const buffer = alloc.alloc(u8, 100) catch @panic("Unable to allocate memory");
    defer alloc.free(buffer);
    var path = std.fmt.bufPrint(buffer, "/home/{s}/.zig/bin", .{user}) catch @panic("Unable to allocate memory");
    defer arena.allocator().free(path);

    const result = std.ChildProcess.run(.{
        .allocator = alloc,
        .argv = &[_][]const u8{
            "cp",
            "zig-out/bin/pixel-edit",
            path,
        },
        .env_map = env_map,
    }) catch @panic("Failed to install app");
    defer alloc.free(result.stdout);
    defer alloc.free(result.stderr);

    switch (result.term) {
        .Exited => |code| if (code != 0) {
            std.debug.print("code {d}: {s}\n", .{ code, result.stderr });
            std.process.exit(code);
        },
        else => std.debug.print("copied exe to ~/.zig/bin/\n", .{}),
    }
    path = std.fmt.bufPrint(buffer, "/home/{s}/.config/pixel-edit", .{user}) catch @panic("Unable to allocate memory");
    const output = std.ChildProcess.run(.{
        .allocator = alloc,
        .argv = &[_][]const u8{
            "cp",
            "assets",
            "-r",
            path,
        },
        .env_map = env_map,
    }) catch @panic("Failed to install app");
    defer alloc.free(output.stdout);
    defer alloc.free(output.stderr);

    switch (output.term) {
        .Exited => |code| if (code != 0) {
            std.debug.print("code {d}: {s}\n", .{ code, output.stderr });
        },
        else => std.debug.print("copied assets to ~/.zig/bin/\n", .{}),
    }
}
