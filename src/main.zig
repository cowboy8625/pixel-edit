const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const rl = @import("raylib_zig");
const cast = rl.utils.cast;
const modes = @import("mode.zig");
const keyboard = @import("keyboard.zig");
const keymapper = @import("keymapper.zig");
const KeyMapper = keymapper.KeyMapper;
const Command = @import("Command.zig");
const Context = @import("Context.zig");
const Cursor = @import("Cursor.zig");

// Drawing imports
const drawing = @import("drawing/status_bar.zig");

test {
    _ = @import("keymapper.zig");
    _ = @import("keyboard.zig");
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const screen_width = 800;
    const screen_height = 600;
    rl.InitWindow(screen_width, screen_height, "raylib zig template");
    defer rl.CloseWindow();

    const major_mode = modes.MajorMode.Text;
    const state = modes.State.Normal;
    var key_queue = std.ArrayList(rl.KeyboardKey).init(allocator);
    defer key_queue.deinit();
    var context = try Context.init(allocator);
    defer context.deinit();
    // var text_buffer = try allocator.alloc(u8, 1024);
    // defer allocator.free(text_buffer);
    var keymap = try KeyMapper.init(allocator);
    defer keymap.deinit();

    rl.SetTargetFPS(60);
    var is_dirty = false;

    print("{}: {}\n", .{ major_mode, state });
    while (!rl.WindowShouldClose()) {
        var keypress = rl.GetKeyPressed();
        while (keypress) |key| {
            try key_queue.append(key);
            is_dirty = true;
            keypress = rl.GetKeyPressed();
        }

        if (keymap.is_possible_combination(
            "text",
            "normal",
            key_queue.items,
        )) {
            // const length = keyboard.to_string(&key_queue, &text_buffer);
            if (keymap.get("text", "normal", key_queue.items)) |cmd| {
                cmd.action(&context);
                key_queue.clearRetainingCapacity();
            }
        } else {
            key_queue.clearRetainingCapacity();
        }

        rl.BeginDrawing();
        rl.ClearBackground(rl.Color.darkGray());
        defer rl.EndDrawing();
        draw_cursor(context.cursor);
        drawing.draw_status_bar();
    }
}

pub fn draw_cursor(cursor: *Cursor) void {
    rl.DrawRectangleV(cursor.get_pos(), cursor.size, rl.Color.rayWhite());
}
