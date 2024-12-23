const std = @import("std");
const rl = @import("rl/mod.zig");
const Frame = @import("Frame.zig");

const Self = @This();
bounding_box: rl.Rectangle(i32),
frames: std.ArrayList(Frame),
current_frame: usize,
// Defaults
pixels_size: i32 = 16,

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
