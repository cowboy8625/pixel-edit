const std = @import("std");
const rl = @import("raylib");
const utils = @import("utils.zig");
const cast = utils.cast;

/// Dragable items can be dragged around on the screen without a camera
pub fn Dragable(comptime T: type) type {
    return struct {
        const Self = @This();

        rect: rl.Rectangle,
        button: rl.MouseButton,
        grabbed_at: ?rl.Vector2 = null,

        callback: (*const fn (rl.Rectangle, T) void),

        pub fn init(rect: rl.Rectangle, button: rl.MouseButton, callback: (fn (rl.Rectangle, T) void)) Self {
            return .{ .rect = rect, .button = button, .callback = callback };
        }

        pub fn update(self: *Self, pos: rl.Vector2) void {
            if (rl.isMouseButtonPressed(self.button) and rl.checkCollisionPointRec(pos, self.rect)) {
                self.grabbed_at = .{ .x = pos.x - self.rect.x, .y = pos.y - self.rect.y };
            } else if (rl.isMouseButtonReleased(.mouse_button_middle)) {
                self.grabbed_at = null;
            }

            if (self.grabbed_at) |p| {
                self.rect.x = pos.x - p.x;
                self.rect.y = pos.y - p.y;
            }
        }

        pub fn draw(self: Self, args: T) void {
            self.callback(self.rect, args);
        }
    };
}
