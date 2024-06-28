const std = @import("std");
const Context = @import("../Context.zig");
const rl = @import("raylib_zig");
const cast = rl.utils.cast;

pub fn draw_canvas(ctx: *Context) void {
    const size = ctx.cursor.size.as(usize);
    for (0.., ctx.canvas.pixels.items) |i, color| {
        const x = (i % cast(usize, ctx.canvas.width)) * size.x;
        const y = (i / cast(usize, ctx.canvas.width)) * size.y;
        const pos = rl.Vector2(usize).init(x, y).as(f32);
        rl.DrawRectangleV(pos, size.as(f32), color);
    }
}
