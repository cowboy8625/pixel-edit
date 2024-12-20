const rl = @import("raylib");
const utils = @import("utils.zig");
const cast = utils.cast;
const Vector2 = @import("Vector2.zig").Vector2;
const Rectangle = @import("Rectangle.zig").Rectangle;

pub const Camera2D = rl.Camera2D;
pub const Color = rl.Color;
pub const Texture2D = rl.Texture2D;
pub const Image = rl.Image;
pub const Font = rl.Font;

// ------- START DEBUG IMPORTS ------
pub const TraceLogLevel = rl.TraceLogLevel;
pub const traceLog = rl.traceLog;
// -------- END DEBUG IMPORTS -------

pub fn getScreenToWorld2D(pos: Vector2(f32), camera: Camera2D) Vector2(f32) {
    const world_pos = rl.getScreenToWorld2D(pos.as(rl.Vector2), camera);
    return .{ .x = world_pos.x, .y = world_pos.y };
}

pub const getCharPressed = rl.getCharPressed;
pub const imageDrawPixel = rl.imageDrawPixel;
pub const genImageColor = rl.genImageColor;
pub const loadRenderTexture = rl.loadRenderTexture;
pub const loadTexture = rl.loadTexture;
pub const loadTextureFromImage = rl.loadTextureFromImage;
pub const loadImageFromMemory = rl.loadImageFromMemory;

pub const textFormat = rl.textFormat;
pub const getFontDefault = rl.getFontDefault;

pub fn measureText(text: []const u8, font_size: i32) i32 {
    const ctext: [*:0]const u8 = @ptrCast(text);
    return rl.measureText(ctext, font_size);
}

pub fn measureTextEx(font: Font, text: []const u8, font_size: f32, spacing: f32) Vector2(f32) {
    const ctext: [*:0]const u8 = @ptrCast(text);
    const result = rl.measureTextEx(font, ctext, font_size, spacing);
    return Vector2(f32).fromRaylibVector2(result);
}

pub fn checkCollisionPointRec(point: Vector2(f32), rec: Rectangle(f32)) bool {
    return rl.checkCollisionPointRec(point.as(rl.Vector2), rec.as(rl.Rectangle));
}

pub fn checkCollisionRecs(rect1: Rectangle(f32), rect2: Rectangle(f32)) bool {
    return rl.checkCollisionRecs(rect1.as(rl.Rectangle), rect2.as(rl.Rectangle));
}

pub fn getCollisionRec(rect1: Rectangle(f32), rect2: Rectangle(f32)) Rectangle(f32) {
    const rect = rl.getCollisionRec(rect1.as(rl.Rectangle), rect2.as(rl.Rectangle));
    return .{ .x = rect.x, .y = rect.y, .width = rect.width, .height = rect.height };
}

pub const initWindow = rl.initWindow;
pub const closeWindow = rl.closeWindow;
pub const windowShouldClose = rl.windowShouldClose;
pub const setTargetFPS = rl.setTargetFPS;
pub const getScreenWidth = rl.getScreenWidth;
pub const getScreenHeight = rl.getScreenHeight;

pub const getFrameTime = rl.getFrameTime;

pub const getImageColor = rl.getImageColor;

pub const clearBackground = rl.clearBackground;
pub const beginMode2D = rl.beginMode2D;
pub const endMode2D = rl.endMode2D;
pub const beginDrawing = rl.beginDrawing;
pub const endDrawing = rl.endDrawing;
pub const beginTextureMode = rl.beginTextureMode;
pub const endTextureMode = rl.endTextureMode;
pub const unloadRenderTexture = rl.unloadRenderTexture;

pub const drawFPS = rl.drawFPS;
pub const drawTexture = rl.drawTexture;

pub fn drawTextureEx(texture: Texture2D, position: Vector2(f32), rotation: f32, scale: f32, tint: Color) void {
    rl.drawTextureEx(texture, position.as(rl.Vector2), rotation, scale, tint);
}

pub fn drawLineV(pos1: Vector2(f32), pos2: Vector2(f32), color: Color) void {
    rl.drawLineV(pos1.as(rl.Vector2), pos2.as(rl.Vector2), color);
}

pub fn drawCircleV(pos: Vector2(f32), radius: f32, color: Color) void {
    rl.drawCircleV(pos.as(rl.Vector2), radius, color);
}

pub fn drawRectangleV(position: Vector2(f32), size: Vector2(f32), color: Color) void {
    rl.drawRectangleV(position.as(rl.Vector2), size.as(rl.Vector2), color);
}

pub fn drawRectangleRec(rect: Rectangle(f32), color: Color) void {
    rl.drawRectangleRec(rect.as(rl.Rectangle), color);
}

pub const drawRectangleLines = rl.drawRectangleLines;
pub fn drawRectangleLinesEx(rect: Rectangle(f32), thick: f32, color: Color) void {
    rl.drawRectangleLinesEx(rect.as(rl.Rectangle), thick, color);
}

pub fn drawRectangleRounded(rect: Rectangle(f32), roundness: f32, segments: i32, color: Color) void {
    rl.drawRectangleRounded(rect.as(rl.Rectangle), roundness, segments, color);
}

pub fn drawRectangleRoundedLines(rec: Rectangle(f32), roundness: f32, segments: i32, color: Color) void {
    rl.drawRectangleRoundedLines(rec.as(rl.Rectangle), roundness, segments, color);
}

pub fn drawRectangleRoundedLinesEx(rec: Rectangle(f32), roundness: f32, segments: i32, lineThick: f32, color: Color) void {
    rl.drawRectangleRoundedLinesEx(rec.as(rl.Rectangle), roundness, segments, lineThick, color);
}

pub fn drawTexturePro(texture: Texture2D, source: Rectangle(f32), dest: Rectangle(f32), origin: Vector2(f32), rotation: f32, tint: Color) void {
    rl.drawTexturePro(texture, source.as(rl.Rectangle), dest.as(rl.Rectangle), origin.as(rl.Vector2), rotation, tint);
}

pub const drawTextZ = rl.drawText;

pub fn drawText(text: []const u8, x: i32, y: i32, font_size: i32, color: Color) void {
    const ctext: [*:0]const u8 = @ptrCast(text);
    rl.drawText(ctext, x, y, font_size, color);
}

pub const drawPixel = rl.drawPixel;

pub fn drawTextEx(
    font: Font,
    text: []const u8,
    position: Vector2(f32),
    font_size: f32,
    spacing: f32,
    tint: Color,
) void {
    const ctext: [*:0]const u8 = @ptrCast(text);
    rl.drawTextEx(font, ctext, position.as(rl.Vector2), font_size, spacing, tint);
}

pub const KeyboardKey = rl.KeyboardKey;
pub const isKeyPressed = rl.isKeyPressed;
pub const isKeyReleased = rl.isKeyReleased;
pub const isKeyDown = rl.isKeyDown;

pub const MouseButton = rl.MouseButton;

pub fn getMousePosition() Vector2(f32) {
    return Vector2(f32).fromRaylibVector2(rl.getMousePosition());
}

pub fn getMouseWheelMoveV() Vector2(f32) {
    return Vector2(f32).fromRaylibVector2(rl.getMouseWheelMoveV());
}

pub const isMouseButtonPressed = rl.isMouseButtonPressed;
pub const isMouseButtonDown = rl.isMouseButtonDown;

pub fn centerScreen() Vector2(f32) {
    return .{ .x = cast(f32, rl.getScreenWidth()) / 2, .y = cast(f32, rl.getScreenHeight()) / 2 };
}

pub const genImagePerlinNoise = rl.genImagePerlinNoise;
pub const unloadImage = rl.unloadImage;
pub const unloadTexture = rl.unloadTexture;
