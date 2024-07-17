const std = @import("std");
const rl = @import("raylib");
const cast = @import("utils.zig").cast;
const Context = @import("Context.zig");
const Vector2 = @import("Vector2.zig").Vector2;

pub const Self = @This();

pub fn default() Self {
    return .{};
}

pub fn draw(_: *const Self, ctx: *Context) !void {
    const height = rl.getScreenHeight();
    const width = rl.getScreenWidth();
    const bar_height = 20;
    const font_size = 20;

    const rect_pos = Vector2(f32).fromRaylibVevtor2(rl.getScreenToWorld2D(
        .{
            .x = 0.0,
            .y = cast(f32, height - bar_height),
        },
        ctx.camera.*,
    )).as(i32);
    rl.drawRectangle(rect_pos.x, rect_pos.y, width, bar_height, rl.fade(rl.Color.red, 0.5));

    const mode_pos = Vector2(f32).fromRaylibVevtor2(rl.getScreenToWorld2D(
        .{
            .x = 10.0,
            .y = cast(f32, height - bar_height),
        },
        ctx.camera.*,
    )).as(i32);
    rl.drawText(@tagName(ctx.mode), mode_pos.x, mode_pos.y, font_size, rl.Color.ray_white);
    const text = try std.fmt.bufPrintZ(ctx.scratch_buffer, "{d}/{d}", .{ ctx.cursor.pos.x, ctx.cursor.pos.y });
    const text_size = rl.measureText(text, font_size);

    const cursor_pos = Vector2(f32).fromRaylibVevtor2(rl.getScreenToWorld2D(
        .{
            .x = cast(f32, width - 10 - text_size),
            .y = cast(f32, height - bar_height),
        },
        ctx.camera.*,
    )).as(i32);
    rl.drawText(text, cursor_pos.x, cursor_pos.y, font_size, rl.Color.ray_white);
}
