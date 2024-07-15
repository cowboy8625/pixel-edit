const std = @import("std");
const rl = @import("raylib_zig");
const cast = rl.utils.cast;
const Context = @import("Context.zig");

pub fn cursor_up(ctx: *Context) !void {
    const y = ctx.cursor.get_pos().as(u32).y;
    if (y <= 0) return;
    ctx.cursor.cursor_up();
}

pub fn cursor_down(ctx: *Context) !void {
    const y = ctx.cursor.get_pos().as(u32).y;
    const bottom = ctx.canvas.height - cast(u32, ctx.cursor.size.y);
    if (y >= bottom) return;
    ctx.cursor.cursor_down();
}

pub fn cursor_left(ctx: *Context) !void {
    const x = ctx.cursor.get_pos().as(u32).x;
    if (x <= 0) return;
    ctx.cursor.cursor_left();
}

pub fn cursor_right(ctx: *Context) !void {
    const x = ctx.cursor.get_pos().as(u32).x;
    const right = ctx.canvas.width - cast(u32, ctx.cursor.size.x);
    if (x >= right) return;
    ctx.cursor.cursor_right();
}

pub fn draw_cursor_up(ctx: *Context) !void {
    try cursor_up(ctx);
    const color = ctx.cursor.color;
    try ctx.canvas.insert(ctx.cursor.pos.as(usize), color);
}

pub fn draw_cursor_down(ctx: *Context) !void {
    try cursor_down(ctx);
    const color = ctx.cursor.color;
    try ctx.canvas.insert(ctx.cursor.pos.as(usize), color);
}

pub fn draw_cursor_left(ctx: *Context) !void {
    try cursor_left(ctx);
    const color = ctx.cursor.color;
    try ctx.canvas.insert(ctx.cursor.pos.as(usize), color);
}

pub fn draw_cursor_right(ctx: *Context) !void {
    try cursor_right(ctx);
    const color = ctx.cursor.color;
    try ctx.canvas.insert(ctx.cursor.pos.as(usize), color);
}

pub fn change_mode_to_normal(ctx: *Context) !void {
    ctx.mode = .Normal;
}

pub fn change_mode_to_command(ctx: *Context) !void {
    ctx.mode = .Command;
}

pub fn change_mode_to_insert(ctx: *Context) !void {
    ctx.mode = .Insert;
    const color = ctx.cursor.color;
    try ctx.canvas.insert(ctx.cursor.pos.as(usize), color);
}

pub fn insert_char(ctx: *Context) !void {
    if (ctx.mode == .Command) {
        const string = try ctx.getCurrentKeyPressedString();
        const key = ctx.getCurrentKeyPressed();
        switch (key.*) {
            .SPACE => {
                ctx.commandBar.push(' ');
            },
            .BACKSPACE => {
                ctx.commandBar.backspace();
            },
            .ENTER => {
                try ctx.commandBar.execute(ctx);
            },
            else => if (!isControlKey(string)) {
                if (rl.IsKeyDown(rl.KeyboardKey.LEFT_SHIFT) or rl.IsKeyDown(rl.KeyboardKey.RIGHT_SHIFT)) {
                    ctx.commandBar.push(std.ascii.toUpper(string[0]));
                    return;
                }
                ctx.commandBar.push(string[0]);
            },
        }
    }
}

fn isControlKey(string: []const u8) bool {
    return string[0] == '<' and string[string.len - 1] == '>';
}

pub fn delete_pixel_under_cursor(ctx: *Context) !void {
    ctx.canvas.remove(ctx.cursor.pos.as(usize));
}
