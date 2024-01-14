const std = @import("std");
const print = std.debug.print;
const ray = @cImport(@cInclude("raylib.h"));
const raygui = @cImport(@cInclude("raygui.h"));
const gui = @import("gui/mod.zig");

const ArrayVec = std.ArrayList(ray.Vector2);
const Canvas = std.AutoHashMap(struct { x: c_int, y: c_int }, struct { color: ray.Color });
const PixelBuffer = std.AutoHashMap(struct { x: c_int, y: c_int }, void);
const ByteArray = std.ArrayList(u8);

const Mode = enum {
    Draw,
    DrawLine,
    Erase,
    Fill,
};

const AppContext = struct {
    brush_size: c_int = 1,
    color: ray.Color = ray.DARKGRAY,
    erase_color: ray.Color = ray.WHITE,
    is_drawing: bool = false,
    mode: Mode = Mode.Draw,
    zoom_level: c_int = 10,
    canvas_width: c_int = 64,
    canvas_height: c_int = 64,
    last_pixel: struct { x: c_int, y: c_int } = .{ .x = 0, .y = 0 },
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize Canvas
    var canvas = Canvas.init(allocator);
    defer canvas.deinit();
    var pixel_buffer = PixelBuffer.init(allocator);
    defer pixel_buffer.deinit();

    // Initialize variables
    var ctx = AppContext{};

    // Initialize ray
    ray.InitWindow(0, 0, "pixel edit");
    defer ray.CloseWindow();
    ray.HideCursor();
    // const monitor = ray.GetCurrentMonitor();
    // const screen_width = ray.GetMonitorWidth(monitor);
    // const screen_height = ray.GetMonitorHeight(monitor);

    const save_texture = ray.LoadTexture("save_icon.png");
    defer ray.UnloadTexture(save_texture);

    // Initialize GUI
    var button_y: f32 = 0;
    var button_save = gui.Button{
        .text = "Save",
        .position = .{ .x = 0, .y = button_y },
        .texture = save_texture,
    };
    button_y += button_save.height();

    const eraser_texture = ray.LoadTexture("eraser_icon.png");
    defer ray.UnloadTexture(eraser_texture);

    var button_eraser = gui.Button{
        .text = "Eraser",
        .position = .{ .x = 0, .y = button_y },
        .texture = eraser_texture,
    };
    button_y += button_eraser.height();

    const pencil_texture = ray.LoadTexture("pencil_icon.png");
    defer ray.UnloadTexture(pencil_texture);

    var button_pencil = gui.Button{
        .text = "Pencil",
        .position = .{ .x = 0, .y = button_y },
        .texture = pencil_texture,
    };
    button_y += button_pencil.height();

    const bucket_texture = ray.LoadTexture("bucket_icon.png");
    defer ray.UnloadTexture(bucket_texture);

    var button_bucket = gui.Button{
        .text = "Fill",
        .position = .{ .x = 0, .y = button_y },
        .texture = bucket_texture,
    };
    button_y += button_bucket.height();

    const colors = [_]ray.Color{ ray.RED, ray.GREEN, ray.BLUE, ray.DARKBLUE, ray.MAGENTA, ray.YELLOW };
    var color_pallet = gui.ColorPallet{
        .position = .{ .x = 0, .y = button_y },
        .colors = try allocator.dupe(ray.Color, &colors),
    };
    defer allocator.free(color_pallet.colors);
    button_y += color_pallet.height();

    const gui_max_width = @as(c_int, @intFromFloat(button_save.width()));
    const canvas_x = (ctx.zoom_level - @mod(gui_max_width, ctx.zoom_level)) + gui_max_width;
    const canvas_y = ctx.zoom_level * 2;

    ray.SetTargetFPS(60);
    while (!ray.WindowShouldClose()) {
        const is_mouse_on_canvas = mouse_is_in_canvas(canvas_x, canvas_y, ctx.canvas_width * ctx.zoom_level, ctx.canvas_height * ctx.zoom_level);
        // Update
        //----------------------------------------------------------------------------------

        // seems a bit dangerous without a undo button

        const mouse_wheel = ray.GetMouseWheelMove();
        const is_ctrl_pressed = ray.IsKeyDown(ray.KEY_LEFT_CONTROL) or ray.IsKeyDown(ray.KEY_RIGHT_CONTROL);

        if (is_ctrl_pressed and ray.IsKeyReleased(ray.KEY_R)) {
            canvas.clearRetainingCapacity();
        }

        if (is_ctrl_pressed and mouse_wheel > 0) {
            ctx.brush_size += 1;
        }

        if (is_ctrl_pressed and mouse_wheel < 0 and ctx.brush_size > 1) {
            ctx.brush_size -= 1;
        }

        if (ray.IsKeyDown(ray.KEY_LEFT_SHIFT) and is_mouse_on_canvas) {
            const pos = fix_point_to_grid(c_int, ctx.zoom_level, ray.GetMousePosition());
            const grid_x = pos.x - canvas_x;
            const grid_y = pos.y - canvas_y;
            const x = @divTrunc(grid_x, ctx.zoom_level);
            const y = @divTrunc(grid_y, ctx.zoom_level);
            try bresenham_line(ctx.last_pixel.x, ctx.last_pixel.y, x, y, &pixel_buffer);
            ctx.mode = Mode.DrawLine;
        }

        if (ray.IsMouseButtonPressed(ray.MOUSE_LEFT_BUTTON)) {
            ctx.is_drawing = true;
        }

        if (ray.IsMouseButtonReleased(ray.MOUSE_LEFT_BUTTON)) {
            ctx.is_drawing = false;
        }

        if (ctx.is_drawing and is_mouse_on_canvas) {
            const pos = fix_point_to_grid(c_int, ctx.zoom_level, ray.GetMousePosition());
            const grid_x = pos.x - canvas_x;
            const grid_y = pos.y - canvas_y;
            const x = @divTrunc(grid_x, ctx.zoom_level);
            const y = @divTrunc(grid_y, ctx.zoom_level);
            ctx.last_pixel = .{ .x = x, .y = y };
            switch (ctx.mode) {
                Mode.Draw => {
                    try canvas.put(.{
                        .x = x,
                        .y = y,
                    }, .{ .color = ctx.color });
                },
                Mode.DrawLine => {
                    var iter = pixel_buffer.iterator();
                    while (iter.next()) |pixel| {
                        try canvas.put(.{
                            .x = pixel.key_ptr.x,
                            .y = pixel.key_ptr.y,
                        }, .{ .color = ctx.color });
                    }
                    ctx.mode = Mode.Draw;
                },
                Mode.Erase => {
                    _ = canvas.remove(.{ .x = x, .y = y });
                },
                Mode.Fill => {},
            }
        }

        if (button_save.update()) {
            save(&canvas, ctx.canvas_width, ctx.canvas_height);
        }

        if (button_eraser.update()) {
            ctx.mode = Mode.Erase;
        }

        if (button_pencil.update()) {
            ctx.mode = Mode.Draw;
        }

        if (button_bucket.update()) {
            ctx.mode = Mode.Fill;
        }

        // color pallet
        if (color_pallet.update()) |index| {
            print("color index: {}\n", .{index});
            ctx.color = color_pallet.colors[index];
        }

        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        ray.BeginDrawing();
        ray.ClearBackground(ray.Color{ .r = 140, .g = 140, .b = 140, .a = 255 });
        // Canva Background
        // zig fmt: off
        ray.DrawRectangle(
            canvas_x,
            canvas_y,
            ctx.canvas_width * ctx.zoom_level,
            ctx.canvas_height * ctx.zoom_level,
            ray.RAYWHITE
        );
        const mouse = ray.GetMousePosition();

        // Canvas
        {
            var iter = canvas.iterator();
            while (iter.next()) |pixel| {
                // zig fmt: off
                const pos = fix_point_to_grid(
                    c_int,
                    ctx.zoom_level,
                    .{
                        .x = @as(f32, @floatFromInt(pixel.key_ptr.x * ctx.zoom_level)),
                        .y = @as(f32, @floatFromInt(pixel.key_ptr.y * ctx.zoom_level)),
                    }
                );
                // zig fmt: off
                ray.DrawRectangleV(
                    .{
                        .x = @as(f32, @floatFromInt(pos.x + canvas_x)),
                        .y = @as(f32, @floatFromInt(pos.y + canvas_y))
                    },
                    .{
                        .x = @as(f32, @floatFromInt(ctx.zoom_level)),
                        .y = @as(f32, @floatFromInt(ctx.zoom_level))
                    },
                    pixel.value_ptr.color
                );
            }
        }

        {
            var iter = pixel_buffer.iterator();
            while (iter.next()) |pixel| {
                // zig fmt: off
                const pos = fix_point_to_grid(
                    c_int,
                    ctx.zoom_level,
                    .{
                        .x = @as(f32, @floatFromInt(pixel.key_ptr.x * ctx.zoom_level)),
                        .y = @as(f32, @floatFromInt(pixel.key_ptr.y * ctx.zoom_level)),
                    }
                );
                // zig fmt: off
                ray.DrawRectangleV(
                    .{
                        .x = @as(f32, @floatFromInt(pos.x + canvas_x)),
                        .y = @as(f32, @floatFromInt(pos.y + canvas_y))
                    },
                    .{
                        .x = @as(f32, @floatFromInt(ctx.zoom_level)),
                        .y = @as(f32, @floatFromInt(ctx.zoom_level))
                    },
                    ctx.color
                );
            }
            pixel_buffer.clearRetainingCapacity();
        }

        // GUI
        button_save.draw();
        button_eraser.draw();
        button_pencil.draw();
        button_bucket.draw();
        color_pallet.draw();

        // Brush
        const pos = fix_point_to_grid(c_int, ctx.zoom_level, mouse);
        const color = if (ctx.mode == Mode.Draw) ctx.color else ctx.erase_color;
        if (is_mouse_on_canvas) {
            ray.HideCursor();
            ray.DrawRectangle(pos.x, pos.y, ctx.zoom_level, ctx.zoom_level, color);
            const texture = switch (ctx.mode) {
                Mode.Erase => eraser_texture,
                Mode.Fill => bucket_texture,
                else => pencil_texture,
            };
            const x: c_int = @intFromFloat(mouse.x);
            const y: c_int = @as(c_int, @intFromFloat(mouse.y)) - texture.height;
            ray.DrawTexture(texture, x, y, ray.WHITE);
        } else {
            ray.ShowCursor();
        }


        ray.EndDrawing();
        //----------------------------------------------------------------------------------
    }
    ray.ShowCursor();
}

fn fix_point_to_grid(comptime T: type, zoom_level: c_int, pos: ray.Vector2) struct { x: T, y: T } {
    const zoom = @as(f32, @floatFromInt(zoom_level));
    if (@typeInfo(T) == .Int) {
        const x = @as(T, @intFromFloat(@divFloor(pos.x, zoom) * zoom));
        const y = @as(T, @intFromFloat(@divFloor(pos.y, zoom) * zoom));
        return .{ .x = x, .y = y };
    }
    const x = @as(T, @floatFromInt(@divFloor(pos.x, zoom) * zoom));
    const y = @as(T, @floatFromInt(@divFloor(pos.y, zoom) * zoom));
    return .{ .x = x, .y = y };
}

fn asF32(x: c_int) f32 {
    return @as(f32, @floatFromInt(x));
}

fn mouse_is_in_canvas(left: c_int, top: c_int, width: c_int, height: c_int) bool {
    const pos = ray.GetMousePosition();
    return ray.CheckCollisionPointRec(pos, ray.Rectangle{ .x = asF32(left), .y = asF32(top), .width = asF32(width), .height = asF32(height) });
}

fn save(canvas: *Canvas, screen_width: c_int, screen_height: c_int) void {
    const target = ray.LoadRenderTexture(screen_width, screen_height);
    defer ray.UnloadTexture(target.texture);

    ray.BeginTextureMode(target);

    var iter_canvas = canvas.iterator();
    while (iter_canvas.next()) |pixel| {
        // zig fmt: off
        ray.DrawPixel(
            @intCast(pixel.key_ptr.x),
            @intCast(pixel.key_ptr.y),
            pixel.value_ptr.color
        );
    }

    ray.EndTextureMode();
    var image = ray.LoadImageFromTexture(target.texture);
    ray.ImageFlipVertical(&image);
    _ = ray.ExportImage(image, "red.png");
}

fn bresenham_line(xx1: c_int, yy1: c_int, x2: c_int, y2: c_int, out: *PixelBuffer) !void {
    var x1 = xx1;
    var y1 = yy1;
    const dx: c_int = @intCast(@abs(x2 - x1));
    const dy: c_int = @intCast(@abs(y2 - y1));

    const sx: c_int = if (x1 < x2) 1 else -1;
    const sy: c_int = if (y1 < y2)  1 else -1;
    var err: c_int = dx - dy;


    while (true) {
        try out.*.put(.{ .x = x1, .y = y1 }, {});

        if (x1 == x2 and y1 == y2) break;

        const e2 = 2 * err;

        if (e2 > -dy) {
            err -= dy;
            x1 += sx;
        }

        if (e2 < dx) {
            err += dx;
            y1 += sy;
        }
    }
}
