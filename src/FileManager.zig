const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const utils = @import("utils.zig");
const cast = utils.cast;

const Button = @import("Button.zig").Button;
const TextInput = @import("TextInput.zig");
const Canvas = @import("Canvas.zig");

const Self = @This();

save_button: Button(*bool),
cancel_button: Button(*bool),
close_with_picked_file: bool = false,
is_open: bool = false,
picked_file: [1024]u8 = [_]u8{0} ** 1024,
picked_file_length: usize = 0,
rect: rl.Rectangle,
text_input: TextInput,

pub fn init() Self {
    const rect: rl.Rectangle = .{
        .x = 100,
        .y = 100,
        .width = 400,
        .height = 400,
    };
    var save_button = Button(*bool).initWithText(
        "Save",
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
    save_button.setTextColor(rl.Color.black);
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

    return .{
        .text_input = text_input,
        .save_button = save_button,
        .cancel_button = cancel_button,
        .rect = rect,
    };
}

pub fn deinit(_: *Self) void {}

pub fn save(self: *Self, canvas: *Canvas) void {
    if (!self.close_with_picked_file) return;
    self.close_with_picked_file = false;
    self.is_open = false;
    const path: []const u8 = self.text_input.text.chars[0..self.text_input.text.len];
    canvas.save(path);
}

pub fn update(self: *Self, mouse_pos: rl.Vector2) !bool {
    var active = false;
    if (!self.is_open) return active;
    if (rl.checkCollisionPointRec(mouse_pos, self.rect)) {
        active = true;
    }

    _ = self.save_button.update(mouse_pos, &self.close_with_picked_file);
    _ = self.cancel_button.update(mouse_pos, &self.is_open);
    _ = self.text_input.update(mouse_pos);
    return active;
}

fn drawNames(self: *Self) !void {
    var cwd = std.fs.cwd();
    var dir = try cwd.openDir("./", .{ .iterate = true });
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
            .file, .directory => {
                const text: [*:0]const u8 = @ptrCast(entry.name);
                rect.y = 100 + (20 * cast(f32, i) + 5);
                if (cast(bool, rg.guiLabelButton(rect, text))) {
                    self.picked_file_length = 0;
                    for (entry.name) |c| {
                        self.picked_file[self.picked_file_length] = c;
                        self.picked_file_length += 1;
                    }
                    self.picked_file[self.picked_file_length] = 0;
                }
                const icon: rg.GuiIconName = if (entry.kind == .directory) .icon_folder else .icon_file;
                rg.guiDrawIcon(
                    @intFromEnum(icon),
                    cast(i32, rect.x) - 20,
                    cast(i32, rect.y),
                    1,
                    rl.Color.black,
                );
                i += 1;
            },
            else => {},
        }
    }
}

pub fn draw(self: *Self) !void {
    if (!self.is_open) return;
    rl.drawRectangleRounded(self.rect, 0.05, 10, rl.Color.ray_white);
    rl.drawRectangleRoundedLines(self.rect, 0.05, 10, rl.Color.black);
    try self.drawNames();
    self.cancel_button.draw();
    self.save_button.draw();
    self.text_input.draw();
}
