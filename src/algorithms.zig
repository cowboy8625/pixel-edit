const std = @import("std");
const Allocator = std.mem.Allocator;
const rl = @import("rl/mod.zig");
const Canvas = @import("Canvas.zig");

pub fn floodFill(alloc: Allocator, canvas: *Canvas, replacement_color: rl.Color, sp: rl.Vector2(i32)) !void {
    const starting_point = sp.div(canvas.pixels_size);
    const rect = canvas.bounding_box;
    var stack = std.ArrayList(rl.Vector2(i32)).init(alloc);
    defer stack.deinit();
    var visited = std.AutoHashMap(rl.Vector2(i32), void).init(alloc);
    defer visited.deinit();

    const target_color = if (canvas.get(starting_point)) |color| color else rl.Color.blank;
    try stack.append(starting_point);
    try visited.put(starting_point, {});
    const frame = canvas.getCurrentFramePtr() orelse @panic("No frame");

    while (stack.items.len > 0) {
        const pixel = stack.pop();
        const current_color =
            if (canvas.get(pixel)) |color| color else rl.Color.blank;

        if (rect.contains(pixel) and compareColors(current_color, target_color)) {
            try frame.pixels.put(pixel, replacement_color);
            if (pixel.x < rect.width) {
                const pos = .{ .x = pixel.x + 1, .y = pixel.y };
                if (visited.get(pos) == null) {
                    try stack.append(pos);
                    try visited.put(pos, {});
                }
            }
            if (pixel.x > 0) {
                const pos = .{ .x = pixel.x - 1, .y = pixel.y };
                if (visited.get(pos) == null) {
                    try stack.append(pos);
                    try visited.put(pos, {});
                }
            }
            if (pixel.y < rect.height) {
                const pos = .{ .x = pixel.x, .y = pixel.y + 1 };
                if (visited.get(pos) == null) {
                    try stack.append(pos);
                    try visited.put(pos, {});
                }
            }
            if (pixel.y > 0) {
                const pos = .{ .x = pixel.x, .y = pixel.y - 1 };
                if (visited.get(pos) == null) {
                    try stack.append(pos);
                    try visited.put(pos, {});
                }
            }
        }
    }
}

fn compareColors(c1: rl.Color, c2: rl.Color) bool {
    return c1.r == c2.r and c1.g == c2.g and c1.b == c2.b and c1.a == c2.a;
}

pub fn bresenhamLine(comptime T: type, xx1: i32, yy1: i32, x2: i32, y2: i32, out: *std.ArrayList(rl.Vector2(T))) !void {
    var x1 = xx1;
    var y1 = yy1;
    const dx: i32 = rl.cast(i32, @abs(x2 - x1));
    const dy: i32 = rl.cast(i32, @abs(y2 - y1));

    const sx: i32 = if (x1 < x2) 1 else -1;
    const sy: i32 = if (y1 < y2) 1 else -1;
    var err: i32 = dx - dy;

    while (true) {
        try out.*.append(.{ .x = x1, .y = y1 });

        if (x1 == x2 and y1 == y2) break;

        const e2 = 2 * err;

        if (e2 > -dy) {
            err -= dy;
            x1 += sx;
        }

        if (e2 < dx) {
            err += dx;
            y1 += sy;
        }
    }
}
