const std = @import("std");
const rl = @import("raylib_zig");

pub fn draw_status_bar() void {
    rl.DrawRectangle(0, 0, 800, 20, rl.Fade(rl.Color.red(), 0.5));
    rl.DrawRectangle(0, 20, 800, 20, rl.Fade(rl.Color.green(), 0.5));
    rl.DrawRectangle(0, 40, 800, 20, rl.Fade(rl.Color.blue(), 0.5));
}
