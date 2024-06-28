const std = @import("std");
const rl = @import("raylib_zig");
const cast = rl.utils.cast;
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

pub fn draw_cursor_up(ctx: *Context) void {
    ctx.cursor.cursor_up();
    const x = cast(usize, ctx.cursor.pos.x);
    const y = cast(usize, ctx.cursor.pos.y);
    const color = ctx.cursor.color;
    ctx.canvas.insert(x, y, color) catch {
        std.debug.print("Failed to insert pixel at {d}, {d}\n", .{ x, y });
        return;
    };
}

pub fn draw_cursor_down(ctx: *Context) void {
    ctx.cursor.cursor_down();
    const x = cast(usize, ctx.cursor.pos.x);
    const y = cast(usize, ctx.cursor.pos.y);
    const color = ctx.cursor.color;
    ctx.canvas.insert(x, y, color) catch {
        std.debug.print("Failed to insert pixel at {d}, {d}\n", .{ x, y });
        return;
    };
}

pub fn draw_cursor_left(ctx: *Context) void {
    ctx.cursor.cursor_left();
    const x = cast(usize, ctx.cursor.pos.x);
    const y = cast(usize, ctx.cursor.pos.y);
    const color = ctx.cursor.color;
    ctx.canvas.insert(x, y, color) catch {
        std.debug.print("Failed to insert pixel at {d}, {d}\n", .{ x, y });
        return;
    };
}

pub fn draw_cursor_right(ctx: *Context) void {
    ctx.cursor.cursor_right();
    const x = cast(usize, ctx.cursor.pos.x);
    const y = cast(usize, ctx.cursor.pos.y);
    const color = ctx.cursor.color;
    ctx.canvas.insert(x, y, color) catch {
        std.debug.print("Failed to insert pixel at {d}, {d}\n", .{ x, y });
        return;
    };
}

pub fn change_mode_to_normal(ctx: *Context) void {
    ctx.mode = .Normal;
}

pub fn change_mode_to_command(ctx: *Context) void {
    ctx.mode = .Command;
}

pub fn change_mode_to_insert(ctx: *Context) void {
    ctx.mode = .Insert;
}
