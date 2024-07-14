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
const CommandBar = @import("CommandBar.zig");

// Drawing imports
const drawing = @import("drawing/mod.zig");

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
    rl.InitWindow(screen_width, screen_height, "raylib zig template");
    defer rl.CloseWindow();
    rl.SetExitKey(rl.KeyboardKey.NULL);

    var context = try Context.init(allocator, screen_width, screen_height);
    defer context.deinit();
    var keymap = try KeyMapper.init(allocator);
    defer keymap.deinit();

    rl.SetTargetFPS(60);

    while (!rl.WindowShouldClose() and context.is_running) {
        var keypress = rl.GetKeyPressed();
        while (keypress) |key| {
            try context.key_queue.append(key);
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

        rl.BeginDrawing();
        rl.ClearBackground(rl.Color.darkGray());
        defer rl.EndDrawing();

        drawing.draw_canvas(&context);
        switch (context.mode) {
            .Command => {
                context.commandBar.draw(&context);
            },
            .Normal => try draw_normal_mode(&context),
            .Insert => try draw_insert_mode(&context),
            else => {},
        }
        try drawing.draw_status_bar(&context);
    }
}

fn draw(ctx: *Context, text_buffer: *[]u8) !void {
    drawing.draw_canvas(ctx);
    switch (ctx.mode) {
        .Command => try draw_command_mode(ctx, text_buffer),
        .Normal => try draw_normal_mode(ctx, text_buffer),
        .Insert => try draw_insert_mode(ctx, text_buffer),
        else => {},
    }
    try drawing.draw_status_bar(ctx, text_buffer);
}

fn major_mode_pixel_edit_draw(ctx: *Context, text_buffer: *[]u8) !void {
    _ = text_buffer;
    _ = ctx;
}

pub fn draw_cursor(cursor: *Cursor) void {
    rl.DrawRectangleV(cursor.get_pos(), cursor.size, cursor.color);
}
pub fn draw_command_mode(ctx: *Context, text_buffer: *[]u8) !void {
    drawing.draw_command_bar();
    _ = ctx;
    _ = text_buffer;
}
pub fn draw_normal_mode(ctx: *Context) !void {
    draw_cursor(ctx.cursor);
}

pub fn draw_insert_mode(ctx: *Context) !void {
    draw_cursor(ctx.cursor);
}
