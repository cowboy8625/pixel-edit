const std = @import("std");
const rl = @import("rl/mod.zig");
const Frame = @import("Frame.zig");
const algorithms = @import("algorithms.zig");

const Self = @This();
bounding_box: rl.Rectangle(i32),
frames: std.ArrayList(Frame),
current_frame: usize,
pixels_size: i32,
display_grid: bool = false,
frame_tool: bool = false,
last_cursor: rl.Vector2(i32) = .{ .x = 0, .y = 0 },
overlay_pixels: std.ArrayList(rl.Vector2(i32)),
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator, bounding_box: rl.Rectangle(i32), pixels_size: i32) !Self {
    var self = .{
        .bounding_box = bounding_box,
        .frames = std.ArrayList(Frame).init(allocator),
        .current_frame = 0,
        .pixels_size = pixels_size,
        .overlay_pixels = std.ArrayList(rl.Vector2(i32)).init(allocator),
        .allocator = allocator,
    };
    try self.frames.append(Frame.init(bounding_box, allocator));
    return self;
}

pub fn deinit(self: *Self) void {
    for (self.frames.items) |*frame| {
        frame.deinit();
    }
    self.frames.deinit();
    self.overlay_pixels.deinit();
}

pub fn getVisibleRect(self: *const Self, comptime T: type) rl.Rectangle(T) {
    const rect: rl.Rectangle(i32) = .{
        .x = self.bounding_box.x,
        .y = self.bounding_box.y,
        .width = (self.bounding_box.width + 1) * self.pixels_size,
        .height = (self.bounding_box.height + 1) * self.pixels_size,
    };
    return rect.as(T);
}

pub fn getCurrentFramePtr(self: *Self) ?*Frame {
    if (self.current_frame >= self.frames.items.len) return null;
    return &self.frames.items[self.current_frame];
}

pub fn getCurrentFrameConstPtr(self: *const Self) ?*const Frame {
    if (self.current_frame >= self.frames.items.len) return null;
    return &self.frames.items[self.current_frame];
}

pub fn setWidth(self: *Self, width: i32) void {
    if (width == 0) return;
    self.bounding_box.width = width;
    for (self.frames.items) |*frame| {
        frame.bounding_box.width = width;
    }
}

pub fn setHeight(self: *Self, height: i32) void {
    if (height == 0) return;
    self.bounding_box.height = height;
    for (self.frames.items) |*frame| {
        frame.bounding_box.height = height;
    }
}

fn normalizeCursor(self: *const Self, world_pos: rl.Vector2(i32)) rl.Vector2(i32) {
    return world_pos.as(i32).sub(self.bounding_box.getPos()).div(self.pixels_size);
}

pub fn insert(self: *Self, world_mouse: rl.Vector2(i32), color: rl.Color) !bool {
    const cursor = self.normalizeCursor(world_mouse);
    const frame = self.getCurrentFramePtr() orelse @panic("No frame");
    if (!frame.bounding_box.contains(cursor)) {
        return false;
    }
    try frame.pixels.put(cursor, color);
    self.last_cursor = cursor;
    return true;
}

pub fn remove(self: *Self, cursor: rl.Vector2(i32)) !bool {
    if (!self.bounding_box.contains(cursor)) return false;
    const frame = self.getCurrentFramePtr() orelse return false;
    const pixel = cursor.sub(self.bounding_box.getPos()).div(self.pixels_size);
    return frame.remove(pixel);
}

pub fn get(self: *const Self, cursor: rl.Vector2(i32)) ?rl.Color {
    const frame = self.getCurrentFrameConstPtr() orelse return null;
    return frame.pixels.get(cursor);
}

pub fn clear(self: *Self) void {
    var frame = self.getCurrentFramePtr();
    if (frame == null) {
        @panic("Cannot clear empty frame");
    }
    frame.?.pixels.clearRetainingCapacity();
}

pub fn nextFrame(self: *Self) void {
    self.current_frame = (self.current_frame + 1) % self.frames.items.len;
}

pub fn previousFrame(self: *Self) void {
    self.current_frame = if (self.current_frame == 0) self.frames.items.len - 1 else self.current_frame - 1;
}

pub fn newFrame(self: *Self) !void {
    self.current_frame = self.frames.items.len;
    try self.frames.append(Frame.init(self.bounding_box, self.allocator));
}

pub fn deleteFrame(self: *Self) void {
    if (self.frames.items.len == 1) return;
    var old_frame = self.frames.orderedRemove(self.current_frame);
    old_frame.deinit();
    self.current_frame = if (self.current_frame == 0) 0 else self.current_frame - 1;
}

pub fn toggleFrameTool(self: *Self) void {
    self.frame_tool = !self.frame_tool;
}

pub fn applyLineToOverlay(self: *Self, endPoint: rl.Vector2(i32)) !void {
    const end = self.normalizeCursor(endPoint);
    const start = self.last_cursor;
    self.overlay_pixels.clearRetainingCapacity();
    try algorithms.bresenhamLine(
        i32,
        start.x,
        start.y,
        end.x,
        end.y,
        &self.overlay_pixels,
    );
}

pub fn applyOverlay(self: *Self, color: rl.Color) !void {
    const frame = self.getCurrentFramePtr() orelse @panic("Cannot apply overlay to empty frame");
    for (self.overlay_pixels.items) |pixel| {
        if (!(try frame.insert(pixel, color))) {
            std.log.err("Failed to apply overlay pixel {any}", .{pixel});
        }
    }

    if (self.overlay_pixels.getLastOrNull()) |last| {
        self.last_cursor = last;
    }
}

pub fn clearOverlay(self: *Self) void {
    self.overlay_pixels.clearRetainingCapacity();
}

pub fn rotateLeft(self: *Self) void {
    var frame = self.getCurrentFramePtr() orelse @panic("Cannot rotate empty frame");
    var iter = frame.iterator();
    while (iter.next()) |kv| {
        const pos = kv.key_ptr.*;
        const size = self.pixels_size;
        const rect = rl.Rectangle(i32).init(pos.x, pos.y, size, size);
        const new_pos = rotateIndexCounterClockwise(i32, rect);
        kv.key_ptr.* = new_pos;
    }
}

pub fn rotateRight(self: *Self) void {
    var frame = self.getCurrentFramePtr() orelse @panic("Cannot rotate empty frame");
    var iter = frame.iterator();
    while (iter.next()) |kv| {
        const pos = kv.key_ptr.*;
        const size = self.pixels_size;
        const rect = rl.Rectangle(i32).init(pos.x, pos.y, size, size);
        const new_pos = rotateIndexClockwise(i32, rect);
        kv.key_ptr.* = new_pos;
    }
}

pub fn flipHorizontal(self: *Self) void {
    var frame = self.getCurrentFramePtr() orelse @panic("Cannot flip empty frame");
    var iter = frame.iterator();
    while (iter.next()) |kv| {
        const pos = kv.key_ptr.*;
        const size = self.pixels_size;
        const rect = rl.Rectangle(i32).init(pos.x, pos.y, size, size);
        const new_pos = flipPointHorizontal(i32, rect);
        kv.key_ptr.* = new_pos;
    }
}

pub fn flipVertical(self: *Self) void {
    var frame = self.getCurrentFramePtr() orelse @panic("Cannot flip empty frame");
    var iter = frame.iterator();
    while (iter.next()) |kv| {
        const pos = kv.key_ptr.*;
        const size = self.pixels_size;
        const rect = rl.Rectangle(i32).init(pos.x, pos.y, size, size);
        const new_pos = flipPointVertical(i32, rect);
        kv.key_ptr.* = new_pos;
    }
}

pub fn save(self: *Self, path: []const u8) void {
    const rect = self.bounding_box.as(f32);
    const width = (rect.width + 1) * rl.cast(f32, self.frames.items.len);
    const height = rect.height + 1;
    const target = rl.loadRenderTexture(rl.cast(i32, width), rl.cast(i32, height));
    defer rl.unloadTexture(target.texture);

    rl.beginTextureMode(target);
    for (0.., self.frames.items) |idx, frame| {
        const x_offset = idx * rl.cast(usize, rect.width);
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

    const frame_rect = self.bounding_box.as(usize);
    const frame_width: usize = frame_rect.width + 1;
    // const frame_height: usize = frame_rect.height + 1;
    const total_width = rl.cast(usize, image.width);
    // const total_height = rl.cast(usize, image.height);

    const num_frames = total_width / frame_width;
    // if (total_width % frame_width != 0 or total_height != frame_height) {
    //     std.log.err("Invalid frame dimensions {d}x{d} != {d}x{d}", .{ frame_width, frame_height, total_width, total_height });
    //     return error.InvalidFrameDimensions;
    // }

    self.clear();

    for (0..num_frames) |frame_index| {
        var frame = self.getCurrentFramePtr() orelse @panic("Cannot load into empty frame");
        for (0..frame_rect.height + 1) |y| {
            for (0..frame_rect.width + 1) |x| {
                const global_x = frame_index * (frame_rect.width + x);
                const color = rl.getImageColor(image, rl.cast(i32, global_x), rl.cast(i32, y));
                const pos = rl.Vector2(usize).init(x, y).as(i32);
                try frame.pixels.put(pos, color);
                if (x == 16 and frame_index == 0) {
                    std.log.info("Loading frame {any}, {any}", .{ pos, color });
                }
            }
        }
        if (frame_index + 1 != num_frames) {
            try self.newFrame();
        }
    }
}

pub fn toggleGrid(self: *Self) void {
    self.display_grid = !self.display_grid;
}

fn drawGrid(self: *const Self) void {
    const rect = self.getVisibleRect(i32);
    const cells: rl.Vector2(i32) = .{ .x = self.pixels_size, .y = self.pixels_size };
    const px_width = rect.width * cells.x;
    const px_height = rect.height * cells.y;
    for (0..(rl.cast(usize, rect.width) + 1)) |x| {
        const ix = cells.x * rl.cast(i32, x);
        rl.drawLine(ix, 0, ix, px_height, rl.Color.gray);
    }
    for (0..(rl.cast(usize, rect.height) + 1)) |y| {
        const iy = cells.y * rl.cast(i32, y);
        rl.drawLine(0, iy, px_width, iy, rl.Color.gray);
    }
}

// TODO: to make this more efficient, we can draw to a
// texture and then have a queue of pixels to add or
// remove from the texture and only draw the texture
pub fn draw(self: *const Self, mouse: ?rl.Vector2(f32)) void {
    const top_left = self.bounding_box.getPos();
    if (self.frame_tool) {
        const current_frame = -rl.cast(i32, self.current_frame);
        const padding = self.pixels_size * 3;
        const bounding_box = self.frames.items[0].bounding_box;
        var offset_x: i32 = current_frame * (bounding_box.width * self.pixels_size + padding);
        var canvas_rect =
            rl.Rectangle(i32).init(
            bounding_box.x + offset_x,
            bounding_box.y,
            (bounding_box.width + 1) * self.pixels_size,
            (bounding_box.height + 1) * self.pixels_size,
        );

        for (0.., self.frames.items) |i, frame| {
            canvas_rect.x = bounding_box.x + offset_x;

            rl.drawRectangleRec(
                canvas_rect.as(f32),
                rl.Color.ray_white,
            );

            var iter = frame.pixels.iterator();
            while (iter.next()) |kv| {
                const pos = kv.key_ptr.*.mul(self.pixels_size).add(top_left).addX(offset_x);
                const color = kv.value_ptr.*;
                const rect = rl.Rectangle(i32).from2vec2(pos, .{ .x = self.pixels_size, .y = self.pixels_size });
                rl.drawRectangleRec(rect.as(f32), color);
            }

            if (self.current_frame == i) {
                rl.drawRectangleLinesEx(
                    canvas_rect.as(f32),
                    1,
                    rl.Color.green,
                );
            }

            offset_x += frame.bounding_box.width * self.pixels_size + padding;
        }
    } else {
        rl.drawRectangleRec(
            self.getVisibleRect(f32),
            rl.Color.ray_white,
        );
        const frame = self.getCurrentFrameConstPtr() orelse return;
        var iter = frame.pixels.iterator();
        while (iter.next()) |kv| {
            const pos = kv.key_ptr.*.mul(self.pixels_size).add(top_left);
            const color = kv.value_ptr.*;
            const rect = rl.Rectangle(i32).from2vec2(pos, .{ .x = self.pixels_size, .y = self.pixels_size });
            rl.drawRectangleRec(rect.as(f32), color);
        }
    }

    // Draw overlay
    for (self.overlay_pixels.items) |pos| {
        rl.drawRectangleRec(
            rl.Rectangle(i32).from2vec2(pos.mul(self.pixels_size), .{ .x = self.pixels_size, .y = self.pixels_size }).as(f32),
            rl.Color.gray,
        );
    }

    // Draw cursor
    if (mouse) |m| {
        const cursor = self.normalizeCursor(m.as(i32));
        const rect = rl.Rectangle(i32).from2vec2(cursor.mul(self.pixels_size), .{ .x = self.pixels_size, .y = self.pixels_size });
        rl.drawRectangleLines(rect.x, rect.y, rect.width, rect.height, rl.Color.gray);
    }

    if (self.display_grid) self.drawGrid();
}

fn rotateIndexClockwise(comptime T: type, rect: rl.Rectangle(T)) rl.Vector2(T) {
    const new_y = rect.x;
    const new_x = rect.height - rect.y - 1;
    const index = new_y * rect.height + new_x;
    return .{
        .x = @mod(index, rect.width),
        .y = @divFloor(index, rect.height),
    };
}

fn rotateIndexCounterClockwise(comptime T: type, rect: rl.Rectangle(T)) rl.Vector2(T) {
    const new_x = rect.y;
    const new_y = rect.height - rect.x - 1;
    const index = new_y * rect.width + new_x;
    return .{
        .x = @mod(index, rect.width),
        .y = @divFloor(index, rect.height),
    };
}

fn flipPointHorizontal(comptime T: type, rect: rl.Rectangle(T)) rl.Vector2(T) {
    const new_x = rect.width - rect.x - 1;
    const new_y = rect.y;
    const index = new_y * rect.width + new_x;

    return .{
        .x = @mod(index, rect.width),
        .y = @divFloor(index, rect.height),
    };
}

fn flipPointVertical(comptime T: type, rect: rl.Rectangle(T)) rl.Vector2(T) {
    const new_x = rect.x;
    const new_y = rect.height - rect.y - 1;
    const index = new_y * rect.width + new_x;

    return .{
        .x = @mod(index, rect.width),
        .y = @divFloor(index, rect.height),
    };
}
