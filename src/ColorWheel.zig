const std = @import("std");
const rl = @import("rl/mod.zig");

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

pub fn move(self: *Self) void {
    if (!rl.isMouseButtonDown(.mouse_button_right)) return;
    const cursor = rl.getMousePosition();
    if (!self.bounding_box.contains(cursor)) return;
    self.bounding_box.x = cursor.x - self.bounding_box.width / 2;
    self.bounding_box.y = cursor.y - self.bounding_box.height / 2;
}

pub fn update(self: *Self) void {
    if (self.state == .hidden) return;
    self.move();
    if (!rl.isMouseButtonDown(.mouse_button_left)) return;
    const mouse = rl.getMousePosition();

    // Check Hue Slider
    const hueRect = rl.Rectangle(f32).init(50, 50, 300, 20);
    if (rl.checkCollisionPointRec(mouse, hueRect)) {
        self.selectedHue = ((mouse.x - hueRect.x) / hueRect.width) * 360.0;
    }

    const svRect = rl.Rectangle(f32).init(50, 100, 300, 300);
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

fn drawVisible(self: *const Self) void {
    // rl.drawRectangleRec(self.bounding_box, rl.Color.green);
    // rl.Color.fromHSV(hue: f32, saturation: f32, value: f32)

    // Draw Hue Slider
    const hueRect = rl.Rectangle(i32).init(50, 50, 300, 20);
    drawHueSlider(hueRect);
    rl.drawRectangleLinesEx(hueRect.as(f32), 2, rl.Color.black);

    // Draw Saturation/Value Box
    const svRect = rl.Rectangle(i32).init(50, 100, 300, 300);
    drawSVBox(svRect, self.selectedHue, rl.Color.fromHSV(self.selectedHue, self.selectedSV.x, self.selectedSV.y));
    rl.drawRectangleLinesEx(svRect.as(f32), 2, rl.Color.black);

    // Draw Current Color Indicator
    const selectedColor = rl.Color.fromHSV(self.selectedHue, self.selectedSV.x, self.selectedSV.y);
    rl.drawRectangle(400, 50, 100, 100, selectedColor);
    rl.drawText("Selected Color", 400, 160, 20, rl.Color.black);
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
// fn drawSVBox(rect: rl.Rectangle(i32), hue: f32, currentColor: rl.Color) void {
//     var image = rl.genImageColor(rect.width, rect.height, rl.Color.blank);
//     defer rl.unloadImage(image);
//
//     for (0..rl.cast(usize, rect.height)) |y| {
//         const value = 1.0 - (rl.cast(f32, y) / rl.cast(f32, rect.height));
//         for (0..rl.cast(usize, rect.width)) |x| {
//             const saturation = rl.cast(f32, x) / rl.cast(f32, rect.width);
//             const color = rl.Color.fromHSV(hue, saturation, value);
//
//             rl.imageDrawPixel(&image, rl.cast(i32, x), rl.cast(i32, y), color);
//         }
//     }
//
//     const texture = rl.loadTextureFromImage(image);
//     defer rl.unloadTexture(texture);
//
//     rl.drawTexture(texture, rect.x, rect.y, rl.Color.white);
//
//     const currentHSV = rl.Color.toHSV(currentColor);
//     const markerX = rect.x + rl.cast(i32, currentHSV.y * rl.cast(f32, rect.width));
//     const markerY = rect.y + rl.cast(i32, (1.0 - currentHSV.z) * rl.cast(f32, rect.height));
//
//     rl.drawCircle(markerX, markerY, 5, rl.Color.black);
// }
