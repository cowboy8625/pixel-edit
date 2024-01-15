const std = @import("std");
const ray = @cImport(@cInclude("raylib.h"));

pub const ColorPallet = struct {
    const Self = @This();

    position: ray.Vector2,
    colors: []ray.Color,
    cell_size: c_int = 32,

    pub fn width(self: *Self) f32 {
        const w = @min(self.colors.len, 2) * self.cell_size;
        return @floatFromInt(w);
    }

    pub fn height(self: *Self) f32 {
        const length = @as(c_int, @intCast(self.colors.len));
        const h = length * @divTrunc(self.cell_size, 2);
        return @floatFromInt(h);
    }

    pub fn update(self: *Self) ?usize {
        const mouse = ray.GetMousePosition();
        const pos_x = @as(c_int, @intFromFloat(self.position.x));
        const pos_y = @as(c_int, @intFromFloat(self.position.y));
        const w: c_int = 2;
        var y: c_int = 0;
        for (0..self.colors.len) |i| {
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
                colorPicker(100, 100);
                return null;
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
        for (0.., self.colors) |i, color| {
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


fn colorPicker(x: c_int, y: c_int) void {
    const size = 200;
    var bounding_box = ray.Rectangle{
        .x = @floatFromInt(x),
        .y = @floatFromInt(y),
        .width = size,
        .height = size,
    };

    const header_bar = ray.Rectangle{
        .x = @floatFromInt(x),
        .y = @floatFromInt(y),
        .width = size,
        .height = 20,
    };
    var first = false;

    while (true) {
        const mouse = ray.GetMousePosition();
        const is_left_mouse_down = ray.IsMouseButtonPressed(ray.MOUSE_LEFT_BUTTON);
        const is_right_mouse_down = ray.IsMouseButtonPressed(ray.MOUSE_RIGHT_BUTTON);
        const is_collision = ray.CheckCollisionPointRec(mouse, bounding_box);
        if ((is_right_mouse_down or is_left_mouse_down) and !is_collision and first) {
            std.debug.print("breaking\n", .{});
            break;
        }

        if (ray.CheckCollisionPointRec(mouse, header_bar) and is_left_mouse_down) {
            bounding_box.x = mouse.x;
            bounding_box.y = mouse.y;
        }
        // -----------Draw-------------
        ray.BeginDrawing();
        ray.DrawRectangleRec(bounding_box, ray.RED);
        ray.DrawRectangleRec(header_bar, ray.GREEN);
        ray.DrawText("Color Picker", x, y, 20, ray.WHITE);
        ray.EndDrawing();
        // -----------------------------
        first = true;
    }

}
