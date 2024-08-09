const rl = @import("raylib");

pub const CROSS_HAIRS_ICON = @embedFile("assets/cross-hairs-icon.png");
pub const GRID_ICON = @embedFile("assets/grid-icon.png");
pub const MENU_ICON = @embedFile("assets/menu-icon.png");
pub const SAVE_ICON = @embedFile("assets/save-icon.png");
pub const COLOR_PICKER_ICON = @embedFile("assets/color-picker-icon.png");
pub const COLOR_WHEEL_ICON = @embedFile("assets/color-wheel-icon.png");
pub const LINE_TOOL_ICON = @embedFile("assets/line-icon.png");
pub const BUCKET_TOOL_ICON = @embedFile("assets/bucket-icon.png");
pub const PENCIL_TOOL_ICON = @embedFile("assets/pencil-icon.png");
pub const LOAD_ICON = @embedFile("assets/load-icon.png");
pub const ERASER_TOOL_ICON = @embedFile("assets/eraser-icon.png");
pub const PLAY_ICON = @embedFile("assets/play-icon.png");
pub const RIGHT_ARROW_ICON = @embedFile("assets/right-arrow-icon.png");
pub const LEFT_ARROW_ICON = @embedFile("assets/left-arrow-icon.png");
pub const ROTATE_RIGHT_ICON = @embedFile("assets/rotate-right-icon.png");
pub const ROTATE_LEFT_ICON = @embedFile("assets/rotate-left-icon.png");
pub const FLIP_VERTICAL_ICON = @embedFile("assets/flip-vertical-icon.png");
pub const FLIP_HORIZONTAL_ICON = @embedFile("assets/flip-horizontal-icon.png");

pub fn loadTexture(data: []const u8) rl.Texture2D {
    const image = rl.loadImageFromMemory(".png", data);
    defer rl.unloadImage(image);
    return rl.loadTextureFromImage(image);
}
