const rl = @import("raylib");
const Brush = @import("Brush.zig");

pub const Commands = enum {
    OpenMenu,
    CloseMenu,
    FrameRight,
    FrameLeft,
    Play,
    Stop,
    OpenColorPicker,
    CloseColorPicker,
    OpenSaveFileManager,
    OpenLoadFileManager,
    CloseSaveFileManager,
    CloseLoadFileManager,
    TurnGridOn,
    TurnGridOff,
    RotateLeft,
    RotateRight,
    FlipHorizontal,
    FlipVertical,
    IntoFrames,
};

const Self = @This();

const Flags = packed struct {
    draw_grid: bool = false,
    save_file_manager_is_open: bool = false,
    load_file_manager_is_open: bool = false,
    color_picker_is_open: bool = false,
    menu_is_open: bool = false,
    gui_active: bool = false,
    debugging: bool = false,
};

flags: Flags = .{},

// DATA
frame_opacity: u8 = 255,
path: ?[]const u8 = null,
path_action: enum { Save, Load } = .Save,
last_cell_position: rl.Vector2 = .{ .x = 0, .y = 0 },
brush: Brush,
command: ?Commands = null,

// METHODS
pub fn init() Self {
    return .{
        .brush = Brush.init(),
    };
}
pub fn deinit(self: *Self) void {
    self.brush.deinit();
}
