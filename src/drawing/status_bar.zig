const std = @import("std");
const rl = @import("raylib_zig");
const cast = rl.utils.cast;
const Context = @import("../Context.zig");

pub fn draw_status_bar(ctx: *Context) !void {
    const height = rl.GetScreenHeight();
    const width = rl.GetScreenWidth();
    const bar_height = 20;
    const font_size = 20;

    const rect_pos = rl.GetScreenToWorld2D(
        .{
            .x = 0.0,
            .y = cast(f32, height - bar_height),
        },
        ctx.camera.*,
    ).as(i32);
    rl.DrawRectangle(rect_pos.x, rect_pos.y, width, bar_height, rl.Fade(rl.Color.red(), 0.5));

    const mode_pos = rl.GetScreenToWorld2D(
        .{
            .x = 10.0,
            .y = cast(f32, height - bar_height),
        },
        ctx.camera.*,
    ).as(i32);
    rl.DrawText(@tagName(ctx.mode), mode_pos.x, mode_pos.y, font_size, rl.Color.rayWhite());
    const text = try std.fmt.bufPrintZ(ctx.scratch_buffer, "{d}/{d}", .{ ctx.cursor.pos.x, ctx.cursor.pos.y });
    const text_size = rl.MeasureText(text, font_size);

    const cursor_pos = rl.GetScreenToWorld2D(
        .{
            .x = cast(f32, width - 10 - text_size),
            .y = cast(f32, height - bar_height),
        },
        ctx.camera.*,
    ).as(i32);
    rl.DrawText(text, cursor_pos.x, cursor_pos.y, font_size, rl.Color.rayWhite());
}
