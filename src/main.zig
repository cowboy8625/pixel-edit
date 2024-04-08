const std = @import("std");
const ziglua = @import("ziglua");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const rl = @import("raylib_zig");
const cast = rl.utils.cast;
const keyboard = @import("keyboard.zig");
const keymapper = @import("keymapper.zig");
const KeyMapper = keymapper.KeyMapper;
const Command = @import("Command.zig");
const Context = @import("Context.zig");
const Cursor = @import("Cursor.zig");

// Drawing imports
const drawing = @import("drawing/mod.zig");

test {
    _ = @import("raylib_zig");
    _ = @import("keymapper.zig");
    _ = @import("keyboard.zig");
    _ = @import("Window.zig");
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const screen_width = 800;
    const screen_height = 600;
    rl.InitWindow(screen_width, screen_height, "raylib zig template");
    defer rl.CloseWindow();

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

    while (!rl.WindowShouldClose()) {
        // var keypress = rl.GetCharPressed();
        // while (keypress != 0) {
        //     print("{d}\n", .{keypress});
        //     // const c = cast(u8, keypress);
        //     // if (std.ascii.isPrint(c)) {
        //     //     print("{c}\n", .{c});
        //     // } else {
        //     //     print("{d}\n", .{keypress});
        //     // }
        //     keypress = rl.GetCharPressed();
        // }
        var keypress = rl.GetKeyPressed();
        while (keypress) |key| {
            try key_queue.append(key);
            is_dirty = true;
            keypress = rl.GetKeyPressed();
        }

        if (keymap.is_possible_combination(
            context.mode,
            key_queue.items,
        )) {
            // const length = keyboard.to_string(&key_queue, &text_buffer);
            if (keymap.get(context.mode, key_queue.items)) |cmd| {
                cmd.action(&context);
                key_queue.clearRetainingCapacity();
            }
        } else {
            key_queue.clearRetainingCapacity();
        }

        rl.BeginDrawing();
        rl.ClearBackground(rl.Color.darkGray());
        defer rl.EndDrawing();
        try draw(&context, &text_buffer);
    }
}

fn draw(ctx: *Context, text_buffer: *[]u8) !void {
    switch (ctx.mode) {
        .Command => try draw_command_mode(ctx, text_buffer),
        .Normal => try draw_normal_mode(ctx, text_buffer),
        else => {},
    }
    try drawing.draw_status_bar(ctx, text_buffer);
}

fn major_mode_pixel_edit_draw(ctx: *Context, text_buffer: *[]u8) !void {
    _ = text_buffer;
    _ = ctx;
}

pub fn draw_cursor(cursor: *Cursor) void {
    rl.DrawRectangleV(cursor.get_pos(), cursor.size, rl.Color.rayWhite());
}
pub fn draw_command_mode(ctx: *Context, text_buffer: *[]u8) !void {
    drawing.draw_command_bar();
    _ = ctx;
    _ = text_buffer;
}
pub fn draw_normal_mode(ctx: *Context, text_buffer: *[]u8) !void {
    draw_cursor(ctx.cursor);
    _ = text_buffer;
}
