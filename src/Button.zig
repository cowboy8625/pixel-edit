const std = @import("std");
const rl = @import("raylib");
const utils = @import("utils.zig");
const cast = utils.cast;

pub fn Button(comptime T: type) type {
    return struct {
        const Self = @This();

        texture: rl.Texture2D,
        pos: rl.Vector2,
        hitbox: rl.Rectangle,

        callback: (*const fn (T) void),

        pub fn init(texture: rl.Texture2D, pos: rl.Vector2, callback: (*const fn (T) void)) Self {
            return .{
                .texture = texture,
                .pos = pos,
                .hitbox = .{
                    .x = pos.x,
                    .y = pos.y,
                    .width = cast(f32, texture.width),
                    .height = cast(f32, texture.height),
                },
                .callback = callback,
            };
        }

        pub fn setHitBox(self: *Self, callback: (*const fn (rl.Rectangle) rl.Rectangle)) void {
            self.hitbox = callback(self.hitbox);
        }

        pub fn deinit(self: *Self) void {
            rl.unloadTexture(self.texture);
        }

        pub fn update(self: *Self, mouse_pos: rl.Vector2, args: T) bool {
            if (rl.checkCollisionPointRec(mouse_pos, self.hitbox)) {
                if (rl.isMouseButtonPressed(.mouse_button_left)) {
                    self.callback(args);
                    return true;
                }
            }
            return false;
        }

        pub fn draw(self: *Self) void {
            const origin: rl.Rectangle = .{
                .x = 0,
                .y = 0,
                .width = cast(f32, self.texture.width),
                .height = cast(f32, self.texture.height),
            };
            rl.drawTexturePro(self.texture, origin, self.hitbox, .{ .x = 0, .y = 0 }, 0, rl.Color.white);
        }
    };
}
