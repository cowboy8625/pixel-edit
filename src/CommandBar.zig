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
    if (std.mem.eql(u8, self.text[0..self.index], "exit")) {
        ctx.is_running = false;
    } else if (std.mem.eql(u8, self.text[0..self.index], "clear")) {
        ctx.canvas.clear();
        try commands.change_mode_to_normal(ctx);
    } else {
        self.message = try std.fmt.bufPrintZ(
            self.error_buf,
            "Error: `{s}` is not a valid command",
            .{
                self.text[0..self.index],
            },
        );
    }
}

pub fn draw(self: *Self, _: *Context) void {
    const screen_width = rl.GetScreenWidth();
    const screen_height = rl.GetScreenHeight();
    const width = cast(f32, screen_width) * 0.9;
    const height = 40;
    var pos: rl.Vector2(f32) = .{
        .x = (cast(f32, screen_width) - width) / 2.0,
        .y = cast(f32, @divFloor((screen_height - height), 2)),
    };
    const font_size = 35;

    const size: rl.Vector2(f32) = .{ .x = width, .y = height };
    rl.DrawRectangleV(pos, size, rl.Color.black());

    pos = pos.add(4);

    if (self.message) |message| {
        rl.DrawText(
            message,
            pos.as(i32).x,
            pos.as(i32).y,
            font_size,
            rl.Color.red(),
        );
        return;
    }

    if (self.index == 0) return;
    rl.DrawText(
        self.text[0..self.index],
        pos.as(i32).x,
        pos.as(i32).y,
        font_size,
        rl.Color.white(),
    );
}
