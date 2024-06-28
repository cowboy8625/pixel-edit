const std = @import("std");
const Allocator = std.mem.Allocator;
const Cursor = @import("Cursor.zig");
const modes = @import("mode.zig");
const Canvas = @import("Canvas.zig");
const rl = @import("raylib_zig");

const Self = @This();

alloc: Allocator,
cursor: *Cursor,
canvas: *Canvas,
mode: modes.Mode = .Normal,

pub fn init(alloc: Allocator, width: u32, height: u32) !Self {
    const cursor = try alloc.create(Cursor);
    errdefer alloc.destroy(cursor);
    cursor.* = Cursor.init();

    const canvas = try alloc.create(Canvas);
    errdefer alloc.destroy(canvas);
    canvas.* = try Canvas.init(alloc, width, height);

    return .{
        .alloc = alloc,
        .cursor = cursor,
        .canvas = canvas,
    };
}

pub fn deinit(self: Self) void {
    self.alloc.destroy(self.cursor);
    self.alloc.destroy(self.canvas);
}
