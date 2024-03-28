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
    var text_buffer = try allocator.alloc(u8, 1024);
    defer allocator.free(text_buffer);
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

        if (key_queue.items.len > 0 and is_dirty) {
            const length = keyboard.to_string(&key_queue, &text_buffer);
            if (keymap.get("text", "normal", text_buffer[0..length])) |cmd| {
                cmd.action(&context);
                key_queue.clearRetainingCapacity();
            }
            is_dirty = false;
        }

        rl.BeginDrawing();
        rl.ClearBackground(rl.Color.darkGray());
        defer rl.EndDrawing();
        draw_cursor(context.cursor);
    }
}

pub fn draw_cursor(cursor: *Cursor) void {
    rl.DrawRectangleV(cursor.get_pos(), cursor.size, rl.Color.rayWhite());
}

// test "to_string" {
//     var keys = std.ArrayList(rl.KeyboardKey).init(std.testing.allocator);
//     defer keys.deinit();
//     try keys.append(rl.KeyboardKey.LEFT_CONTROL);
//     try keys.append(rl.KeyboardKey.C);
//
//     var out = try std.testing.allocator.alloc(u8, 10);
//     defer std.testing.allocator.free(out);
//
//     try keyboard.to_string(&keys, &out);
//     const found: []const u8 = out[0..9];
//     print("'{s}'\n", .{found});
//     try std.testing.expectEqualStrings("<ctrlL-c>", found);
// }
