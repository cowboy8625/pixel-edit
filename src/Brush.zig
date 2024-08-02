const std = @import("std");
const rl = @import("raylib");
const utils = @import("utils.zig");
const cast = utils.cast;

const Self = @This();

color: rl.Color = rl.Color.ray_white,
show_outline: bool = false,

pub fn init() Self {
    return .{};
}

pub fn showOutline(self: *Self) void {
    self.show_outline = true;
}
pub fn hideOutline(self: *Self) void {
    self.show_outline = false;
}

pub fn draw(self: *const Self, mouse_pos: rl.Vector2, cell_size: rl.Vector2) void {
    if (!self.show_outline) return;
    const pos: rl.Vector2 = .{
        .x = @divFloor(mouse_pos.x, cell_size.x) * cell_size.x,
        .y = @divFloor(mouse_pos.y, cell_size.y) * cell_size.y,
    };
    rl.drawRectangleLinesEx(
        .{
            .x = pos.x,
            .y = pos.y,
            .width = cell_size.x,
            .height = cell_size.y,
        },
        2,
        self.color.contrast(-0.5),
    );
}
