const std = @import("std");
const rl = @import("rl/mod.zig");

const Self = @This();
const State = enum { visible, hidden };
bounding_box: rl.Rectangle(f32),
state: Self.State = .hidden,

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

pub fn update(self: *Self) void {
    if (self.state == .hidden) return;
    if (!rl.isMouseButtonDown(.mouse_button_right)) return;
    const cursor = rl.getMousePosition();
    if (!self.bounding_box.contains(cursor)) return;
    self.bounding_box.x = cursor.x - self.bounding_box.width / 2;
    self.bounding_box.y = cursor.y - self.bounding_box.height / 2;
}

pub fn draw(self: *const Self) void {
    switch (self.state) {
        .hidden => return,
        .visible => {
            rl.drawRectangleRec(self.bounding_box, rl.Color.green);
        },
    }
}
