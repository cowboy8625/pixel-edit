const std = @import("std");
const rl = @import("rl/mod.zig");
const event = @import("event.zig");

pub const Button = struct {
    const Self = @This();
    pub const Action = *const fn (*Self) event.Event;
    name: []const u8,
    event: event.Event,
    action_left_click: Self.Action,
    hovered: bool = false,
    hover_color: rl.Color,
    texture: rl.Texture2D,
};

pub const Input = struct {
    pub const MAX_LEN = 13;
    name: []const u8,
    action_left_click: event.Event,
    hovered: bool = false,
    hover_color: rl.Color,
    contents: [MAX_LEN]u8 = [_]u8{0} ** MAX_LEN,
    cursor: usize = 0,
};

pub fn drawHelpText(vec: rl.Vector2(i32), text: []const u8) void {
    const text_width = rl.measureText(text, 10);
    const text_rect: rl.Rectangle(i32) = .{ .x = vec.x - 5, .y = vec.y - 5, .width = text_width + 10, .height = 20 };
    rl.drawRectangleRoundedLinesEx(text_rect.as(f32), 0.5, 8, 0.3, rl.Color.black);
    rl.drawRectangleRounded(text_rect.as(f32), 0.5, 8, rl.Color.white);
    rl.drawText(text, vec.x, vec.y, 10, rl.Color.black);
}
