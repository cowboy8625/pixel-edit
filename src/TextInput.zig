const std = @import("std");
const rl = @import("raylib");
const utils = @import("utils.zig");
const cast = utils.cast;
const StaticString = @import("StaticString.zig").StaticString;

const STRING_LENGTH = 1024;
const Self = @This();

rect: rl.Rectangle,
text: StaticString(STRING_LENGTH) = StaticString(STRING_LENGTH).init(),
background_color: rl.Color = rl.Color.gray,
border_color: rl.Color = rl.Color.black,
cursor_color: rl.Color = rl.Color.red,
has_focus: bool = false,
keypress_delay: f32 = 0.06,
keypress_timer: f32 = 0,
cursor_position: usize = 0,
font_size: i32 = 10,

pub fn init(x: f32, y: f32, width: f32, height: f32) Self {
    return .{
        .rect = .{
            .x = x,
            .y = y,
            .width = width,
            .height = height,
        },
    };
}

pub fn update(self: *Self, mouse_pos: rl.Vector2) bool {
    self.keypress_timer += rl.getFrameTime();
    var active = false;
    if (rl.checkCollisionPointRec(mouse_pos, self.rect)) {
        if (rl.isMouseButtonDown(.mouse_button_left)) {
            self.has_focus = true;
        }
        active = true;
    }

    const can_keypress = self.keypress_timer >= self.keypress_delay;
    if (can_keypress) {
        self.keypress_timer = 0;
    }

    if (rl.isKeyDown(.key_backspace) and can_keypress and self.text.len > 0) {
        self.text.pop();
        self.cursor_position -= 1;
    }

    if (!self.has_focus) return active;
    const char = cast(u8, rl.getCharPressed());
    if (char == 0) return active;
    self.text.push(char);
    self.cursor_position += 1;
    return active;
}

pub fn draw(self: *Self) void {
    const roundness = 0.05;
    const segments = 10;
    rl.drawRectangleRounded(self.rect, roundness, segments, self.background_color);
    rl.drawRectangleRoundedLines(self.rect, roundness, segments, self.border_color);
    const ctext: [*:0]const u8 = @ptrCast(self.text.chars[0..self.text.len]);
    const x = cast(i32, self.rect.x + 5);
    const y = cast(i32, self.rect.y + 5);
    rl.drawText(ctext, x, y, self.font_size, rl.Color.black);

    const text_before_cursor: [*:0]const u8 = @ptrCast(self.text.chars[0 .. self.text.len + 1]);
    const text_width = rl.measureText(text_before_cursor, self.font_size);
    rl.drawRectangleRounded(
        .{
            .x = self.rect.x + cast(f32, text_width) + 5,
            .y = self.rect.y,
            .width = 5,
            .height = self.rect.height - 2,
        },
        roundness,
        segments,
        self.cursor_color,
    );
}
