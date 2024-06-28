const std = @import("std");
const Allocator = std.mem.Allocator;
const rl = @import("raylib_zig");

const Pixels = std.ArrayList(rl.Color);

const Self = @This();
alloc: Allocator,
pixels: Pixels,
width: u32,
height: u32,

pub fn init(alloc: Allocator, width: u32, height: u32) !Self {
    var pixels = Pixels.init(alloc);
    errdefer pixels.deinit();
    for (0..(width * height)) |_| {
        try pixels.append(rl.Color.rayWhite());
    }
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

pub fn insert(self: *Self, x: usize, y: usize, color: rl.Color) !void {
    const idx = y * self.width + x;
    _ = self.pixels.orderedRemove(idx);
    try self.pixels.insert(idx, color);
}
