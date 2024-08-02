const std = @import("std");
const Allocator = std.mem.Allocator;
const rl = @import("raylib");
const utils = @import("utils.zig");
const cast = utils.cast;

const Pixels = std.AutoHashMap(Point, rl.Color);
const Point = struct {
    x: usize,
    y: usize,
};

const Self = @This();
alloc: Allocator,
pixels: Pixels,
rect: rl.Rectangle,
cell_size: rl.Vector2,
background_color: rl.Color = rl.Color.ray_white,

/// width and height are in pixels/cells
pub fn init(alloc: Allocator, rect: rl.Rectangle, cell_size: rl.Vector2) !Self {
    var pixels = Pixels.init(alloc);
    errdefer pixels.deinit();

    return .{
        .alloc = alloc,
        .pixels = pixels,
        .rect = .{
            .x = rect.x,
            .y = rect.y,
            .width = rect.width * cell_size.x,
            .height = rect.height * cell_size.y,
        },
        .cell_size = cell_size,
    };
}

pub fn deinit(self: *Self) void {
    self.pixels.deinit();
}

pub fn clear(self: *Self) void {
    self.pixels.clearRetainingCapacity();
}

pub fn insert(self: *Self, pos: anytype, color: rl.Color) !void {
    const p = convertToPoint(pos);
    try self.pixels.put(p, color);
}

pub fn remove(self: *Self, pos: anytype) void {
    const p = convertToPoint(pos);
    _ = self.pixels.remove(p);
}

pub fn get(self: *const Self, pos: anytype) ?rl.Color {
    switch (@TypeOf(pos)) {
        rl.Vector2 => {
            const x = cast(usize, pos.x);
            const y = cast(usize, pos.y);
            return self.pixels.get(.{ .x = x, .y = y });
        },
        Point => {
            return self.pixels.get(pos);
        },
        else => {
            @compileError("Invalid type: " ++ @typeName(@TypeOf(pos)));
        },
    }
    return self.pixels.get(pos);
}

pub fn draw(self: *const Self) void {
    rl.drawRectangleRec(self.rect, self.background_color);
    var iter = self.pixels.iterator();
    while (iter.next()) |entry| {
        const pos: rl.Vector2 = .{
            .x = cast(f32, entry.key_ptr.*.x),
            .y = cast(f32, entry.key_ptr.*.y),
        };
        const color = entry.value_ptr.*;
        rl.drawRectangleV(pos.multiply(self.cell_size), self.cell_size, color);
    }
}

fn convertToPoint(pos: anytype) Point {
    return switch (@TypeOf(pos)) {
        rl.Vector2 => {
            const x = cast(usize, pos.x);
            const y = cast(usize, pos.y);
            return .{ .x = x, .y = y };
        },
        Point => {
            return pos;
        },
        else => {
            @compileError("Invalid type: " ++ @typeName(@TypeOf(pos)));
        },
    };
}
