const std = @import("std");
const rl = @import("rl/mod.zig");
const event = @import("event.zig");

pub const Button = struct {
    x: i32,
    y: i32,
    action_left_click: event.Event,
    hovered: bool = false,
    hover_color: rl.Color = rl.Color.red,
    texture: rl.Texture2D,
};
