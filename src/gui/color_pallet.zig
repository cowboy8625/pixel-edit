const std = @import("std");
const button = @import("button.zig");
const ray = @cImport(@cInclude("raylib.h"));
const Allocator = std.mem.Allocator;

pub const ColorPallet = struct {
    const Self = @This();

    position: ray.Vector2,
    colors: std.ArrayList(ray.Color),
    cell_size: c_int = 32,
    alloc: Allocator,

    pub fn init(alloc: Allocator, position: ray.Vector2, starting_colors: []const ray.Color) !Self {
        const Colors = std.ArrayList(ray.Color);
        var colors = Colors.init(alloc);
        errdefer colors.deinit();
        if (starting_colors.len != 0) {
            try colors.appendSlice(starting_colors);
        }
        return Self{
            .position = position,
            .colors = colors,
            .alloc = alloc,
        };
    }

    pub fn deinit(self: *Self) void {
        self.colors.deinit();
    }

    pub fn width(self: *Self) f32 {
        const w = @min(self.colors.items.len, 2) * self.cell_size;
        return @floatFromInt(w);
    }

    pub fn height(self: *Self) f32 {
        const length = @as(c_int, @intCast(self.colors.items.len));
        const h = length * @divTrunc(self.cell_size, 2);
        return @floatFromInt(h);
    }

    pub fn update(self: *Self) !?usize {
        const mouse = ray.GetMousePosition();
        const pos_x = @as(c_int, @intFromFloat(self.position.x));
        const pos_y = @as(c_int, @intFromFloat(self.position.y));
        const w: c_int = 2;
        var y: c_int = 0;
        for (0..self.colors.items.len) |i| {
            const x = @as(c_int, @intCast(@mod(i, w)));
            // zig fmt: off
            const bounding_box = ray.Rectangle{
                .x = @as(f32, @floatFromInt(pos_x + x * self.cell_size)),
                .y = @as(f32, @floatFromInt(pos_y + y * self.cell_size)),
                .width = @as(f32, @floatFromInt(self.cell_size)),
                .height = @as(f32, @floatFromInt(self.cell_size)),
            };
            const is_left_mouse_down = ray.IsMouseButtonPressed(ray.MOUSE_LEFT_BUTTON);
            const is_right_mouse_down = ray.IsMouseButtonPressed(ray.MOUSE_RIGHT_BUTTON);
            const is_collision = ray.CheckCollisionPointRec(mouse, bounding_box);
            if (is_right_mouse_down and is_collision) {
                std.debug.print("Right click\n", .{});
                if (colorPicker(200, 100)) |color| {
                    std.debug.print("color: {any}\n", .{color});
                    try self.colors.append(color);
                    return null;
                }
                std.debug.print("no color\n", .{});
            }
            if (is_left_mouse_down and is_collision) {
                return i;
            }
            y += @intFromBool(i % w >= w - 1);
        }
        return null;
    }

    pub fn draw(self: *Self) void {
        const pos_x = @as(c_int, @intFromFloat(self.position.x));
        const pos_y = @as(c_int, @intFromFloat(self.position.y));
        const w: c_int = 2;
        var y: c_int = 0;
        for (0.., self.colors.items) |i, color| {
            const x = @as(c_int, @intCast(@mod(i, w)));
            // zig fmt: off
            ray.DrawRectangle(
                pos_x + x * self.cell_size,
                pos_y + y * self.cell_size,
                self.cell_size,
                self.cell_size,
                color
            );
            y += @intFromBool(i % w >= w - 1);
        }
    }
};


fn colorPicker(x: c_int, y: c_int) ?ray.Color {
    const colors = [_]ray.Color{
        .{ .r = 200 , .g = 200  , .b = 200 , .a = 255 },
        .{ .r = 130 , .g = 130  , .b = 130 , .a = 255 },
        .{ .r = 80  , .g = 80   , .b = 80  , .a = 255 },
        .{ .r = 253 , .g = 249  , .b = 0   , .a = 255 },
        .{ .r = 255 , .g = 203  , .b = 0   , .a = 255 },
        .{ .r = 255 , .g = 161  , .b = 0   , .a = 255 },
        .{ .r = 255 , .g = 109  , .b = 194 , .a = 255 },
        .{ .r = 230 , .g = 41   , .b = 55  , .a = 255 },
        .{ .r = 190 , .g = 33   , .b = 55  , .a = 255 },
        .{ .r = 0   , .g = 228  , .b = 48  , .a = 255 },
        .{ .r = 0   , .g = 158  , .b = 47  , .a = 255 },
        .{ .r = 0   , .g = 117  , .b = 44  , .a = 255 },
        .{ .r = 102 , .g = 191  , .b = 255 , .a = 255 },
        .{ .r = 0   , .g = 121  , .b = 241 , .a = 255 },
        .{ .r = 0   , .g = 82   , .b = 172 , .a = 255 },
        .{ .r = 200 , .g = 122  , .b = 255 , .a = 255 },
        .{ .r = 135 , .g = 60   , .b = 190 , .a = 255 },
        .{ .r = 112 , .g = 31   , .b = 126 , .a = 255 },
        .{ .r = 211 , .g = 176  , .b = 131 , .a = 255 },
        .{ .r = 127 , .g = 106  , .b = 79  , .a = 255 },
        .{ .r = 128 , .g = 107  , .b = 79  , .a = 255 },
        .{ .r = 129 , .g = 108  , .b = 79  , .a = 255 },
        .{ .r = 130 , .g = 108  , .b = 80  , .a = 255 },
        .{ .r = 131 , .g = 108  , .b = 81  , .a = 255 },
        .{ .r = 132 , .g = 108  , .b = 81  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 81  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 81  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
        .{ .r = 133 , .g = 108  , .b = 82  , .a = 255 },
    };


    var selected_color: ?usize = null;
    const size = 200;
    const cell_size: c_int = 20;
    const cell_width_count: c_int = 10;
    const bounding_box = ray.Rectangle{
        .x = @floatFromInt(x),
        .y = @floatFromInt(y),
        .width = size,
        .height = size + 40,
    };

    const header_bar = ray.Rectangle{
        .x = @floatFromInt(x),
        .y = @floatFromInt(y),
        .width = size,
        .height = 20,
    };

    const ok_texture = ray.LoadTexture("assets/ok_button.png");
    defer ray.UnloadTexture(ok_texture);

    var button_ok = button.Button {
        .text = "OK",
        .position = .{
            .x = bounding_box.x + bounding_box.width -  @as(f32, @floatFromInt(ok_texture.width)),
            .y = bounding_box.y + bounding_box.height - @as(f32, @floatFromInt(ok_texture.height))
        },
        .texture = ok_texture,
    };

    const cancel_texture = ray.LoadTexture("assets/cancel_button.png");
    defer ray.UnloadTexture(ok_texture);

    var button_cancel = button.Button {
        .text = "OK",
        .position = .{
            .x = bounding_box.x + @as(f32, @floatFromInt(ok_texture.width)),
            .y = bounding_box.y + bounding_box.height - @as(f32, @floatFromInt(ok_texture.height))
        },
        .texture = cancel_texture,
    };

    var first = false;

    while (true) {
        const mouse = ray.GetMousePosition();
        const is_left_mouse_down = ray.IsMouseButtonPressed(ray.MOUSE_LEFT_BUTTON);
        // const is_right_mouse_down = ray.IsMouseButtonPressed(ray.MOUSE_RIGHT_BUTTON);
        // const is_collision = ray.CheckCollisionPointRec(mouse, bounding_box);
        // if ((is_right_mouse_down or is_left_mouse_down) and !is_collision and first) {
        //     std.debug.print("breaking\n", .{});
        //     break;
        // }

        {
            const pos_x = @as(c_int, @intFromFloat(bounding_box.x));
            const pos_y = @as(c_int, @intFromFloat(bounding_box.y + header_bar.height));
            var yy: c_int = 0;
            for (0..colors.len) |i| {
                const xx = @as(c_int, @intCast(@mod(i, cell_width_count)));
                // zig fmt: off
                const color_box = ray.Rectangle{
                    .x = @as(f32, @floatFromInt(pos_x + xx * cell_size)),
                    .y = @as(f32, @floatFromInt(pos_y + yy * cell_size)),
                    .width = @as(f32, @floatFromInt(cell_size)),
                    .height = @as(f32, @floatFromInt(cell_size)),
                };
                const is_in_color_box = ray.CheckCollisionPointRec(mouse, color_box);
                if (is_left_mouse_down and is_in_color_box) {
                    selected_color = i;
                }
                yy += @intFromBool(i % cell_width_count >= cell_width_count - 1);
            }
        }

        if (button_ok.update()) {
            std.debug.print("OK {any}\n", .{selected_color});
            if (selected_color) |index| {
                return colors[index];
            }
        }
        if (button_cancel.update()) {
            break;
        }

        // -----------Draw-------------
        ray.BeginDrawing();
        ray.DrawRectangleRec(bounding_box, ray.LIGHTGRAY);
        ray.DrawRectangleRec(header_bar, ray.DARKGRAY);
        ray.DrawText("Color Picker", x + 40, y, cell_size, ray.WHITE);
        drawColorPallet(x, y + 20, cell_size, &colors);
        if (selected_color) |index| {
            const i: c_int = @intCast(index);
            const bound_x: c_int = @intFromFloat(bounding_box.x);
            const bound_y: c_int = @intFromFloat(bounding_box.y);
            const y_: c_int = (@divTrunc(i, cell_width_count) + 1) * cell_size + bound_y;
            const x_: c_int = @mod(i, cell_width_count) * cell_size + bound_x;
            ray.DrawRectangleLines(x_, y_, cell_size, cell_size, ray.BLACK);
        }


        button_ok.draw();
        button_cancel.draw();


        ray.EndDrawing();
        // -----------------------------
        first = true;
    }
    return null;
}

fn drawColorPallet(xx: c_int, yy: c_int, cell_size: c_int, colors: []const ray.Color) void {
    const w: c_int = 10;
    var y: c_int = 0;
    for (0.., colors) |i, color| {
        const x = @as(c_int, @intCast(@mod(i, w)));
        ray.DrawRectangle(
            xx + x * cell_size,
            yy + y * cell_size,
            cell_size,
            cell_size,
            color
        );
        y += @intFromBool(i % w >= w - 1);
    }
}
