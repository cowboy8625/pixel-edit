const std = @import("std");
const ray = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

pub const Button = struct {
    const Self = @This();

    text: [:0]const u8,
    position: ray.Vector2,

    // Defaults

    texture: ?ray.Texture2D = null,
    color_bg: ray.Color = ray.LIGHTGRAY,
    color_text: ray.Color = ray.WHITE,
    color_hover: ray.Color = ray.Color{ .r = 40, .g = 40, .b = 40, .a = 255 },
    is_hovered: bool = false,
    font_size: f32 = 40,
    offset: f32 = 40,

    fn get_rect(self: *Self) ray.Rectangle {
        if (self.texture) |texture| {
            const w: f32 = @floatFromInt(texture.width);
            const h: f32 = @floatFromInt(texture.height);
            return .{ .x = self.position.x, .y = self.position.y, .width = w, .height = h };
        }
        const text_size = ray.MeasureTextEx(ray.GetFontDefault(), self.text, self.font_size, 0);
        const w = text_size.x + self.offset;
        const h = text_size.y + self.offset;
        const x = self.position.x;
        const y = self.position.y;
        return ray.Rectangle{ .x = x, .y = y, .width = w, .height = h };
    }

    pub fn width(self: *Self) f32 {
        return self.get_rect().width;
    }

    pub fn height(self: *Self) f32 {
        return self.get_rect().height;
    }

    pub fn update(self: *Self) ?enum { Left, Right } {
        const bounding_box = self.get_rect();
        self.is_hovered = false;
        if (ray.CheckCollisionPointRec(ray.GetMousePosition(), bounding_box)) {
            self.is_hovered = true;
            if (ray.IsMouseButtonPressed(ray.MOUSE_LEFT_BUTTON)) {
                return .Left;
            } else if (ray.IsMouseButtonPressed(ray.MOUSE_RIGHT_BUTTON)) {
                return .Right;
            }
        }
        return null;
    }

    pub fn draw(self: *Self) void {
        const color_bg = if (!self.is_hovered) self.color_bg else self.color_hover;

        const rect = self.get_rect();

        // zig fmt: off
        ray.DrawRectangleV(
            .{
                .x = rect.x,
                .y = rect.y
            },
            .{
                .x = rect.width,
                .y = rect.height
            },
            color_bg
        );

        if (self.texture) |texture| {
            ray.DrawTexture(texture, @as(c_int, @intFromFloat(self.position.x)), @as(c_int, @intFromFloat(self.position.y)), self.color_text);
            return;
        }

        const x_text = (self.offset / 4) + rect.x;
        const y_text = (self.offset / 2) + rect.y;

        // zig fmt: off
        ray.DrawText(
            self.text,
            @as(c_int, @intFromFloat(x_text)),
            @as(c_int, @intFromFloat(y_text)),
            @as(c_int, @intFromFloat(self.font_size)),
            self.color_text
        );
    }
};
