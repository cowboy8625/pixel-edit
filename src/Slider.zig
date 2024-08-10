const std = @import("std");
const rl = @import("raylib");
const utils = @import("utils.zig");
const cast = utils.cast;

const Context = @import("Context.zig");

pub fn Slider(comptime V: type, comptime T: type) type {
    const Callback = (*const fn (V, T) V);
    return struct {
        const Self = @This();

        rect: rl.Rectangle,
        min: V,
        max: V,
        value: V,
        callback: Callback,
        line_color: rl.Color = rl.Color.gray,
        circle_color: rl.Color = rl.Color.dark_gray,

        pub fn init(value: V, min: V, max: V, size: rl.Vector2, callback: Callback) Self {
            return .{
                .rect = .{
                    .x = 0,
                    .y = 0,
                    .width = size.x,
                    .height = size.y,
                },
                .value = value,
                .min = min,
                .max = max,
                .callback = callback,
            };
        }

        pub fn update(self: *Self, mouse_pos: rl.Vector2, data: T) bool {
            var active = false;
            if (rl.checkCollisionPointRec(mouse_pos, self.rect)) {
                if (rl.isMouseButtonDown(.mouse_button_left)) {
                    var value = cast(V, cast(f32, rl.getMouseX()) - self.rect.x);
                    value = @min(self.max, @max(value, self.min));
                    self.value = self.callback(self.value, data);
                }
                active = true;
            }
            return active;
        }

        pub fn draw(self: *Self, pos: rl.Vector2) void {
            self.rect.x = pos.x;
            self.rect.y = pos.y;
            rl.drawRectangleRounded(self.rect, 0.5, 8, self.line_color);
            const v = cast(f32, self.value);
            const y_offset = self.rect.y + @divFloor(self.rect.height, 2);
            rl.drawCircleV(.{ .x = self.rect.x + v, .y = y_offset }, 7, self.circle_color);
        }
    };
}
