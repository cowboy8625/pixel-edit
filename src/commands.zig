const std = @import("std");
const rl = @import("raylib_zig");
const cast = rl.utils.cast;
const Context = @import("Context.zig");

pub fn cursor_up(ctx: *Context) !void {
    ctx.cursor.cursor_up();
}

pub fn cursor_down(ctx: *Context) !void {
    ctx.cursor.cursor_down();
}

pub fn cursor_left(ctx: *Context) !void {
    ctx.cursor.cursor_left();
}

pub fn cursor_right(ctx: *Context) !void {
    ctx.cursor.cursor_right();
}

pub fn draw_cursor_up(ctx: *Context) !void {
    const color = ctx.cursor.color;
    try ctx.canvas.insert(ctx.cursor.pos.as(usize), color);
    ctx.cursor.cursor_up();
}

pub fn draw_cursor_down(ctx: *Context) !void {
    const color = ctx.cursor.color;
    try ctx.canvas.insert(ctx.cursor.pos.as(usize), color);
    ctx.cursor.cursor_down();
}

pub fn draw_cursor_left(ctx: *Context) !void {
    const color = ctx.cursor.color;
    try ctx.canvas.insert(ctx.cursor.pos.as(usize), color);
    ctx.cursor.cursor_left();
}

pub fn draw_cursor_right(ctx: *Context) !void {
    const color = ctx.cursor.color;
    try ctx.canvas.insert(ctx.cursor.pos.as(usize), color);
    ctx.cursor.cursor_right();
}

pub fn change_mode_to_normal(ctx: *Context) !void {
    ctx.mode = .Normal;
}

pub fn change_mode_to_command(ctx: *Context) !void {
    ctx.mode = .Command;
}

pub fn change_mode_to_insert(ctx: *Context) !void {
    ctx.mode = .Insert;
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
            else => {
                ctx.commandBar.push(string[0]);
            },
        }
    }
}
