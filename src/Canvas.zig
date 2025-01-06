const std = @import("std");
const rl = @import("rl/mod.zig");
const Frame = @import("Frame.zig");

const Self = @This();
bounding_box: rl.Rectangle(i32),
frames: std.ArrayList(Frame),
current_frame: usize,
// Defaults
pixels_size: i32 = 16,
size_in_pixels: rl.Vector2(f32) = .{ .x = 1, .y = 1 },

pub fn init(bounding_box: rl.Rectangle(i32), allocator: std.mem.Allocator) !Self {
    var self = Self{
        .bounding_box = bounding_box,
        .frames = std.ArrayList(Frame).init(allocator),
        .current_frame = 0,
    };
    errdefer self.deinit();

    const bb_size = bounding_box.getSize().mul(self.pixels_size);
    const bb_pos = bounding_box.getPos();
    const bb = rl.Rectangle(i32).from2vec2(bb_pos, bb_size);
    self.bounding_box = bb;

    const frame_bb = rl.Rectangle(i32).from2vec2(.{ .x = 0, .y = 0 }, bounding_box.getSize().sub(1));
    const frame = Frame.init(frame_bb, allocator);
    try self.frames.append(frame);

    return self;
}

pub fn deinit(self: *Self) void {
    for (self.frames.items) |*frame| {
        frame.deinit();
    }
    self.frames.deinit();
}

pub fn setWidth(self: *Self, width: i32) void {
    self.bounding_box.width = width * self.pixels_size;
    for (self.frames.items) |*f| {
        f.bounding_box.width = width;
    }
}

pub fn setHeight(self: *Self, height: i32) void {
    self.bounding_box.height = height * self.pixels_size;
    for (self.frames.items) |*f| {
        f.bounding_box.height = height;
    }
}

pub fn getCurrentFramePtr(self: *Self) ?*Frame {
    if (self.current_frame >= self.frames.items.len) return null;
    return &self.frames.items[self.current_frame];
}

pub fn getCurrentFrameConstPtr(self: *const Self) ?*const Frame {
    if (self.current_frame >= self.frames.items.len) return null;
    return &self.frames.items[self.current_frame];
}

pub fn insert(self: *Self, cursor: rl.Vector2(i32), color: rl.Color) !bool {
    if (!self.bounding_box.contains(cursor)) return false;
    const frame = self.getCurrentFramePtr() orelse return false;
    const pixel = cursor.sub(self.bounding_box.getPos()).div(self.pixels_size);
    return try frame.insert(pixel, color);
}

pub fn clear(self: *Self) void {
    var frame = self.getCurrentFramePtr();
    if (frame == null) {
        @panic("Cannot clear empty frame");
    }
    frame.?.pixels.clearRetainingCapacity();
}

pub fn save(self: *Self, path: []const u8) void {
    const width = self.size_in_pixels.x * rl.cast(f32, self.frames.items.len);
    const height = self.size_in_pixels.y;
    const target = rl.loadRenderTexture(rl.cast(i32, width), rl.cast(i32, height));
    defer rl.unloadTexture(target.texture);

    rl.beginTextureMode(target);
    for (0.., self.frames.items) |idx, frame| {
        const x_offset = idx * rl.cast(usize, self.size_in_pixels.x);
        var iter = frame.pixels.iterator();
        while (iter.next()) |kv| {
            const pos = kv.key_ptr.*;
            const color = kv.value_ptr.*;
            rl.drawPixel(pos.x + rl.cast(i32, x_offset), rl.cast(i32, pos.y), color);
        }
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
        .x = rl.cast(f32, image.width),
        .y = rl.cast(f32, image.height),
    };
    const frame = self.getCurrentFramePtr() orelse @panic("Cannot load into empty frame");
    for (0..rl.cast(usize, image.height)) |y| {
        for (0..@intCast(image.width)) |x| {
            const color = rl.getImageColor(image, rl.cast(i32, x), rl.cast(i32, y));
            const pos = rl.Vector2(usize).init(x, y).as(i32);
            try frame.pixels.put(pos, color);
            // _ = try self.insert(pos, color);
        }
    }
}

pub fn draw(self: *const Self) void {
    rl.drawRectangleRec(
        self.bounding_box.as(f32),
        rl.Color.ray_white,
    );
    const frame = self.getCurrentFrameConstPtr() orelse return;
    var iter = frame.pixels.iterator();
    while (iter.next()) |kv| {
        const pos = kv.key_ptr.*.mul(self.pixels_size).add(self.bounding_box.getPos());
        const color = kv.value_ptr.*;
        const rect = rl.Rectangle(i32).from2vec2(pos, .{ .x = self.pixels_size, .y = self.pixels_size });
        rl.drawRectangleRec(rect.as(f32), color);
    }
}
