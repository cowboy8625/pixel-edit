const std = @import("std");
const rl = @import("rl/mod.zig");
const widget = @import("widget.zig");
const Asset = @import("assets.zig");
const event = @import("event.zig");
const main = @import("main.zig");

const Self = @This();
const WIDTH: i32 = 7;
const OFFSET: i32 = 10;
const PADDING: i32 = 5;
const DEFAULT_CELL_WIDTH: i32 = 16;

const State = enum {
    hidden,
    visible,
};

buttons: std.MultiArrayList(widget.Button),
inputs: std.MultiArrayList(widget.Input),
allocator: std.mem.Allocator,
state: State = .visible,

pub fn init(allocator: std.mem.Allocator) !Self {
    var self = Self{
        .buttons = std.MultiArrayList(widget.Button){},
        .inputs = std.MultiArrayList(widget.Input){},
        .allocator = allocator,
    };
    try self.add_button("menu open and close", .close_control_pannel, Asset.loadTexture(Asset.MENU_ICON));
    try self.add_button("load image", .testing, Asset.loadTexture(Asset.LOAD_ICON));
    try self.add_button("save image", .testing, Asset.loadTexture(Asset.SAVE_ICON));
    try self.add_button("pencil tool", .draw, Asset.loadTexture(Asset.PENCIL_TOOL_ICON));
    try self.add_button("eraser tool", .testing, Asset.loadTexture(Asset.ERASER_TOOL_ICON));
    try self.add_button("bucket tool", .testing, Asset.loadTexture(Asset.BUCKET_TOOL_ICON));
    try self.add_button("grid", .testing, Asset.loadTexture(Asset.GRID_ICON));
    try self.add_button("color picker", .testing, Asset.loadTexture(Asset.COLOR_PICKER_ICON));
    try self.add_button("color wheel", .testing, Asset.loadTexture(Asset.COLOR_WHEEL_ICON));
    try self.add_button("rotate left", .testing, Asset.loadTexture(Asset.ROTATE_LEFT_ICON));
    try self.add_button("play animation", .testing, Asset.loadTexture(Asset.PLAY_ICON));
    try self.add_button("next frame", .testing, Asset.loadTexture(Asset.RIGHT_ARROW_ICON));
    try self.add_button("previous frame", .testing, Asset.loadTexture(Asset.LEFT_ARROW_ICON));
    try self.add_button("rotate right", .testing, Asset.loadTexture(Asset.ROTATE_RIGHT_ICON));
    try self.add_button("draw line tool", .testing, Asset.loadTexture(Asset.LINE_TOOL_ICON));
    try self.add_button("flip vertical", .testing, Asset.loadTexture(Asset.FLIP_VERTICAL_ICON));
    try self.add_button("flip horizontal", .testing, Asset.loadTexture(Asset.FLIP_HORIZONTAL_ICON));
    try self.add_button("frames tool", .testing, Asset.loadTexture(Asset.FRAMES_ICON));
    try self.add_button("selection tool", .testing, Asset.loadTexture(Asset.SELECTION_ICON));
    try self.add_input("Width", .{ .clicked = .width_input });
    try self.add_input("Height", .{ .clicked = .height_input });

    return self;
}

pub fn deinit(self: *Self) void {
    for (0..self.buttons.len) |i| {
        rl.unloadTexture(self.buttons.items(.texture)[i]);
    }
    self.buttons.deinit(self.allocator);
    self.inputs.deinit(self.allocator);
}

pub fn hide(self: *Self) void {
    self.state = .hidden;
}

pub fn show(self: *Self) void {
    self.state = .visible;
}

pub fn add_button(self: *Self, name: []const u8, action: event.Event, texture: rl.Texture2D) !void {
    try self.buttons.append(self.allocator, .{
        .name = name,
        .action_left_click = action,
        .hover_color = rl.Color.fromInt(0x343028FF),
        .texture = texture,
    });
}

pub fn add_input(self: *Self, name: []const u8, action: event.Event) !void {
    try self.inputs.append(self.allocator, .{
        .name = name,
        .action_left_click = action,
        .hover_color = rl.Color.fromInt(0x343028FF),
    });
}

pub fn update_input(self: *Self, input_kind: event.WidgetEvent, state: *main.State) void {
    const idx: usize = switch (input_kind) {
        .width_input => 0,
        .height_input => 1,
    };

    if (rl.isKeyPressed(.key_enter)) {
        state.* = .none;
    } else if (rl.isKeyPressed(.key_backspace)) {
        const contents = &self.inputs.items(.contents)[idx];
        const cursor = &self.inputs.items(.cursor)[idx];
        if (cursor.* > 0) {
            cursor.* -= 1;
            contents.*[cursor.*] = 0;
        }
    }
    const c = rl.getCharPressed();
    if (c == 0) return;
    if (c < 48 or c > 57) return;
    const ch: u8 = @truncate(@as(u32, @intCast(c)));
    const contents = &self.inputs.items(.contents)[idx];
    const cursor = &self.inputs.items(.cursor)[idx];
    if (cursor.* >= widget.Input.MAX_LEN) return;
    contents.*[cursor.*] = ch;
    cursor.* += 1;
}

pub fn update(self: *Self, mouse_pos: rl.Vector2(f32), events: *std.ArrayList(event.Event)) !void {
    switch (self.state) {
        .hidden => try self.updateClosed(mouse_pos, events),
        .visible => try self.updateOpen(mouse_pos, events),
    }
}

fn updateClosed(self: *Self, mouse_pos: rl.Vector2(f32), events: *std.ArrayList(event.Event)) !void {
    const menu_action: event.Event = if (self.state == .visible) .close_control_pannel else .open_control_pannel;
    self.buttons.items(.action_left_click)[0] = menu_action;
    const i = 0;
    const pos = self.getButtonVector(i);
    const x = pos.x;
    const y = pos.y;
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

fn updateOpen(self: *Self, mouse_pos: rl.Vector2(f32), events: *std.ArrayList(event.Event)) !void {
    const menu_action: event.Event = if (self.state == .visible) .close_control_pannel else .open_control_pannel;
    self.buttons.items(.action_left_click)[0] = menu_action;
    for (0..self.buttons.len) |i| {
        const pos = self.getButtonVector(i);
        const x = pos.x;
        const y = pos.y;
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

    for (0..self.inputs.len) |i| {
        const rect = self.getInputRect(i);
        const is_hovered = rl.checkCollisionPointRec(mouse_pos, rect.as(f32));
        if (is_hovered and rl.isMouseButtonPressed(.mouse_button_left)) {
            const action = self.inputs.items(.action_left_click)[i];
            try events.append(action);
            self.inputs.items(.hovered)[i] = false;
        }
        self.inputs.items(.hovered)[i] = is_hovered;
    }
}

fn getButtonVector(self: *const Self, idx: usize) rl.Vector2(i32) {
    const texture = self.buttons.items(.texture)[idx];
    const w: i32 = @intCast(texture.width);
    const h: i32 = @intCast(texture.height);
    const x: i32 = @intCast(@mod(idx, Self.WIDTH));
    const y: i32 = @intCast(@divFloor(idx, Self.WIDTH));
    return .{
        .x = x * (w + Self.PADDING) + Self.OFFSET,
        .y = y * (h + Self.PADDING) + Self.OFFSET,
    };
}

fn getInputRect(self: *const Self, idx: usize) rl.Rectangle(i32) {
    const last_button_pos = self.getButtonVector(self.buttons.len - 1);
    const w: i32 = DEFAULT_CELL_WIDTH * WIDTH;
    const h: i32 = DEFAULT_CELL_WIDTH;
    const x: i32 = OFFSET;
    const y: i32 = rl.cast(i32, idx) * (h + PADDING) + (last_button_pos.y + h) + PADDING;

    return rl.Rectangle(i32).init(x, y, w, h);
}

fn getCellWidth(self: *const Self) i32 {
    const textures = self.buttons.items(.texture);
    if (textures.len == 0) return Self.DEFAULT_CELL_WIDTH + Self.PADDING;
    return textures[0].width + Self.PADDING;
}

fn drawHelpText(self: *const Self, help_text_id: ?usize) void {
    const i = help_text_id orelse return;
    var pos = self.getButtonVector(i);
    pos.x += 32;
    widget.drawHelpText(pos, self.buttons.items(.name)[i]);
}

fn drawClosed(self: *const Self) void {
    const texture = self.buttons.items(.texture)[0];
    const pos = self.getButtonVector(0);
    const x = pos.x;
    const y = pos.y;
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
        const pos = self.getButtonVector(i);
        const x = pos.x;
        const y = pos.y;
        const color = if (self.buttons.items(.hovered)[i]) self.buttons.items(.hover_color)[i] else rl.Color.white;
        const is_hovered = self.buttons.items(.hovered)[i];
        rl.drawTexture(self.buttons.items(.texture)[i], x, y, color);
        if (is_hovered) help_text_id = i;
    }
    self.drawHelpText(help_text_id);
    self.drawInputs();
}

fn drawInputs(self: *const Self) void {
    var help_text_id: ?usize = null;
    for (0..self.inputs.len) |i| {
        const color = if (self.inputs.items(.hovered)[i]) self.inputs.items(.hover_color)[i] else rl.Color.white;
        const rect = self.getInputRect(i);
        rl.drawRectangleRec(rect.as(f32), color);
        rl.drawText(&self.inputs.items(.contents)[i], rect.x + 2, rect.y, 15, rl.Color.black);
        if (self.inputs.items(.hovered)[i]) help_text_id = i;
    }

    if (help_text_id) |i| {
        var pos = self.getInputRect(i).getPos();
        pos.y += 32;
        widget.drawHelpText(pos, self.inputs.items(.name)[i]);
    }
}

pub fn draw(self: *const Self) void {
    switch (self.state) {
        .visible => self.drawOpen(),
        .hidden => self.drawClosed(),
    }
}
