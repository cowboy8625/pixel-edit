const std = @import("std");
const rl = @import("rl/mod.zig");
const widget = @import("widget.zig");
const Asset = @import("assets.zig");
const event = @import("event.zig");
const main = @import("main.zig");
const Button = widget.Button(event.Event);

const Self = @This();
const WIDTH: i32 = 7;
const OFFSET: i32 = 10;
const PADDING: i32 = 5;
const DEFAULT_CELL_WIDTH: i32 = 16;

pub const State = enum {
    hidden,
    visible,
};

buttons: std.MultiArrayList(Button),
inputs: std.MultiArrayList(widget.Input),
allocator: std.mem.Allocator,
state: State = .visible,

pub fn init(allocator: std.mem.Allocator, canvas_size: rl.Vector2(i32)) !Self {
    var self = Self{
        .buttons = std.MultiArrayList(Button){},
        .inputs = std.MultiArrayList(widget.Input){},
        .allocator = allocator,
    };
    try self.initButtons();
    try self.initInputs(canvas_size);

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

pub fn getWidth(comptime T: type) T {
    const result: T = OFFSET * 2 + PADDING * 2 + WIDTH * DEFAULT_CELL_WIDTH + 15;
    return result;
}

pub fn add_button(
    self: *Self,
    name: []const u8,
    action_left_click: Button.Action,
    default_event: event.Event,
    texture: rl.Texture2D,
) !void {
    try self.buttons.append(self.allocator, .{
        .name = name,
        .event = default_event,
        .action_left_click = action_left_click,
        .hover_color = rl.Color.fromInt(0x343028FF),
        .texture = texture,
    });
}

pub fn add_input(self: *Self, name: []const u8, action: event.Event, default_value: i32) !void {
    var contents = [_]u8{0} ** widget.Input.MAX_LEN;

    const b = try std.fmt.bufPrint(&contents, "{d}", .{default_value});
    const cursor = b.len;

    try self.inputs.append(self.allocator, .{
        .name = name,
        .action_left_click = action,
        .hover_color = rl.Color.fromInt(0x343028FF),
        .contents = contents,
        .cursor = cursor,
    });
}

pub fn updateInput(self: *Self, input_kind: event.WidgetEvent, state: *main.State, events: *std.ArrayList(event.Event)) !void {
    const idx: usize = switch (input_kind) {
        .frame_speed_input => 0,
        .width_input => 1,
        .height_input => 2,
    };
    if (rl.isKeyPressed(.key_enter)) {
        const contents = self.inputs.items(.contents)[idx];
        const cursor = self.inputs.items(.cursor)[idx];
        switch (idx) {
            0 => try events.append(.{ .set_frame_speed = std.fmt.parseFloat(f32, contents[0..cursor]) catch |e| {
                std.log.err("parse error: {s} {s}\n", .{ contents, @errorName(e) });
                return;
            } }),
            1 => try events.append(.{ .set_canvas_width = std.fmt.parseInt(i32, contents[0..cursor], 10) catch |e| {
                std.log.err("parse error: {s} {s}\n", .{ contents, @errorName(e) });
                return;
            } }),
            2 => try events.append(.{ .set_canvas_height = std.fmt.parseInt(i32, contents[0..cursor], 10) catch |e| {
                std.log.err("parse error: {s} {s}\n", .{ contents, @errorName(e) });
                return;
            } }),
            else => unreachable,
        }
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
    if ((c < 48 or c > 57) and c != 46) return;
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
    const i = 0;
    const pos = self.getButtonVector(i);
    var button = self.buttons.get(i);
    const rect = rl.Rectangle(i32).from2vec2(
        pos,
        .{
            .x = button.texture.width,
            .y = button.texture.height,
        },
    );
    const is_hovered = rl.checkCollisionPointRec(mouse_pos, rect.as(f32));
    if (is_hovered and rl.isMouseButtonPressed(.mouse_button_left)) {
        const current_event = button.event;
        const new_event = button.action_left_click(&button);
        button.event = new_event;
        try events.append(current_event);
        self.buttons.items(.hovered)[i] = false;
    }
    button.hovered = is_hovered;
    self.buttons.set(i, button);
}

fn updateOpen(self: *Self, mouse_pos: rl.Vector2(f32), events: *std.ArrayList(event.Event)) !void {
    for (0..self.buttons.len) |i| {
        const pos = self.getButtonVector(i);
        var button = self.buttons.get(i);
        const rect = rl.Rectangle(i32).from2vec2(
            pos,
            .{
                .x = button.texture.width,
                .y = button.texture.height,
            },
        );
        const is_hovered = rl.checkCollisionPointRec(mouse_pos, rect.as(f32));
        if (is_hovered and rl.isMouseButtonPressed(.mouse_button_left)) {
            const current_event = button.event;
            const new_event = button.action_left_click(&button);
            button.event = new_event;
            try events.append(current_event);
            self.buttons.items(.hovered)[i] = false;
        }
        button.hovered = is_hovered;
        self.buttons.set(i, button);
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

fn initButtons(self: *Self) !void {
    try self.add_button("menu open and close", struct {
        fn f(w: *Button) event.Event {
            const new_event: event.Event = if (w.event == event.Event.close_control_pannel) .open_control_pannel else .close_control_pannel;
            return new_event;
        }
    }.f, .close_control_pannel, Asset.loadTexture(Asset.MENU_ICON));
    try self.add_button("load image", struct {
        fn f(w: *Button) event.Event {
            return w.event;
        }
    }.f, .open_load_file_browser, Asset.loadTexture(Asset.LOAD_ICON));
    try self.add_button("save image", struct {
        fn f(w: *Button) event.Event {
            return w.event;
        }
    }.f, .open_save_file_browser, Asset.loadTexture(Asset.SAVE_ICON));
    try self.add_button("pencil tool", struct {
        fn f(w: *Button) event.Event {
            return w.event;
        }
    }.f, .draw, Asset.loadTexture(Asset.PENCIL_TOOL_ICON));
    try self.add_button("eraser tool", struct {
        fn f(w: *Button) event.Event {
            return w.event;
        }
    }.f, .erase, Asset.loadTexture(Asset.ERASER_TOOL_ICON));
    try self.add_button("bucket tool", struct {
        fn f(w: *Button) event.Event {
            return w.event;
        }
    }.f, .bucket, Asset.loadTexture(Asset.BUCKET_TOOL_ICON));
    try self.add_button("grid", struct {
        fn f(w: *Button) event.Event {
            return w.event;
        }
    }.f, .display_canvas_grid, Asset.loadTexture(Asset.GRID_ICON));
    try self.add_button("color picker", struct {
        fn f(w: *Button) event.Event {
            return w.event;
        }
    }.f, .color_picker, Asset.loadTexture(Asset.COLOR_PICKER_ICON));
    try self.add_button("color wheel", struct {
        fn f(w: *Button) event.Event {
            const new_event: event.Event = if (w.event == event.Event.close_color_wheel) .open_color_wheel else .close_color_wheel;
            return new_event;
        }
    }.f, .open_color_wheel, Asset.loadTexture(Asset.COLOR_WHEEL_ICON));
    try self.add_button("rotate left", struct {
        fn f(e: *Button) event.Event {
            return e.event;
        }
    }.f, .rotate_left, Asset.loadTexture(Asset.ROTATE_LEFT_ICON));
    try self.add_button("rotate right", struct {
        fn f(e: *Button) event.Event {
            return e.event;
        }
    }.f, .rotate_right, Asset.loadTexture(Asset.ROTATE_RIGHT_ICON));
    try self.add_button("previous frame", struct {
        fn f(w: *Button) event.Event {
            return w.event;
        }
    }.f, .previous_frame, Asset.loadTexture(Asset.LEFT_ARROW_ICON));
    try self.add_button("play animation", struct {
        fn f(w: *Button) event.Event {
            const new_event: event.Event = if (w.event == event.Event.stop_animation) .play_animation else .stop_animation;
            w.texture = if (w.event == event.Event.stop_animation) Asset.loadTexture(Asset.PLAY_ICON) else Asset.loadTexture(Asset.STOP_ICON);
            return new_event;
        }
    }.f, .play_animation, Asset.loadTexture(Asset.PLAY_ICON));
    try self.add_button("next frame", struct {
        fn f(w: *Button) event.Event {
            return w.event;
        }
    }.f, .next_frame, Asset.loadTexture(Asset.RIGHT_ARROW_ICON));
    try self.add_button("draw line tool", struct {
        fn f(w: *Button) event.Event {
            return w.event;
        }
    }.f, .draw_line, Asset.loadTexture(Asset.LINE_TOOL_ICON));
    try self.add_button("flip vertical", struct {
        fn f(w: *Button) event.Event {
            return w.event;
        }
    }.f, .flip_vertical, Asset.loadTexture(Asset.FLIP_VERTICAL_ICON));
    try self.add_button("flip horizontal", struct {
        fn f(w: *Button) event.Event {
            return w.event;
        }
    }.f, .flip_horizontal, Asset.loadTexture(Asset.FLIP_HORIZONTAL_ICON));
    try self.add_button("frames tool", struct {
        fn f(w: *Button) event.Event {
            return w.event;
        }
    }.f, .frame_tool, Asset.loadTexture(Asset.FRAMES_ICON));
    try self.add_button("selection tool", struct {
        fn f(w: *Button) event.Event {
            return w.event;
        }
    }.f, .selection_tool, Asset.loadTexture(Asset.SELECTION_ICON));
    try self.add_button("delete current frame", struct {
        fn f(w: *Button) event.Event {
            return w.event;
        }
    }.f, .delete_frame, Asset.loadTexture(Asset.DELETE_ICON));
    try self.add_button("create new frame", struct {
        fn f(w: *Button) event.Event {
            return w.event;
        }
    }.f, .new_frame, Asset.loadTexture(Asset.PLUS_ICON));
}

fn initInputs(self: *Self, canvas_size: rl.Vector2(i32)) !void {
    try self.add_input("Frame Speed", .{ .clicked = .frame_speed_input }, canvas_size.y + 1);
    try self.add_input("Width", .{ .clicked = .width_input }, canvas_size.x + 1);
    try self.add_input("Height", .{ .clicked = .height_input }, canvas_size.y + 1);
}

// fn numberStringLen(value: i32) usize {
//     if (@abs(value) == 0) {
//         return 1;
//     }
//     var len: usize = std.math.log10(@abs(value)) + 1;
//     if (value < 0) {
//         len += 1;
//     }
//     return len;
// }
