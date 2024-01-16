const std = @import("std");
const button = @import("button.zig");
const ray = @cImport(@cInclude("raylib.h"));

pub fn fileDialong(background: *const ray.Texture2D) void {
    while (!ray.WindowShouldClose()) {
        update();
        draw(background);
    }
}

fn update() void {}

fn draw(background: *const ray.Texture2D) void {
    const rect = ray.Rectangle{
        .x = 0,
        .y = 0,
        .width = 200,
        .height = 200,
    };
    ray.BeginDrawing();
    ray.ClearBackground(ray.WHITE);
    ray.DrawTexture(background, 0, 0, ray.WHITE);
    ray.DrawRectangleRounded(rect, 1.0, 4, ray.RED);
    ray.EndDrawing();
}
