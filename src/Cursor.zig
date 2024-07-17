const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const rl = @import("raylib");
const utils = @import("utils.zig");
const cast = utils.cast;
const Context = @import("Context.zig");

const Self = @This();

pos: rl.Vector2,
size: rl.Vector2,
color: rl.Color,
pub fn init() Self {
    return .{
        .pos = .{ .x = 10, .y = 10 },
        .size = .{ .x = 10, .y = 10 },
        .color = rl.Color.black,
    };
}
pub fn get_pos(self: *const Self) rl.Vector2 {
    return self.pos.multiply(self.size);
}

pub fn cursor_up(self: *Self) void {
    self.pos.y -= 1;
}

pub fn cursor_down(self: *Self) void {
    self.pos.y += 1;
}

pub fn cursor_left(self: *Self) void {
    self.pos.x -= 1;
}

pub fn cursor_right(self: *Self) void {
    self.pos.x += 1;
}

pub fn draw(self: *const Self, ctx: *Context) void {
    rl.drawRectangleV(self.get_pos(), self.size, self.color);
    var color: rl.Color = undefined;
    if (ctx.canvas.get(ctx.cursor.pos)) |c| if (c.toInt() == rl.Color.black.toInt()) {
        color = rl.Color.white;
    } else {
        color = rl.Color.black;
    };
    const pos = self.get_pos().subtractValue(1);
    const size = self.size.addValue(2);
    rl.drawRectangleLines(
        cast(i32, pos.x),
        cast(i32, pos.y),
        cast(i32, size.x),
        cast(i32, size.y),
        color,
    );
}
