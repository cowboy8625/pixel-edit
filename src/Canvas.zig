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

pub fn remove(self: *Self, pos: rl.Vector2(usize)) void {
    _ = self.pixels.remove(pos);
}

fn drawBackground(self: *const Self) void {
    const pos = rl.Vector2(f32).init(0, 0);
    const size = rl.Vector2(u32).init(self.width, self.height).as(f32);
    rl.DrawRectangleV(pos, size, rl.Color.white());
}

pub fn draw(self: *const Self, ctx: *Context) void {
    self.drawBackground();
    const size = ctx.cursor.size.as(usize);
    var iter = self.pixels.iterator();
    while (iter.next()) |entry| {
        const pos = entry.key_ptr.*.mul(size).as(f32);
        const color = entry.value_ptr.*;
        rl.DrawRectangleV(pos, size.as(f32), color);
    }
}
