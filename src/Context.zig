const std = @import("std");
const Allocator = std.mem.Allocator;
const Cursor = @import("Cursor.zig");
const modes = @import("mode.zig");
const Canvas = @import("Canvas.zig");
const CommandBar = @import("CommandBar.zig");
const rl = @import("raylib_zig");
const keyboard = @import("keyboard.zig");

const Self = @This();
const BUFFER_SIZE = 256;

alloc: Allocator,
cursor: *Cursor,
canvas: *Canvas,
commandBar: *CommandBar,
scratch_buffer: []u8,
scratch_index: usize = 0,
key_queue: std.ArrayList(rl.KeyboardKey),
mode: modes.Mode = .Normal,
is_running: bool = true,

pub fn init(alloc: Allocator, width: u32, height: u32) !Self {
    const cursor = try alloc.create(Cursor);
    errdefer alloc.destroy(cursor);
    cursor.* = Cursor.init();

    const canvas = try alloc.create(Canvas);
    errdefer alloc.destroy(canvas);
    canvas.* = try Canvas.init(alloc, width, height);

    const commandBar = try alloc.create(CommandBar);
    errdefer alloc.destroy(commandBar);
    commandBar.* = try CommandBar.init(alloc);

    const buffer = try alloc.alloc(u8, BUFFER_SIZE);
    errdefer alloc.free(buffer);
    @memset(buffer, 0);

    return .{
        .alloc = alloc,
        .cursor = cursor,
        .canvas = canvas,
        .commandBar = commandBar,
        .scratch_buffer = buffer,
        .key_queue = std.ArrayList(rl.KeyboardKey).init(alloc),
    };
}

pub fn deinit(self: Self) void {
    self.alloc.destroy(self.cursor);
    self.canvas.*.deinit();
    self.alloc.destroy(self.canvas);
    self.commandBar.*.deinit();
    self.alloc.destroy(self.commandBar);
    self.alloc.free(self.scratch_buffer);
    self.key_queue.deinit();
}

pub fn getCurrentKeyPressedString(self: *Self) ![]const u8 {
    const key = self.getCurrentKeyPressed().*;
    return try keyboard.get_string_value_of_key(key, self.scratch_buffer);
}

pub fn getCurrentKeyPressed(self: *Self) *rl.KeyboardKey {
    return &self.key_queue.items[self.key_queue.items.len - 1];
}
