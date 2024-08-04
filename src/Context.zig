const rl = @import("raylib");

pub const Mode = enum {
    Draw,
    Line,
    Fill,
};

draw_grid: bool = false,
last_cell_position: rl.Vector2 = .{ .x = 0, .y = 0 },
mode: Mode = .Draw,
