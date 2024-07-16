const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const rl = @import("raylib_zig");
const Context = @import("Context.zig");

const Self = @This();

pos: rl.Vector2(f32),
size: rl.Vector2(f32),
color: rl.Color,
pub fn init() Self {
    return .{
        .pos = rl.Vector2(f32).init(10, 10),
        .size = rl.Vector2(f32).init(10, 10),
        .color = rl.Color.black(),
    };
}
pub fn get_pos(self: *const Self) rl.Vector2(f32) {
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
    rl.DrawRectangleV(self.get_pos(), self.size, self.color);
    var color: rl.Color = undefined;
    if (ctx.canvas.pixels.get(ctx.cursor.pos.as(usize))) |c| if (c.equals(rl.Color.black())) {
        color = rl.Color.white();
    } else {
        color = rl.Color.black();
    };
    rl.DrawRectangleLinesV(
        self.get_pos().as(i32).sub(1),
        self.size.add(2).as(i32),
        color,
    );
}
