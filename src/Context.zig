const rl = @import("raylib");
const Brush = @import("Brush.zig");

pub const Mode = enum {
    Draw,
    Line,
    Fill,
};

const Self = @This();

// FLAGS
draw_grid: bool = false,
file_manager_is_open: bool = false,
gui_active: bool = false,
color_picker_is_open: bool = false,

// DATA
save_file_path: ?[]const u8 = null,
last_cell_position: rl.Vector2 = .{ .x = 0, .y = 0 },
mode: Mode = .Draw,
brush: Brush,

// METHODS
pub fn init() Self {
    return .{
        .brush = Brush.init(),
    };
}
pub fn deinit(self: *Self) void {
    self.brush.deinit();
}
