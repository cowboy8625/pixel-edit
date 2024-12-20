const std = @import("std");
const rl = @import("rl/mod.zig");
const widget = @import("widget.zig");
const Asset = @import("assets.zig");
const event = @import("event.zig");

const Self = @This();
const WIDTH: i32 = 7;
const OFFSET: i32 = 10;
const PADDING: i32 = 5;
const DEFAULT_CELL_WIDTH: i32 = 16;

const State = enum {
    Hidden,
    Visible,
};

buttons: std.MultiArrayList(widget.Button),
allocator: std.mem.Allocator,
state: State = .Visible,

pub fn init(allocator: std.mem.Allocator) !Self {
    var self = Self{
        .buttons = std.MultiArrayList(widget.Button){},
        .allocator = allocator,
    };
    try self.add_button("menu open and close", .close_control_pannel, Asset.loadTexture(Asset.MENU_ICON));
    return self;
}

pub fn deinit(self: *Self) void {
    for (0..self.buttons.len) |i| {
        rl.unloadTexture(self.buttons.items(.texture)[i]);
    }
    self.buttons.deinit(self.allocator);
}

pub fn hide(self: *Self) void {
    self.state = .Hidden;
}

pub fn show(self: *Self) void {
    self.state = .Visible;
}

pub fn add_button(self: *Self, name: []const u8, action: event.Event, texture: rl.Texture2D) !void {
    const idx = self.buttons.len;
    const w: i32 = @intCast(texture.width);
    const h: i32 = @intCast(texture.height);
    const x: i32 = @intCast(@mod(idx, Self.WIDTH));
    const y: i32 = @intCast(@divFloor(idx, Self.WIDTH));
    try self.buttons.append(self.allocator, .{
        .name = name,
        .x = x * (w + Self.PADDING) + Self.OFFSET,
        .y = y * (h + Self.PADDING) + Self.OFFSET,
        .action_left_click = action,
        .texture = texture,
    });
}

pub fn update(self: *Self, mouse_pos: rl.Vector2(f32), events: *std.ArrayList(event.Event)) !void {
    const menu_action: event.Event = if (self.state == .Visible) .close_control_pannel else .open_control_pannel;
    self.buttons.items(.action_left_click)[0] = menu_action;
    for (0..self.buttons.len) |i| {
        const x = self.buttons.items(.x)[i];
        const y = self.buttons.items(.y)[i];
        const texture = self.buttons.items(.texture)[i];
        const w = texture.width;
        const h = texture.height;
        const rect: rl.Rectangle(i32) = .{ .x = x, .y = y, .width = w, .height = h };
        const is_hovered = rl.checkCollisionPointRec(mouse_pos, rect.as(f32));
        if (is_hovered and rl.isMouseButtonPressed(.mouse_button_left)) {
            const action = self.buttons.items(.action_left_click)[i];
            try events.append(action);
            self.buttons.items(.hovered)[i] = false;
        }
        self.buttons.items(.hovered)[i] = is_hovered;
    }
}

fn getCellWidth(self: *const Self) i32 {
    const textures = self.buttons.items(.texture);
    if (textures.len == 0) return Self.DEFAULT_CELL_WIDTH + Self.PADDING;
    return textures[0].width + Self.PADDING;
}

fn drawHelpText(self: *const Self, help_text_id: ?usize) void {
    const i = help_text_id orelse return;
    const x = self.buttons.items(.x)[i] + 32;
    const y = self.buttons.items(.y)[i];
    const text_width = rl.measureText(self.buttons.items(.name)[i], 10);
    const text_rect: rl.Rectangle(i32) = .{ .x = x - 5, .y = y - 5, .width = text_width + 10, .height = 20 };
    rl.drawRectangleRoundedLinesEx(text_rect.as(f32), 0.5, 8, 0.3, rl.Color.black);
    rl.drawRectangleRounded(text_rect.as(f32), 0.5, 8, rl.Color.white);
    rl.drawText(self.buttons.items(.name)[i], x, y, 10, rl.Color.black);
}

fn drawClosed(self: *const Self) void {
    const texture = self.buttons.items(.texture)[0];
    const x = self.buttons.items(.x)[0];
    const y = self.buttons.items(.y)[0];
    const color = if (self.buttons.items(.hovered)[0]) self.buttons.items(.hover_color)[0] else rl.Color.white;
    rl.drawTexture(texture, x, y, color);
    const help_text_id: ?usize = if (self.buttons.items(.hovered)[0]) 0 else null;
    self.drawHelpText(help_text_id);
}

fn drawOpen(self: *const Self) void {
    var help_text_id: ?usize = null;
    const h = rl.getScreenHeight();
    const w = self.getCellWidth() * Self.WIDTH + Self.OFFSET;
    const rect: rl.Rectangle(i32) = .{ .x = 0, .y = 0, .width = w, .height = h };
    rl.drawRectangleRec(rect.as(f32), rl.Color.fromInt(0x282C34FF));
    for (0..self.buttons.len) |i| {
        const x = self.buttons.items(.x)[i];
        const y = self.buttons.items(.y)[i];
        const color = if (self.buttons.items(.hovered)[i]) self.buttons.items(.hover_color)[i] else rl.Color.white;
        const is_hovered = self.buttons.items(.hovered)[i];
        rl.drawTexture(self.buttons.items(.texture)[i], x, y, color);
        if (is_hovered) help_text_id = i;
    }
    self.drawHelpText(help_text_id);
}

pub fn draw(self: *const Self) void {
    switch (self.state) {
        .Visible => self.drawOpen(),
        .Hidden => self.drawClosed(),
    }
}
