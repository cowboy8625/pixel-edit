const std = @import("std");
const rl = @import("raylib");
const utils = @import("utils.zig");
const cast = utils.cast;
const DEFAULT_FONT_SIZE = 20;

pub fn Button(comptime T: type) type {
    return struct {
        const Self = @This();

        texture: ?rl.Texture2D,
        text: ?[]const u8,
        pos: rl.Vector2,
        hitbox: rl.Rectangle,
        font_size: f32,
        callback: (*const fn (T) void),
        text_color: rl.Color = rl.Color.ray_white,
        hover_color: rl.Color = rl.Color.green,
        is_hovered: bool = false,

        pub fn init(text: ?[]const u8, texture: ?rl.Texture2D, pos: rl.Vector2, font_size: f32, callback: (*const fn (T) void)) Self {
            const spacing = 4;
            var size: rl.Vector2 = .{ .x = 0, .y = 0 };
            if (texture) |t| {
                size.x = cast(f32, t.width);
                size.y = cast(f32, t.height);
            }
            if (text) |t| {
                const ctext: [*:0]const u8 = @ptrCast(t);
                const s = rl.measureTextEx(rl.getFontDefault(), ctext, font_size, spacing);
                if (size.x < s.x) size.x = s.x;
                if (size.y < s.y) size.y = s.y;
            }

            const hitbox = .{
                .x = pos.x,
                .y = pos.y,
                .width = size.x,
                .height = size.y,
            };
            return .{
                .texture = texture,
                .text = text,
                .pos = pos,
                .hitbox = hitbox,
                .font_size = font_size,
                .callback = callback,
            };
        }

        pub fn initWithTexture(texture: rl.Texture2D, pos: rl.Vector2, callback: (*const fn (T) void)) Self {
            return Self.init(null, texture, pos, DEFAULT_FONT_SIZE, callback);
        }

        pub fn initWithText(text: []const u8, pos: rl.Vector2, callback: (*const fn (T) void)) Self {
            return Self.init(text, null, pos, DEFAULT_FONT_SIZE, callback);
        }

        pub fn setHitBox(self: *Self, callback: (*const fn (rl.Rectangle) rl.Rectangle)) void {
            self.hitbox = callback(self.hitbox);
        }

        pub fn setTextColor(self: *Self, color: rl.Color) void {
            self.text_color = color;
        }

        pub fn deinit(self: *Self) void {
            if (self.texture) |texture| rl.unloadTexture(texture);
        }

        pub fn update(self: *Self, mouse_pos: rl.Vector2, args: T) bool {
            if (rl.checkCollisionPointRec(mouse_pos, self.hitbox)) {
                self.is_hovered = true;
                if (rl.isMouseButtonPressed(.mouse_button_left)) {
                    self.callback(args);
                    return true;
                }
                return true;
            }
            self.is_hovered = false;
            return false;
        }

        fn drawTexture(self: *Self) void {
            if (self.texture == null) return;
            const origin: rl.Rectangle = .{
                .x = 0,
                .y = 0,
                .width = cast(f32, self.texture.?.width),
                .height = cast(f32, self.texture.?.height),
            };
            rl.drawTexturePro(self.texture.?, origin, self.hitbox, .{ .x = 0, .y = 0 }, 0, rl.Color.white);
        }

        fn drawText(self: *Self) void {
            if (self.text == null) return;
            const ctext: [*:0]const u8 = @ptrCast(self.text);
            const color = if (self.is_hovered) self.hover_color else self.text_color;
            rl.drawTextEx(rl.getFontDefault(), ctext, self.pos, self.font_size, 0, color);
        }
        pub fn draw(self: *Self) void {
            self.drawTexture();
            self.drawText();
        }
    };
}
