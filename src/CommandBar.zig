const std = @import("std");
const rl = @import("raylib_zig");
const keyboard = @import("keyboard.zig");
const cast = rl.utils.cast;
const commands = @import("commands.zig");
const Context = @import("Context.zig");
const Allocator = std.mem.Allocator;

const Self = @This();

text: []u8,
error_buf: []u8,
message: ?[]u8 = null,
index: usize = 0,
font_size: i32 = 35,
alloc: Allocator,

pub fn init(alloc: Allocator) !Self {
    const text = try alloc.alloc(u8, 256);
    errdefer alloc.free(text);

    const error_buf = try alloc.alloc(u8, 256);
    errdefer alloc.free(error_buf);

    return .{
        .text = text,
        .error_buf = error_buf,
        .alloc = alloc,
    };
}

pub fn deinit(self: *Self) void {
    self.alloc.free(self.text);
    self.alloc.free(self.error_buf);
}

pub fn push(self: *Self, char: u8) void {
    self.text[self.index] = char;
    self.index += 1;
    self.text[self.index] = 0;
}

pub fn backspace(self: *Self) void {
    if (self.index == 0) return;
    self.index -= 1;
    self.text[self.index] = 0;
}

pub fn execute(self: *Self, ctx: *Context) !void {
    if (self.message != null) {
        self.message = null;
        self.index = 0;
        return;
    }
    const command = self.text[0..self.index];
    if (std.mem.startsWith(u8, command, "set")) {
        var it = std.mem.split(u8, command, "=");
        const first = it.next() orelse "";
        if (std.mem.startsWith(u8, first, "set canvas-width")) {
            const maybe_value = it.next() orelse "";
            const value = std.fmt.parseInt(u32, maybe_value, 10) catch {
                self.message = try std.fmt.bufPrintZ(
                    self.error_buf,
                    "`{s}` Error: canvas-width expected a number but found",
                    .{
                        maybe_value,
                    },
                );
                return;
            };
            ctx.canvas.width = value * cast(u32, ctx.cursor.size.x);
            self.clear();
            try commands.change_mode_to_normal(ctx);
        } else if (std.mem.startsWith(u8, command, "set canvas-height=")) {
            const maybe_value = it.next() orelse "";
            const value = std.fmt.parseInt(u32, maybe_value, 10) catch {
                self.message = try std.fmt.bufPrintZ(
                    self.error_buf,
                    "Error: canvas-height expected a number but found `{s}`",
                    .{
                        maybe_value,
                    },
                );
                return;
            };
            ctx.canvas.height = value * cast(u32, ctx.cursor.size.x);
            self.clear();
            try commands.change_mode_to_normal(ctx);
        }
    } else if (std.mem.eql(u8, command, "exit")) {
        ctx.is_running = false;
    } else if (std.mem.eql(u8, command, "clear")) {
        ctx.canvas.clear();
        self.clear();
        try commands.change_mode_to_normal(ctx);
    } else {
        self.message = try std.fmt.bufPrintZ(
            self.error_buf,
            "Error: `{s}` is not a valid command",
            .{
                command,
            },
        );
    }
}

pub fn draw(self: *Self, ctx: *Context) void {
    const screen_width = rl.GetScreenWidth();
    const screen_height = rl.GetScreenHeight();
    const width = cast(f32, screen_width) * 0.9;
    const height = 40;
    var pos: rl.Vector2(f32) = .{
        .x = (cast(f32, screen_width) - width) / 2.0,
        .y = cast(f32, @divFloor((screen_height - height), 2)),
    };
    pos = rl.GetScreenToWorld2D(pos, ctx.camera.*);

    const size: rl.Vector2(f32) = .{ .x = width, .y = height };
    rl.DrawRectangleV(pos, size, rl.Color.black());

    const pos0 = pos.add(4).as(i32);

    if (self.message) |message| {
        rl.DrawText(
            message,
            pos0.x,
            pos0.y,
            self.font_size,
            rl.Color.red(),
        );
        return;
    }
    self.draw_cursor(pos);

    if (self.index == 0) return;
    rl.DrawText(
        self.text[0..self.index],
        pos0.x,
        pos0.y,
        self.font_size,
        rl.Color.white(),
    );
}

fn clear(self: *Self) void {
    self.index = 0;
    self.text[0] = 0;
}

fn draw_cursor(self: *const Self, pos: rl.Vector2(f32)) void {
    var font_width: i32 = undefined;
    if (self.index > 0) {
        font_width = rl.MeasureText(self.text[0..self.index], self.font_size);
    } else {
        font_width = 0;
    }
    const p = pos.add(rl.Vector2(i32).init(font_width + 4, 0).as(f32));

    rl.DrawRectangleV(p, .{ .x = 10, .y = 40 }, rl.Color.red());
}
