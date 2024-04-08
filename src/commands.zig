const Context = @import("Context.zig");

pub fn cursor_up(ctx: *Context) void {
    ctx.cursor.cursor_up();
}

pub fn cursor_down(ctx: *Context) void {
    ctx.cursor.cursor_down();
}

pub fn cursor_left(ctx: *Context) void {
    ctx.cursor.cursor_left();
}

pub fn cursor_right(ctx: *Context) void {
    ctx.cursor.cursor_right();
}

pub fn change_mode_to_normal(ctx: *Context) void {
    ctx.mode = .Normal;
}

pub fn change_mode_to_command(ctx: *Context) void {
    ctx.mode = .Command;
}
