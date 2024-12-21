const std = @import("std");
const Allocator = std.mem.Allocator;
const Canvas = @import("Canvas.zig");

const HELP_MESSAGE =
    \\ Usage: pixel-edit [path]
    \\
    \\  -h, --help    Print this help and exit
    \\
;
pub fn handleCliArgs(allocator: Allocator, canvas: *Canvas) !void {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        if (isOneOf(args[i], .{ "-h", "--help" })) {
            std.debug.print("{s}\n", .{HELP_MESSAGE});
            std.process.exit(0);
        } else if (isOneOf(args[i], .{ "-d", "--display" })) {
            hasNextValue(args[i], i, args);
            i += 1;
            const value = args[i];
            var iter = std.mem.split(u8, value, "x");
            const width = try std.fmt.parseFloat(f32, iter.next().?);
            const height = try std.fmt.parseFloat(f32, iter.next().?);
            canvas.size_in_pixels = .{ .x = width, .y = height };
        }
    }
}

fn isOneOf(arg: []const u8, commands: anytype) bool {
    inline for (commands) |command| {
        if (std.mem.eql(u8, command, arg)) return true;
    }
    return false;
}

fn hasNextValue(command: []const u8, i: usize, args: []const []const u8) void {
    if (i + 1 >= args.len) {
        std.debug.print("{s}: expected argument\n", .{command});
        std.process.exit(0);
    }
}
