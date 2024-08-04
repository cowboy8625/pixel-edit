const rl = @import("raylib");

pub const CROSS_HAIRS_ICON = @embedFile("assets/cross-hairs-icon.png");
pub const GRID_ICON = @embedFile("assets/grid-icon.png");
pub const MENU_ICON = @embedFile("assets/menu-icon.png");
pub const SAVE_ICON = @embedFile("assets/save-icon.png");
pub const COLOR_PICKER_ICON = @embedFile("assets/color-picker-icon.png");
pub const LINE_TOOL_ICON = @embedFile("assets/line-tool-icon.png");

pub fn loadTexture(data: []const u8) rl.Texture2D {
    const image = rl.loadImageFromMemory(".png", data);
    defer rl.unloadImage(image);
    return rl.loadTextureFromImage(image);
}
