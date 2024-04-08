const std = @import("std");
const rl = @import("raylib_zig");
const cast = rl.utils.cast;

pub fn draw_command_bar() void {
    const screen_width = rl.GetScreenWidth();
    const screen_height = rl.GetScreenHeight();
    const width = cast(f32, screen_width) * 0.9;
    const height = 40;
    const pos: rl.Vector2(f32) = .{
        .x = (cast(f32, screen_width) - width) / 2.0,
        .y = cast(f32, @divFloor((screen_height - height), 2)),
    };
    const size: rl.Vector2(f32) = .{ .x = width, .y = height };
    rl.DrawRectangleV(pos, size, rl.Color.black());
}
