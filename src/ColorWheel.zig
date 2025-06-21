const std = @import("std");
const rl = @import("rl/mod.zig");
const ControlPannel = @import("ControlPannel.zig");

const Self = @This();
const State = enum { visible, hidden };
bounding_box: rl.Rectangle(f32),
state: Self.State = .hidden,
selectedHue: f32 = 0.0,
selectedSV: rl.Vector2(f32) = rl.Vector2(f32).init(0.5, 0.5),

pub fn init(bounding_box: rl.Rectangle(f32)) Self {
    return .{
        .bounding_box = bounding_box,
    };
}

pub fn show(self: *Self) void {
    self.state = .visible;
}

pub fn hide(self: *Self) void {
    self.state = .hidden;
}

pub fn getSelectedColor(self: *const Self) rl.Color {
    return rl.Color.fromHSV(self.selectedHue, self.selectedSV.x, self.selectedSV.y);
}

pub fn setColor(self: *Self, color: rl.Color) void {
    const hsv = color.toHSV();
    self.selectedHue = hsv.x;
    self.selectedSV.x = hsv.y;
    self.selectedSV.y = hsv.z;
}

pub fn move(self: *Self, cursor: rl.Vector2(f32)) void {
    if (!rl.isMouseButtonDown(.mouse_button_right)) return;
    if (!self.bounding_box.contains(cursor)) return;
    self.bounding_box.x = cursor.x - self.bounding_box.width / 2;
    self.bounding_box.y = cursor.y - self.bounding_box.height / 2;
}

fn adjustPos(self: *Self, control_pannel_width: f32, control_pannel_state: ControlPannel.State) void {
    const is_visible = control_pannel_state == .visible;
    const is_touching = self.bounding_box.x <= control_pannel_width;
    if (!is_visible) return;
    if (!is_touching) return;
    self.bounding_box.x = control_pannel_width;
}

pub fn update(self: *Self, mouse: rl.Vector2(f32), control_pannel_width: f32, control_pannel_state: ControlPannel.State) void {
    if (self.state == .hidden) return;
    self.move(mouse);
    self.adjustPos(control_pannel_width, control_pannel_state);
    if (!rl.isMouseButtonDown(.mouse_button_left)) return;

    const hueRect = self.getHueRect();
    if (rl.checkCollisionPointRec(mouse, hueRect)) {
        self.selectedHue = ((mouse.x - hueRect.x) / hueRect.width) * 360.0;
    }

    const svRect = self.getSVRect();
    if (rl.checkCollisionPointRec(mouse, svRect)) {
        self.selectedSV.x = (mouse.x - svRect.x) / svRect.width;
        self.selectedSV.y = 1.0 - (mouse.y - svRect.y) / svRect.height;
    }
}

pub fn draw(self: *const Self) void {
    switch (self.state) {
        .hidden => return,
        .visible => self.drawVisible(),
    }
}

fn getHueRect(self: *const Self) rl.Rectangle(f32) {
    return rl.Rectangle(f32).init(self.bounding_box.x, self.bounding_box.y, 200, 15);
}

fn getSVRect(self: *const Self) rl.Rectangle(f32) {
    return rl.Rectangle(f32).init(self.bounding_box.x, self.bounding_box.y + 20, 200, 180);
}

fn getSelectedColorRect(self: *const Self) rl.Rectangle(f32) {
    return rl.Rectangle(f32).init(self.bounding_box.x + self.bounding_box.width + 20, self.bounding_box.y, 64, 64);
}

fn drawVisible(self: *const Self) void {
    const hueRect = self.getHueRect();
    drawHueSlider(hueRect.as(i32));
    rl.drawRectangleLinesEx(hueRect, 2, rl.Color.black);

    const svRect = self.getSVRect();
    drawSVBox(svRect.as(i32), self.selectedHue, rl.Color.fromHSV(self.selectedHue, self.selectedSV.x, self.selectedSV.y));
    rl.drawRectangleLinesEx(svRect, 2, rl.Color.black);

    const selectedColor = rl.Color.fromHSV(self.selectedHue, self.selectedSV.x, self.selectedSV.y);
    const colorRect = self.getSelectedColorRect();
    rl.drawRectangleRec(colorRect, selectedColor);
    rl.drawTextZ(
        rl.textFormat("#%X", .{self.getSelectedColor().toInt()}),
        rl.cast(i32, self.bounding_box.x + self.bounding_box.width + 20),
        rl.cast(i32, self.bounding_box.y + colorRect.height + 10),
        20,
        rl.Color.black,
    );
}

fn drawHueSlider(rect: rl.Rectangle(i32)) void {
    for (0..rl.cast(usize, rect.width)) |x| {
        const hue = (rl.cast(f32, x) / rl.cast(f32, rect.width)) * 360.0;
        const color = rl.Color.fromHSV(hue, 1.0, 1.0);

        rl.drawRectangle(rect.x + rl.cast(i32, x), rect.y, 1, rect.height, color);
    }
}

// TODO: Move this to the GPU at some point
fn drawSVBox(rect: rl.Rectangle(i32), hue: f32, _: rl.Color) void {
    // var pos: ?rl.Vector2(i32) = null;
    for (0..rl.cast(usize, rect.height)) |y| {
        for (0..rl.cast(usize, rect.width)) |x| {
            const saturation = rl.cast(f32, x) / rl.cast(f32, rect.width);
            const value = 1.0 - (rl.cast(f32, y) / rl.cast(f32, rect.height));
            const color = rl.Color.fromHSV(hue, saturation, value);

            const xx = rect.x + rl.cast(i32, x);
            const yy = rect.y + rl.cast(i32, y);
            rl.drawPixel(xx, yy, color);

            // if (currentColor.r == color.r and currentColor.g == color.g and currentColor.b == color.b and currentColor.a == color.a) {
            //     pos = .{ .x = xx, .y = yy };
            // }
        }
    }
    // if (pos) |p|
    //     rl.drawCircle(p.x, p.x, 5, rl.Color.black);
}
