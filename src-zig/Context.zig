const rl = @import("raylib");
const Brush = @import("Brush.zig");

pub const Mode = enum {
    Draw,
    Line,
    Fill,
};

const Self = @This();

const Flags = packed struct {
    draw_grid: bool = false,
    save_file_manager_is_open: bool = false,
    load_file_manager_is_open: bool = false,
    gui_active: bool = false,
    color_picker_is_open: bool = false,
};

flags: Flags = .{},

// DATA
path: ?[]const u8 = null,
path_action: enum { Save, Load } = .Save,
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
