const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const rl = @import("raylib");
const Vector2 = @import("Vector2.zig").Vector2;
const Context = @import("Context.zig");

const Self = @This();

pos: Vector2(f32),
size: Vector2(f32),
color: rl.Color,
pub fn init() Self {
    return .{
        .pos = Vector2(f32).init(10, 10),
        .size = Vector2(f32).init(10, 10),
        .color = rl.Color.black,
    };
}
pub fn get_pos(self: *const Self) Vector2(f32) {
    return self.pos.mul(self.size);
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
    rl.drawRectangleV(self.get_pos().asRaylibVector2(), self.size.asRaylibVector2(), self.color);
    var color: rl.Color = undefined;
    if (ctx.canvas.pixels.get(ctx.cursor.pos.as(usize))) |c| if (c.toInt() == rl.Color.black.toInt()) {
        color = rl.Color.white;
    } else {
        color = rl.Color.black;
    };
    const pos = self.get_pos().as(i32).sub(1);
    const size = self.size.add(2).as(i32);
    rl.drawRectangleLines(
        pos.x,
        pos.y,
        size.x,
        size.y,
        color,
    );
}
