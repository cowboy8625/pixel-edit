const std = @import("std");
const Allocator = std.mem.Allocator;
const Cursor = @import("Cursor.zig");
const modes = @import("mode.zig");
const Canvas = @import("Canvas.zig");
const CommandBar = @import("CommandBar.zig");
const StatusBar = @import("StatusBar.zig");
const rl = @import("raylib_zig");
const keyboard = @import("keyboard.zig");
const cast = rl.utils.cast;

const Self = @This();
const BUFFER_SIZE = 256;

alloc: Allocator,
cursor: *Cursor,
canvas: *Canvas,
commandBar: *CommandBar,
statusBar: *StatusBar,
camera: *rl.Camera2D,
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

    const statusBar = try alloc.create(StatusBar);
    errdefer alloc.destroy(statusBar);
    statusBar.* = StatusBar.default();

    const buffer = try alloc.alloc(u8, BUFFER_SIZE);
    errdefer alloc.free(buffer);
    @memset(buffer, 0);

    const camera = try alloc.create(rl.Camera2D);
    errdefer alloc.destroy(camera);
    camera.* = .{
        .offset = .{
            .x = cast(f32, @divFloor(rl.GetScreenWidth(), 2)),
            .y = cast(f32, @divFloor(rl.GetScreenHeight(), 2)),
        },
        .target = .{ .x = 0.0, .y = 0.0 },
        .rotation = 0.0,
        .zoom = 1.0,
    };

    return .{
        .alloc = alloc,
        .cursor = cursor,
        .canvas = canvas,
        .commandBar = commandBar,
        .statusBar = statusBar,
        .camera = camera,
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
    self.alloc.destroy(self.statusBar);
    self.alloc.destroy(self.camera);
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
