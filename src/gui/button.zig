const std = @import("std");
const ray = @cImport(@cInclude("raylib.h"));

pub const Button = struct {
    const Self = @This();

    text: [:0]const u8,
    position: ray.Vector2,

    // Defaults

    color_bg: ray.Color = ray.RED,
    color_text: ray.Color = ray.WHITE,
    is_hovered: bool = false,
    font_size: f32 = 40,
    offset: f32 = 40,

    fn get_rect(self: *Self) ray.Rectangle {
        const text_size = ray.MeasureTextEx(ray.GetFontDefault(), self.text, self.font_size, 0);
        const w = text_size.x + self.offset;
        const h = text_size.y + self.offset;
        const x = self.position.x; // - width / 2;
        const y = self.position.y; // - height / 2;
        return ray.Rectangle{ .x = x, .y = y, .width = w, .height = h };
    }

    pub fn height(self: *Self) f32 {
        return self.get_rect().height;
    }

    pub fn update(self: *Self) bool {
        const bounding_box = self.get_rect();
        self.is_hovered = false;
        if (ray.CheckCollisionPointRec(ray.GetMousePosition(), bounding_box)) {
            self.is_hovered = true;
            if (ray.IsMouseButtonPressed(ray.MOUSE_LEFT_BUTTON)) {
                return true;
            }
        }
        return false;
    }

    pub fn draw(self: *Self) void {
        const rect = self.get_rect();
        const color_bg = if (!self.is_hovered) self.color_bg else ray.BLUE;
        ray.DrawRectangleV(ray.Vector2{ .x = rect.x, .y = rect.y }, ray.Vector2{ .x = rect.width, .y = rect.height }, color_bg);
        const x_text = (self.offset / 4) + rect.x;
        const y_text = (self.offset / 2) + rect.y;
        ray.DrawText(self.text, @as(c_int, @intFromFloat(x_text)), @as(c_int, @intFromFloat(y_text)), @as(c_int, @intFromFloat(self.font_size)), self.color_text);
    }
};
