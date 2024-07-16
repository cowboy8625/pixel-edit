const std = @import("std");
// const ziglua = @import("ziglua");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const rl = @import("raylib");
const cast = rl.utils.cast;
const keyboard = @import("keyboard.zig");
const keymapper = @import("keymapper.zig");
const KeyMapper = keymapper.KeyMapper;
const Command = @import("Command.zig");
const Context = @import("Context.zig");
const Cursor = @import("Cursor.zig");
const CommandBar = @import("CommandBar.zig");

test {
    _ = @import("raylib_zig");
    _ = @import("keymapper.zig");
    _ = @import("keyboard.zig");
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const screen_width = 800;
    const screen_height = 600;
    rl.InitWindow(screen_width, screen_height, "Pixel Edit");
    defer rl.CloseWindow();
    rl.SetExitKey(rl.KeyboardKey.NULL);

    var context = try Context.init(allocator, screen_width, screen_height);
    defer context.deinit();
    var keymap = try KeyMapper.init(allocator);
    defer keymap.deinit();

    rl.SetTargetFPS(60);

    while (!rl.WindowShouldClose() and context.is_running) {
        var keypress = rl.GetKeyPressed();
        if (keypress != .NULL) {
            try context.key_queue.append(keypress);
            keypress = rl.GetKeyPressed();
        }

        if (keymap.is_possible_combination(
            context.mode,
            context.key_queue.items,
        )) {
            // const length = keyboard.to_string(&key_queue, &text_buffer);
            if (keymap.get(context.mode, context.key_queue.items)) |cmd| {
                try cmd.action(&context);
            }
        }
        context.key_queue.clearRetainingCapacity();
        context.camera.*.target = context.cursor.get_pos().asRaylibVector2();

        rl.BeginDrawing();
        rl.ClearBackground(rl.Color.darkGray());
        defer rl.EndDrawing();
        rl.BeginMode2D(context.camera.*);
        defer rl.EndMode2D();

        context.canvas.draw(&context);
        context.cursor.draw(&context);
        switch (context.mode) {
            .Command => {
                context.commandBar.draw(&context);
            },
            else => {},
        }
        try context.statusBar.*.draw(&context);
    }
}
