const std = @import("std");
const rl = @import("raylib_zig");
const Context = @import("../Context.zig");

pub fn draw_status_bar(ctx: *Context) !void {
    const height = rl.GetScreenHeight();
    const width = rl.GetScreenWidth();
    const bar_height = 20;
    const font_size = 20;
    rl.DrawRectangle(0, height - bar_height, width, bar_height, rl.Fade(rl.Color.red(), 0.5));
    rl.DrawText(@tagName(ctx.mode), 10, height - bar_height, font_size, rl.Color.rayWhite());
    const text = try std.fmt.bufPrintZ(ctx.scratch_buffer, "{d}/{d}", .{ ctx.cursor.pos.x, ctx.cursor.pos.y });
    const text_size = rl.MeasureText(text, font_size);
    rl.DrawText(text, width - 10 - text_size, height - bar_height, font_size, rl.Color.rayWhite());
}
