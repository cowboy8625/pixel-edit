const utils = @import("utils.zig");
const std = @import("std");
const button = @import("button.zig");
const ray = @cImport(@cInclude("raylib.h"));
const Allocator = std.mem.Allocator;

pub const ColorPallet = struct {
    const Self = @This();

    position: ray.Vector2,
    selected_color: struct { x: c_int, y: c_int },
    colors: std.ArrayList(ray.Color),
    alloc: Allocator,

    cell_size: c_int = 32,

    pub fn init(alloc: Allocator, position: ray.Vector2, starting_colors: []const ray.Color) !Self {
        const Colors = std.ArrayList(ray.Color);
        var colors = Colors.init(alloc);
        errdefer colors.deinit();
        if (starting_colors.len != 0) {
            try colors.appendSlice(starting_colors);
        }
        // TODO: This is sloppy
        const pos = getCordsFromIndex(0, 32, 2, position);
        return Self{
            .position = position,
            .selected_color = .{ .x = pos.x, .y = pos.y },
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
            const is_collision = ray.CheckCollisionPointRec(mouse, bounding_box);
            if (is_left_mouse_down and is_collision) {
                const pos = getCordsFromIndex(i, self.cell_size, w, self.position);
                self.selected_color = .{ .x = pos.x, .y = pos.y };
                return i;
            } else if (is_collision and ray.IsKeyDown(ray.KEY_R)) {
                incColor(&self.colors.items[i].r);
            } else if (is_collision and ray.IsKeyDown(ray.KEY_G)) {
                incColor(&self.colors.items[i].g);
            } else if (is_collision and ray.IsKeyDown(ray.KEY_B)) {
                incColor(&self.colors.items[i].b);
            } else if (is_collision and ray.IsKeyDown(ray.KEY_A)) {
                incColor(&self.colors.items[i].a);
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

        ray.DrawRectangleLines(
            self.selected_color.x,
            self.selected_color.y,
            self.cell_size,
            self.cell_size,
            ray.BLACK
        );
    }
};

fn incColor(value: *u8) void {
    const d = ray.GetMouseWheelMove();
    if (d > 0) {
    value.* +|= 1;
    } else if (d < 0) {
    value.* -|= 1;
    }
}

fn getCordsFromIndex(index: usize, cell_size: c_int, cell_count_width: c_int, offset: ray.Vector2) struct { x: c_int, y: c_int } {
    const i: c_int = @intCast(index);
    const bound_x: c_int = @intFromFloat(offset.x);
    const bound_y: c_int = @intFromFloat(offset.y);
    const y_: c_int = @divTrunc(i, cell_count_width) * cell_size + bound_y;
    const x_: c_int = @mod(i, cell_count_width) * cell_size + bound_x;
    return .{
        .x = x_,
        .y = y_,
    };
}
