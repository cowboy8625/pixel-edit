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
