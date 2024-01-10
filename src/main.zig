const std = @import("std");
const print = std.debug.print;
const raylib = @cImport(@cInclude("raylib.h"));
const raygui = @cImport(@cInclude("raygui.h"));
const gui = @import("gui/button.zig");

const ArrayVec = std.ArrayList(raylib.Vector2);
const Canvas = std.AutoHashMap(struct { x: usize, y: usize }, struct { color: raylib.Color });
const ByteArray = std.ArrayList(u8);

const Mode = enum {
    Draw,
    Erase,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    _ = allocator;
    var canvas = Canvas.init(std.heap.page_allocator);
    defer canvas.deinit();
    const brush_size = 32;
    var color = raylib.DARKGRAY;

    var drawing = false;
    var mode = Mode.Draw;

    raylib.InitWindow(0, 0, "pixel edit");
    defer raylib.CloseWindow();
    const monitor = raylib.GetCurrentMonitor();
    const screen_width = raylib.GetMonitorWidth(monitor);
    const screen_height = raylib.GetMonitorHeight(monitor);

    var button_save = gui.Button{
        .text = "Save",
        .position = .{ .x = 0, .y = 0 },
    };
    var button_eraser = gui.Button{
        .text = "Eraser",
        .position = .{ .x = 0, .y = button_save.height() },
    };

    raylib.SetTargetFPS(60);
    while (!raylib.WindowShouldClose()) {
        // Update
        //----------------------------------------------------------------------------------

        if (raylib.IsKeyReleased(raylib.KEY_R)) {
            canvas.clearRetainingCapacity();
        }
        if (raylib.IsMouseButtonPressed(raylib.MOUSE_LEFT_BUTTON)) {
            drawing = true;
        }

        if (raylib.IsMouseButtonReleased(raylib.MOUSE_LEFT_BUTTON)) {
            drawing = false;
        }

        if (drawing) {
            var mouse_position = raylib.GetMousePosition();
            const x = @divFloor(mouse_position.x, brush_size) * brush_size;
            const y = @divFloor(mouse_position.y, brush_size) * brush_size;
            mouse_position.x = x;
            mouse_position.y = y;
            switch (mode) {
                Mode.Draw => {
                    if (drawing) {
                        // zig fmt: off
                        try canvas.put(
                            .{
                                .x = @as(usize, @intFromFloat(x)),
                                .y = @as(usize, @intFromFloat(y)),
                            },
                            .{
                                .color = color
                            }
                        );
                    }
                },
                Mode.Erase => {
                    _ = canvas.remove(.{
                        .x = @as(usize, @intFromFloat(x)),
                        .y = @as(usize, @intFromFloat(y)),
                        });
                },
            }
        }

        if (button_save.update()) {
            save(&canvas, screen_width, screen_height, brush_size);
        }

        if (button_eraser.update()) {
            mode = Mode.Erase;
            color = raylib.WHITE;
        }

        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.RAYWHITE);


        // Canvas
        var iter = canvas.iterator();
        while (iter.next()) |pixel| {
            // zig fmt: off
            raylib.DrawRectangleV(
                .{
                    .x = @as(f32, @floatFromInt(pixel.key_ptr.x)),
                    .y = @as(f32, @floatFromInt(pixel.key_ptr.y))
                },
                .{
                    .x = brush_size,
                    .y = brush_size
                },
                pixel.value_ptr.color
            );
        }
        // Brush
        const x = @divFloor(raylib.GetMouseX(), brush_size) * brush_size;
        const y = @divFloor(raylib.GetMouseY(), brush_size) * brush_size;
        raylib.DrawRectangle(x, y, brush_size, brush_size, color);

        // GUI
        button_save.draw();
        button_eraser.draw();

        raylib.EndDrawing();
        //----------------------------------------------------------------------------------
    }
}

fn save(canvas: *Canvas, screen_width: c_int, screen_height: c_int, brush_size: c_int) void {
    const target = raylib.LoadRenderTexture(screen_width, screen_height);
    defer raylib.UnloadTexture(target.texture);

    raylib.BeginTextureMode(target);

    var iter_canvas = canvas.keyIterator();
    while (iter_canvas.next()) |pixel| {
        // zig fmt: off
        raylib.DrawRectangleRec(
            raylib.Rectangle{
                .x = @floatFromInt(pixel.x),
                .y = @floatFromInt(pixel.y),
                .width = @floatFromInt(brush_size),
                .height = @floatFromInt(brush_size)
            },
            raylib.DARKGRAY
        );
    }

    raylib.EndTextureMode();
    var image = raylib.LoadImageFromTexture(target.texture);
    raylib.ImageFlipVertical(&image);
    _ = raylib.ExportImage(image, "red.png");
}
