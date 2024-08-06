const std = @import("std");
const rl = @import("raylib");
const utils = @import("utils.zig");
const cast = utils.cast;
const assets = @import("assets.zig");

const Self = @This();

color: rl.Color = rl.Color.ray_white,
show_outline: bool = false,
texture: rl.Texture2D,

pub fn init() Self {
    return .{
        .texture = assets.loadTexture(assets.CROSS_HAIRS_ICON),
    };
}

pub fn deinit(self: *Self) void {
    rl.unloadTexture(self.texture);
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
    rl.drawRectangleRec(
        .{
            .x = pos.x,
            .y = pos.y,
            .width = cell_size.x,
            .height = cell_size.y,
        },
        self.color,
    );
    const cross_hair_pos: rl.Vector2 = .{
        .x = mouse_pos.x - @divFloor(cast(f32, self.texture.width), 2),
        .y = mouse_pos.y - @divFloor(cast(f32, self.texture.height), 2),
    };
    rl.drawTextureEx(self.texture, cross_hair_pos, 0, 1, rl.Color.white);
}
