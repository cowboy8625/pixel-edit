const std = @import("std");
const print = std.debug.print;
const raylib = @cImport(@cInclude("raylib.h"));
const raygui = @cImport(@cInclude("raygui.h"));

const ArrayVec = std.ArrayList(raylib.Vector2);
const Canvas = std.AutoHashMap(struct { x: usize, y: usize }, void);
const ByteArray = std.ArrayList(u8);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var canvas = Canvas.init(std.heap.page_allocator);
    defer canvas.deinit();
    var queue = ArrayVec.init(std.heap.page_allocator);
    defer queue.deinit();
    const bush_size = 32;

    var drawing = false;

    raylib.InitWindow(0, 0, "pixel edit");
    defer raylib.CloseWindow();
    const monitor = raylib.GetCurrentMonitor();
    const screen_width = raylib.GetMonitorWidth(monitor);
    const screen_height = raylib.GetMonitorHeight(monitor);

    raylib.SetTargetFPS(60);
    while (!raylib.WindowShouldClose()) {
        // Update
        //----------------------------------------------------------------------------------
        var bush_size_text = try std.fmt.allocPrint(allocator, "BRUSH SIZE: {d}", .{bush_size});
        defer allocator.free(bush_size_text);

        if (raylib.IsKeyDown(raylib.KEY_LEFT_CONTROL) and raylib.IsKeyReleased(raylib.KEY_S)) {
            save(&canvas, screen_width, screen_height, bush_size);
        }

        if (raylib.IsMouseButtonPressed(raylib.MOUSE_LEFT_BUTTON)) {
            drawing = true;
        }

        if (raylib.IsMouseButtonReleased(raylib.MOUSE_LEFT_BUTTON)) {
            drawing = false;
        }

        if (drawing) {
            var mouse_position = raylib.GetMousePosition();
            mouse_position.x = @divFloor(mouse_position.x, bush_size) * bush_size;
            mouse_position.y = @divFloor(mouse_position.y, bush_size) * bush_size;
            try queue.append(mouse_position);
            try canvas.put(.{ .x = @as(usize, @intFromFloat(mouse_position.x)), .y = @as(usize, @intFromFloat(mouse_position.y)) }, {});
        }

        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.RAYWHITE);

        raylib.DrawText(@as([*:0]u8, @ptrCast(&bush_size_text)), 10, 10, 40, raylib.BLACK);

        for (queue.items) |position| {
            raylib.DrawRectangleV(position, .{ .x = bush_size, .y = bush_size }, raylib.DARKGRAY);
        }

        raylib.EndDrawing();
        //----------------------------------------------------------------------------------
    }
}

fn save(canvas: *Canvas, screen_width: c_int, screen_height: c_int, bush_size: c_int) void {
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
                .width = @floatFromInt(bush_size),
                .height = @floatFromInt(bush_size)
            },
            raylib.DARKGRAY
        );
    }

    raylib.EndTextureMode();
    var image = raylib.LoadImageFromTexture(target.texture);
    raylib.ImageFlipVertical(&image);
    _ = raylib.ExportImage(image, "red.png");
}
