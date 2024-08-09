const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const utils = @import("utils.zig");
const cast = utils.cast;

const StaticString = @import("StaticString.zig").StaticString;
const Button = @import("Button.zig").Button;
const TextInput = @import("TextInput.zig");
const Canvas = @import("Canvas.zig");
const Context = @import("Context.zig");
const ActionCallback = (*const fn (*Self, *Context) void);

const Self = @This();

action_button: Button(*bool),
cancel_button: Button(*bool),
action: ActionCallback,
text_input: TextInput,
rect: rl.Rectangle,
close_with_picked_file: bool = false,
is_open: bool = false,

pub fn init(action_name: []const u8, action: ActionCallback) Self {
    const rect: rl.Rectangle = .{
        .x = 100,
        .y = 100,
        .width = 400,
        .height = 400,
    };
    var action_button = Button(*bool).initWithText(
        action_name,
        .{
            .x = rect.x + rect.width - 75,
            .y = rect.y + rect.height - 25,
        },
        struct {
            fn callback(arg: *bool) void {
                arg.* = !arg.*;
            }
        }.callback,
    );
    action_button.setTextColor(rl.Color.black);
    var cancel_button = Button(*bool).initWithText(
        "Cancel",
        .{
            .x = rect.x + rect.width - 75 * 2,
            .y = rect.y + rect.height - 25,
        },
        struct {
            fn callback(arg: *bool) void {
                arg.* = !arg.*;
            }
        }.callback,
    );
    cancel_button.setTextColor(rl.Color.black);

    const text_input = TextInput.init(rect.x + 10, rect.y + rect.height - 30, 200, 20);
    var path = StaticString(1024).init();
    path.push('.');
    path.push('/');

    return .{
        .action_button = action_button,
        .cancel_button = cancel_button,
        .action = action,
        .text_input = text_input,
        .rect = rect,
    };
}

pub fn deinit(_: *Self) void {}

pub fn update(self: *Self, mouse_pos: rl.Vector2, context: *Context) !bool {
    var active = false;
    if (!self.is_open) {
        self.text_input.clear();
        return active;
    }
    if (rl.checkCollisionPointRec(mouse_pos, self.rect)) {
        active = true;
    }

    _ = self.action_button.update(mouse_pos, &self.close_with_picked_file);
    _ = self.cancel_button.update(mouse_pos, &self.is_open);
    _ = self.text_input.update(mouse_pos);
    if (!self.close_with_picked_file) return active;
    self.action(self, context);
    return active;
}

fn drawNames(self: *Self) !void {
    var cwd = std.fs.cwd();
    if (self.text_input.text.string().len == 0) {
        self.text_input.pushChar('.');
    }
    const state = try std.fs.cwd().statFile(self.text_input.text.string());
    const path = switch (state.kind) {
        .file => blk: {
            // FIXME: This can fail if there isn't a '/' in the path
            const index = self.text_input.text.findIndexRev('/');
            break :blk self.text_input.text.string()[0..(index.? + 1)];
        },
        .directory => self.text_input.text.string(),
        else => unreachable,
    };
    var dir = try cwd.openDir(path, .{ .iterate = true });
    defer dir.close();

    var iter = dir.iterate();
    var i: usize = 0;
    var rect: rl.Rectangle = .{
        .x = 125,
        .y = 100,
        .width = 200,
        .height = 20,
    };
    while (try iter.next()) |entry| {
        switch (entry.kind) {
            .file => if (endsWithOneOf(entry.name, &.{ ".png", ".jpg" })) {
                try self.drawName(&rect, i, entry, state.kind);
                i += 1;
            },
            .directory => {
                try self.drawName(&rect, i, entry, state.kind);
                i += 1;
            },
            else => {},
        }
    }
}

fn endsWithOneOf(name: []const u8, list: []const []const u8) bool {
    for (list) |item| {
        if (std.mem.endsWith(u8, name, item)) {
            return true;
        }
    }
    return false;
}

fn drawName(self: *Self, rect: *rl.Rectangle, i: usize, entry: std.fs.Dir.Entry, current_state: std.fs.File.Kind) !void {
    const text: [*:0]const u8 = @ptrCast(entry.name);
    rect.y = 100 + (20 * cast(f32, i) + 5);
    if (cast(bool, rg.guiLabelButton(rect.*, text)) and entry.kind == .directory and current_state == .directory) {
        if (self.text_input.text.last() != '/') {
            self.text_input.pushChar('/');
        }
        for (entry.name) |c| {
            self.text_input.pushChar(c);
        }
    } else if (cast(bool, rg.guiLabelButton(rect.*, text)) and entry.kind == .file and current_state == .directory) {
        if (self.text_input.text.last() != '/') {
            self.text_input.pushChar('/');
        }
        for (entry.name) |c| {
            self.text_input.pushChar(c);
        }
    } else if (cast(bool, rg.guiLabelButton(rect.*, text)) and entry.kind == .file and current_state == .file) {
        const index = self.text_input.text.findIndexRev('/');
        if (index) |idx| {
            self.text_input.chopAt(idx + 1);
            for (entry.name) |c| {
                self.text_input.pushChar(c);
            }
        }
    }
    const icon: rg.GuiIconName = if (entry.kind == .directory) .icon_folder else .icon_file;
    rg.guiDrawIcon(
        @intFromEnum(icon),
        cast(i32, rect.x) - 20,
        cast(i32, rect.y),
        1,
        rl.Color.black,
    );
}

pub fn draw(self: *Self) !void {
    if (!self.is_open) return;
    rl.drawRectangleRounded(self.rect, 0.05, 10, rl.Color.ray_white);
    rl.drawRectangleRoundedLines(self.rect, 0.05, 10, rl.Color.black);
    try self.drawNames();
    self.cancel_button.draw();
    self.action_button.draw();
    self.text_input.draw();
}
