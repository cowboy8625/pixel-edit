const std = @import("std");
const Allocator = std.mem.Allocator;
const rl = @import("raylib");
const utils = @import("utils.zig");
const cast = utils.cast;
const Canvas = @import("Canvas.zig");
const Context = @import("Context.zig");
const Brush = @import("Brush.zig");

pub fn floodFill(alloc: Allocator, canvas: *Canvas, brush: Brush, starting_point: Canvas.Point) !void {
    const width = cast(usize, canvas.size_in_pixels.x);
    const height = cast(usize, canvas.size_in_pixels.y);
    var stack = std.ArrayList(Canvas.Point).init(alloc);
    defer stack.deinit();
    var visited = std.AutoHashMap(Canvas.Point, void).init(alloc);
    defer visited.deinit();

    const target_color =
        if (canvas.get(starting_point)) |color| color else rl.Color.blank;
    const replacement_color = brush.color;
    try stack.append(starting_point);
    try visited.put(starting_point, {});

    while (stack.items.len > 0) {
        const pixel = stack.pop();
        const current_color =
            if (canvas.get(pixel)) |color| color else rl.Color.blank;

        if ((0 <= pixel.x and pixel.x < width) and
            (0 <= pixel.y and pixel.y < height) and
            compareColors(current_color, target_color))
        {
            try canvas.insert(pixel, replacement_color);
            if (pixel.x < width - 1) {
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
            if (pixel.y < height - 1) {
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

pub fn bresenhamLine(xx1: i32, yy1: i32, x2: i32, y2: i32, out: *std.ArrayList(rl.Vector2)) !void {
    var x1 = xx1;
    var y1 = yy1;
    const dx: i32 = cast(i32, @abs(x2 - x1));
    const dy: i32 = cast(i32, @abs(y2 - y1));

    const sx: i32 = if (x1 < x2) 1 else -1;
    const sy: i32 = if (y1 < y2) 1 else -1;
    var err: i32 = dx - dy;

    while (true) {
        try out.*.append(.{ .x = cast(f32, x1), .y = cast(f32, y1) });

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
