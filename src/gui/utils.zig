const ray = @cImport(@cInclude("raylib.h"));

pub fn drawTexture(
    target: *const ray.Texture2D,
    x_int: c_int,
    y_int: c_int,
    opacity: u8,
) void {
    const width: f32 = @floatFromInt(target.width);
    const height: f32 = @floatFromInt(target.height);
    const rect = ray.Rectangle{
        .x = 0,
        .y = 0,
        .width = width,
        .height = -height,
    };
    const x: f32 = @floatFromInt(x_int);
    const y: f32 = @floatFromInt(y_int);
    const origin = ray.Vector2{ .x = x, .y = y };
    ray.DrawTextureRec(target.*, rect, origin, ray.Color{ .r = 255, .g = 255, .b = 255, .a = opacity });
}
