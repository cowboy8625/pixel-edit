const std = @import("std");
const rl = @import("raylib_zig");
const mode = @import("../mode.zig");

pub fn draw_status_bar(state: mode.State, cursor_pos: rl.Vector2(i32), buffer: *[]u8) !void {
    const height = rl.GetScreenHeight();
    const width = rl.GetScreenWidth();
    const bar_height = 20;
    const font_size = 20;
    rl.DrawRectangle(0, height - bar_height, width, bar_height, rl.Fade(rl.Color.red(), 0.5));
    rl.DrawText(@tagName(state), 10, height - bar_height, font_size, rl.Color.rayWhite());
    const text = try std.fmt.bufPrintZ(buffer.*, "{d}/{d}", .{ cursor_pos.x, cursor_pos.y });
    const text_size = rl.MeasureText(text, font_size);
    rl.DrawText(text, width - 10 - text_size, height - bar_height, font_size, rl.Color.rayWhite());
}
