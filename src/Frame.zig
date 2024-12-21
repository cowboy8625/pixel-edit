const std = @import("std");
const rl = @import("rl/mod.zig");

const Self = @This();
bounding_box: rl.Rectangle(i32),
pixels: std.AutoHashMap(rl.Vector2(i32), rl.Color),

pub fn init(bounding_box: rl.Rectangle(i32), allocator: std.mem.Allocator) Self {
    return Self{
        .bounding_box = bounding_box,
        .pixels = std.AutoHashMap(rl.Vector2(i32), rl.Color).init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.pixels.deinit();
}

pub fn insert(self: *Self, pixel: rl.Vector2(i32), color: rl.Color) !bool {
    if (!self.bounding_box.contains(pixel)) return false;
    try self.pixels.put(pixel, color);
    return true;
}
