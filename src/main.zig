const std = @import("std");
const print = std.debug.print;
const raylib = @cImport(@cInclude("raylib.h"));
const raygui = @cImport(@cInclude("raygui.h"));
const gui = @import("gui/button.zig");

const ArrayVec = std.ArrayList(raylib.Vector2);
const Canvas = std.AutoHashMap(struct { x: usize, y: usize }, struct { color: raylib.Color, brush_size: c_int });
const ByteArray = std.ArrayList(u8);

const Mode = enum {
    Draw,
    Erase,
};

const AppContext = struct {
    brush_size: c_int = 32,
    color: raylib.Color = raylib.DARKGRAY,
    erase_color: raylib.Color = raylib.WHITE,
    is_drawing: bool = false,
    mode: Mode = Mode.Draw,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    _ = allocator;

    // Initialize Canvas
    var canvas = Canvas.init(std.heap.page_allocator);
    defer canvas.deinit();
    var drawing = false;
    _ = drawing;

    // Initialize variables
    // Move this into a struct at some point
    var ctx = AppContext{};

    // Initialize Raylib
    raylib.InitWindow(0, 0, "pixel edit");
    defer raylib.CloseWindow();
    const monitor = raylib.GetCurrentMonitor();
    const screen_width = raylib.GetMonitorWidth(monitor);
    const screen_height = raylib.GetMonitorHeight(monitor);

    // Initialize GUI
    var button_save = gui.Button{
        .text = "Save",
        .position = .{ .x = 0, .y = 0 },
    };

    var button_eraser = gui.Button{
        .text = "Eraser",
        .position = .{ .x = 0, .y = button_save.height() },
    };

    var button_pincel = gui.Button{
        .text = "Pincel",
        .position = .{ .x = 0, .y = button_save.height() + button_eraser.height() },
    };

    raylib.SetTargetFPS(60);
    while (!raylib.WindowShouldClose()) {
        // Update
        //----------------------------------------------------------------------------------

        // seems a bit dangerous without a undo button
        // if (raylib.IsKeyReleased(raylib.KEY_R)) {
        //     canvas.clearRetainingCapacity();
        // }

        const mouse_wheel = raylib.GetMouseWheelMove();
        const is_ctrl_pressed = true; // raylib.IsKeyDown(raylib.KEY_LEFT_CONTROL) or raylib.IsKeyDown(raylib.KEY_RIGHT_CONTROL);
        if (is_ctrl_pressed and mouse_wheel > 0) {
            print("middle button up\n", .{});
            ctx.brush_size += 32;
        }

        if (is_ctrl_pressed and mouse_wheel < 0 and ctx.brush_size > 32) {
            print("middle button down\n", .{});
            ctx.brush_size -= 32;
        }

        if (raylib.IsMouseButtonPressed(raylib.MOUSE_LEFT_BUTTON)) {
            ctx.is_drawing = true;
        }

        if (raylib.IsMouseButtonReleased(raylib.MOUSE_LEFT_BUTTON)) {
            ctx.is_drawing = false;
        }

        if (ctx.is_drawing) {
            const pos = normalize_mouse(usize, ctx.brush_size);
            switch (ctx.mode) {
                Mode.Draw => {
                    try canvas.put(.{ .x = pos.x, .y = pos.y }, .{ .color = ctx.color, .brush_size = ctx.brush_size });
                },
                Mode.Erase => {
                    _ = canvas.remove(.{ .x = pos.x, .y = pos.y });
                },
            }
        }

        if (button_save.update()) {
            save(&canvas, screen_width, screen_height);
        }

        if (button_eraser.update()) {
            ctx.mode = Mode.Erase;
        }

        if (button_pincel.update()) {
            ctx.mode = Mode.Draw;
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
                    .x = @as(f32, @floatFromInt(pixel.value_ptr.brush_size)),
                    .y = @as(f32, @floatFromInt(pixel.value_ptr.brush_size))
                },
                pixel.value_ptr.color
            );
        }
        // Brush
        const pos = normalize_mouse(c_int, ctx.brush_size);
        const color = if (ctx.mode == Mode.Draw) ctx.color else ctx.erase_color;
        raylib.DrawRectangle(pos.x, pos.y, ctx.brush_size, ctx.brush_size, color);

        // GUI
        button_save.draw();
        button_eraser.draw();
        button_pincel.draw();

        raylib.EndDrawing();
        //----------------------------------------------------------------------------------
    }
}

fn normalize_mouse(comptime T: type, brush_size: c_int) struct { x: T, y: T } {
    const bsize = @as(f32, @floatFromInt(brush_size));
    var mouse_position = raylib.GetMousePosition();
    if (@typeInfo(T) == .Int) {
        const x = @as(T, @intFromFloat(@divFloor(mouse_position.x, bsize) * bsize));
        const y = @as(T, @intFromFloat(@divFloor(mouse_position.y, bsize) * bsize));
        return .{ .x = x, .y = y };
    }
    const x = @as(T, @floatFromInt(@divFloor(mouse_position.x, bsize) * bsize));
    const y = @as(T, @floatFromInt(@divFloor(mouse_position.y, bsize) * bsize));
    return .{ .x = x, .y = y };
}

fn save(canvas: *Canvas, screen_width: c_int, screen_height: c_int) void {
    const target = raylib.LoadRenderTexture(screen_width, screen_height);
    defer raylib.UnloadTexture(target.texture);

    raylib.BeginTextureMode(target);

    var iter_canvas = canvas.iterator();
    while (iter_canvas.next()) |pixel| {
        // zig fmt: off
        raylib.DrawRectangleRec(
            raylib.Rectangle{
                .x = @floatFromInt(pixel.key_ptr.x),
                .y = @floatFromInt(pixel.key_ptr.y),
                .width = @floatFromInt(pixel.value_ptr.brush_size),
                .height = @floatFromInt(pixel.value_ptr.brush_size)
            },
            pixel.value_ptr.color
        );
    }

    raylib.EndTextureMode();
    var image = raylib.LoadImageFromTexture(target.texture);
    raylib.ImageFlipVertical(&image);
    _ = raylib.ExportImage(image, "red.png");
}
