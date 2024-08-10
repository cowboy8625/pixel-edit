const std = @import("std");
const Allocator = std.mem.Allocator;
const rl = @import("raylib");
const rg = @import("raygui");
const utils = @import("utils.zig");
const cast = utils.cast;

const Frame = std.AutoHashMap(Point, rl.Color);
const Frames = std.ArrayList(Frame);
pub const Point = struct {
    x: usize,
    y: usize,
};

const Self = @This();
alloc: Allocator,
frames: Frames,
rect: rl.Rectangle,
cell_size: rl.Vector2,
size_in_pixels: rl.Vector2,
background_color: rl.Color = rl.Color.gray,
frame_id: usize = 0,
animation_accumulator: f32 = 0,
animation_duration: f32 = 0.2,

/// width and height are in pixels/cells
pub fn init(alloc: Allocator, rect: rl.Rectangle, cell_size: rl.Vector2) !Self {
    var frames = Frames.init(alloc);
    errdefer frames.deinit();
    try frames.append(Frame.init(alloc));

    return .{
        .alloc = alloc,
        .frames = frames,
        .rect = .{
            .x = rect.x,
            .y = rect.y,
            .width = rect.width * cell_size.x,
            .height = rect.height * cell_size.y,
        },
        .size_in_pixels = .{
            .x = rect.width,
            .y = rect.height,
        },
        .cell_size = cell_size,
    };
}

pub fn deinit(self: *Self) void {
    for (self.frames.items) |*frame| {
        frame.deinit();
    }
    self.frames.deinit();
}

pub fn save(self: *Self, path: []const u8) void {
    const width = self.size_in_pixels.x;
    const height = self.size_in_pixels.y;
    const target = rl.loadRenderTexture(cast(i32, width), cast(i32, height));
    defer rl.unloadTexture(target.texture);

    rl.beginTextureMode(target);
    const frame = self.getCurrentFrameConst();
    var iter = frame.iterator();
    while (iter.next()) |kv| {
        const pos = kv.key_ptr.*;
        const color = kv.value_ptr.*;
        rl.drawPixel(cast(i32, pos.x), cast(i32, pos.y), color);
    }
    rl.endTextureMode();
    var image = rl.loadImageFromTexture(target.texture);
    rl.imageFlipVertical(&image);
    const cpath: [*c]const u8 = @ptrCast(path);
    _ = rl.exportImage(image, cpath);
}

pub fn load(self: *Self, path: []const u8) !void {
    const cpath: [*c]const u8 = @ptrCast(path);
    const image = rl.loadImage(cpath);
    defer rl.unloadImage(image);
    self.clear();
    self.size_in_pixels = .{
        .x = cast(f32, image.width),
        .y = cast(f32, image.height),
    };
    for (0..cast(usize, image.height)) |y| {
        for (0..@intCast(image.width)) |x| {
            const color = rl.getImageColor(image, cast(i32, x), cast(i32, y));
            try self.insert(Point{ .x = x, .y = y }, color);
        }
    }
}

pub fn newFrame(self: *Self) !void {
    try self.frames.append(Frame.init(self.alloc));
}

pub fn nextFrame(self: *Self) void {
    self.frame_id = (self.frame_id + 1) % self.frames.items.len;
}

pub fn previousFrame(self: *Self) void {
    self.frame_id = if (self.frame_id == 0) self.frames.items.len - 1 else self.frame_id - 1;
}

pub fn getCurrentFramePtr(self: *Self) *Frame {
    return &self.frames.items[self.frame_id];
}

fn rotateIndexClockwise(x: usize, y: usize, w: usize, h: usize) Point {
    const new_y = x;
    const new_x = h - y - 1;
    const index = new_y * h + new_x;
    return .{
        .x = @mod(index, w),
        .y = index / h,
    };
}

fn rotateIndexCounterClockwise(x: usize, y: usize, w: usize, h: usize) Point {
    const new_x = y;
    const new_y = h - x - 1;
    const index = new_y * w + new_x;
    return .{
        .x = @mod(index, w),
        .y = index / h,
    };
}

fn flipPointHorizontal(x: usize, y: usize, w: usize, h: usize) Point {
    const new_x = w - x - 1;
    const new_y = y;
    const index = new_y * w + new_x;

    return .{
        .x = @mod(index, w),
        .y = index / h,
    };
}

fn flipPointVertical(x: usize, y: usize, w: usize, h: usize) Point {
    const new_x = x;
    const new_y = h - y - 1;
    const index = new_y * w + new_x;

    return .{
        .x = @mod(index, w),
        .y = index / h,
    };
}

pub fn rotateLeft(self: *Self) void {
    var frame = self.getCurrentFramePtr();
    var iter = frame.iterator();
    while (iter.next()) |kv| {
        const pos = kv.key_ptr.*;
        const new_pos = rotateIndexCounterClockwise(
            pos.x,
            pos.y,
            cast(usize, self.size_in_pixels.x),
            cast(usize, self.size_in_pixels.y),
        );
        kv.key_ptr.* = new_pos;
    }
}

pub fn rotateRight(self: *Self) void {
    var frame = self.getCurrentFramePtr();
    var iter = frame.iterator();
    while (iter.next()) |kv| {
        const pos = kv.key_ptr.*;
        const new_pos = rotateIndexClockwise(
            pos.x,
            pos.y,
            cast(usize, self.size_in_pixels.x),
            cast(usize, self.size_in_pixels.y),
        );
        kv.key_ptr.* = new_pos;
    }
}

pub fn flipHorizontal(self: *Self) void {
    var frame = self.getCurrentFramePtr();
    var iter = frame.iterator();
    while (iter.next()) |kv| {
        const pos = kv.key_ptr.*;
        const new_pos = flipPointHorizontal(
            pos.x,
            pos.y,
            cast(usize, self.size_in_pixels.x),
            cast(usize, self.size_in_pixels.y),
        );
        kv.key_ptr.* = new_pos;
    }
}

pub fn flipVertical(self: *Self) void {
    var frame = self.getCurrentFramePtr();
    var iter = frame.iterator();
    while (iter.next()) |kv| {
        const pos = kv.key_ptr.*;
        const new_pos = flipPointVertical(
            pos.x,
            pos.y,
            cast(usize, self.size_in_pixels.x),
            cast(usize, self.size_in_pixels.y),
        );
        kv.key_ptr.* = new_pos;
    }
}

pub fn getCurrentFrameConst(self: *const Self) *const Frame {
    return &self.frames.items[self.frame_id];
}

pub fn clear(self: *Self) void {
    var frame = self.getCurrentFramePtr();
    frame.clearRetainingCapacity();
}

pub fn insert(self: *Self, pos: anytype, color: rl.Color) !void {
    var frame = self.getCurrentFramePtr();
    const p = convertToPoint(pos);
    try frame.put(p, color);
}

pub fn remove(self: *Self, pos: anytype) void {
    var frame = self.getCurrentFramePtr();
    const p = convertToPoint(pos);
    _ = frame.remove(p);
}

pub fn get(self: *const Self, pos: anytype) ?rl.Color {
    const frame = self.getCurrentFrameConst();
    const p = convertToPoint(pos);
    return frame.get(p);
}

pub fn update(self: *Self) void {
    self.rect = .{
        .x = self.rect.x,
        .y = self.rect.y,
        .width = self.size_in_pixels.x * self.cell_size.x,
        .height = self.size_in_pixels.y * self.cell_size.y,
    };
}

pub fn draw(self: *Self) void {
    const frame = self.getCurrentFramePtr();
    rl.drawRectangleRec(self.rect, self.background_color);
    var iter = frame.iterator();
    while (iter.next()) |entry| {
        const pos: rl.Vector2 = .{
            .x = cast(f32, entry.key_ptr.*.x),
            .y = cast(f32, entry.key_ptr.*.y),
        };
        const color = entry.value_ptr.*;
        rl.drawRectangleV(pos.multiply(self.cell_size), self.cell_size, color);
    }
}

pub fn animate(self: *Self, delta_time: f32) void {
    self.animation_accumulator += delta_time;
    if (self.animation_accumulator >= self.animation_duration) {
        self.nextFrame();
        self.animation_accumulator = 0;
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
