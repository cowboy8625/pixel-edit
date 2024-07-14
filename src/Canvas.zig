const std = @import("std");
const Allocator = std.mem.Allocator;
const rl = @import("raylib_zig");
const Context = @import("Context.zig");

const Pixels = std.AutoHashMap(rl.Vector2(usize), rl.Color);

const Self = @This();
alloc: Allocator,
pixels: Pixels,
width: u32,
height: u32,

pub fn init(alloc: Allocator, width: u32, height: u32) !Self {
    var pixels = Pixels.init(alloc);
    errdefer pixels.deinit();

    return .{
        .alloc = alloc,
        .pixels = pixels,
        .width = width,
        .height = height,
    };
}

pub fn deinit(self: *Self) void {
    self.pixels.deinit();
}

pub fn clear(self: *Self) void {
    self.pixels.clearRetainingCapacity();
}

pub fn insert(self: *Self, pos: rl.Vector2(usize), color: rl.Color) !void {
    try self.pixels.put(pos, color);
}

pub fn draw(self: *const Self, ctx: *Context) void {
    const size = ctx.cursor.size.as(usize);
    var iter = self.pixels.iterator();
    while (iter.next()) |entry| {
        const pos = entry.key_ptr.*.mul(size).as(f32);
        const color = entry.value_ptr.*;
        rl.DrawRectangleV(pos, size.as(f32), color);
    }
}
