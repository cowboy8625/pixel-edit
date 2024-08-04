const rl = @import("raylib");
draw_grid: bool = false,
line_tool: bool = false,
last_cell_position: rl.Vector2 = .{ .x = 0, .y = 0 },
