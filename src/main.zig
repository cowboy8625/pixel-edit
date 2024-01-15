const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const ray = @cImport(@cInclude("raylib.h"));
const raygui = @cImport(@cInclude("raygui.h"));
const gui = @import("gui/mod.zig");

const ArrayVec = std.ArrayList(ray.Vector2);
const Canvas = std.AutoHashMap(Pixel, struct { color: ray.Color });
const PixelBuffer = std.AutoHashMap(Pixel, void);

const Mode = enum {
    Draw,
    DrawLine,
    Erase,
    Fill,
};

const Pixel = struct {
    x: c_int,
    y: c_int,
};

const AppContext = struct {
    brush_size: c_int = 1,
    color: ray.Color = ray.DARKGRAY,
    erase_color: ray.Color = ray.WHITE,
    is_drawing: bool = false,
    mode: Mode = Mode.Draw,
    zoom_level: c_int = 10,
    canvas_width: c_int = 20,
    canvas_height: c_int = 20,
    last_pixel: Pixel = .{ .x = 0, .y = 0 },
};

const Textures = struct {
    const Self = @This();

    save_texture: ray.Texture2D,
    eraser_texture: ray.Texture2D,
    pencil_texture: ray.Texture2D,
    bucket_texture: ray.Texture2D,

    pub fn init() Self {
        return Self{
            .save_texture = ray.LoadTexture("save_icon.png"),
            .eraser_texture = ray.LoadTexture("eraser_icon.png"),
            .pencil_texture = ray.LoadTexture("pencil_icon.png"),
            .bucket_texture = ray.LoadTexture("bucket_icon.png"),
        };
    }

    pub fn deinit(self: Self) void {
        ray.UnloadTexture(self.save_texture);
        ray.UnloadTexture(self.eraser_texture);
        ray.UnloadTexture(self.pencil_texture);
        ray.UnloadTexture(self.bucket_texture);
    }

    pub fn len() usize {
        return @typeInfo(Self).Struct.fields.len;
    }
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
    ray.SetConfigFlags(ray.FLAG_WINDOW_RESIZABLE);
    ray.InitWindow(0, 0, "pixel edit");
    defer ray.CloseWindow();
    ray.HideCursor();
    const monitor = ray.GetCurrentMonitor();
    const screen_width = ray.GetMonitorWidth(monitor);
    const screen_height = ray.GetMonitorHeight(monitor);
    ray.SetWindowMinSize(400, 400);
    ray.SetWindowMaxSize(screen_width, screen_height);

    // Canvas Texture
    const canvasTexture = ray.LoadRenderTexture(ctx.canvas_width * ctx.zoom_level, ctx.canvas_height * ctx.zoom_level);
    defer ray.UnloadTexture(canvasTexture.texture);

    // Preview Texture
    const previewTexture = ray.LoadRenderTexture(ctx.canvas_width * ctx.zoom_level, ctx.canvas_height * ctx.zoom_level);
    defer ray.UnloadTexture(previewTexture.texture);

    const textures = Textures.init();
    defer textures.deinit();

    // Initialize GUI
    var button_y: f32 = 0;
    var button_save = gui.Button{
        .text = "Save",
        .position = .{ .x = 0, .y = button_y },
        .texture = textures.save_texture,
    };
    button_y += button_save.height();

    var button_eraser = gui.Button{
        .text = "Eraser",
        .position = .{ .x = 0, .y = button_y },
        .texture = textures.eraser_texture,
    };
    button_y += button_eraser.height();

    var button_pencil = gui.Button{
        .text = "Pencil",
        .position = .{ .x = 0, .y = button_y },
        .texture = textures.pencil_texture,
    };
    button_y += button_pencil.height();

    var button_bucket = gui.Button{
        .text = "Fill",
        .position = .{ .x = 0, .y = button_y },
        .texture = textures.bucket_texture,
    };
    button_y += button_bucket.height();

    const colors = [_]ray.Color{ ray.RED, ray.GREEN, ray.BLUE, ray.DARKBLUE, ray.MAGENTA, ray.YELLOW, ray.WHITE, ray.GRAY, ray.BLACK, ray.DARKGRAY };
    var color_pallet = try gui.ColorPallet.init(allocator, .{ .x = 0, .y = button_y }, &colors);
    defer color_pallet.deinit();
    button_y += color_pallet.height();

    const gui_max_width = @as(c_int, @intFromFloat(button_save.width()));
    const canvas_x = (ctx.zoom_level - @mod(gui_max_width, ctx.zoom_level)) + gui_max_width;
    const canvas_y = ctx.zoom_level * 2;

    ray.SetTargetFPS(60);
    while (!ray.WindowShouldClose()) {
        const is_mouse_on_canvas = mouseIsInCanvas(canvas_x, canvas_y, ctx.canvas_width * ctx.zoom_level, ctx.canvas_height * ctx.zoom_level);
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
            try bresenhamLine(ctx.last_pixel.x, ctx.last_pixel.y, x, y, &pixel_buffer);
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
                Mode.Fill => try fillTool(allocator, &canvas, &ctx, x, y),
            }
        }

        if (button_save.update()) {
            saveCanvasToPng(&canvas, ctx.canvas_width, ctx.canvas_height);
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
        if (try color_pallet.update()) |index| {
            const r = color_pallet.colors.items[index].r;
            const g = color_pallet.colors.items[index].g;
            const b = color_pallet.colors.items[index].b;
            const a = color_pallet.colors.items[index].a;
            ctx.color = ray.Color{ .r = r, .g = g, .b = b, .a = a };
        }

        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        ray.BeginDrawing();
        ray.ClearBackground(ray.Color{ .r = 140, .g = 140, .b = 140, .a = 255 });
        const mouse = ray.GetMousePosition();

        updateCanvasTexture(canvasTexture, &canvas, ctx.zoom_level);
        drawCanvasTexture(&canvasTexture.texture, canvas_x, canvas_y);
        updatePreviewTexture(previewTexture, &pixel_buffer, ctx.zoom_level, ctx.color);
        drawCanvasTexture(&previewTexture.texture, canvas_x, canvas_y);
        // GUI
        button_save.draw();
        button_eraser.draw();
        button_pencil.draw();
        button_bucket.draw();
        color_pallet.draw();
        drawSelectedTool(ctx.mode);

        // Brush
        drawBrush(&ctx, mouse, is_mouse_on_canvas, &textures);

        ray.EndDrawing();
        //----------------------------------------------------------------------------------
    }
    ray.ShowCursor();
}

fn updateCanvasTexture(target: ray.RenderTexture2D, canvas: *Canvas, zoom_level: c_int) void {
    ray.BeginTextureMode(target);
    ray.ClearBackground(ray.RAYWHITE);
    var iter = canvas.iterator();
    const zoom: f32 = @floatFromInt(zoom_level);
    while (iter.next()) |pixel| {
        // zig fmt: off
        const pos = fix_point_to_grid(
            c_int,
            zoom_level,
            .{
                .x = @as(f32, @floatFromInt(pixel.key_ptr.x * zoom_level)),
                .y = @as(f32, @floatFromInt(pixel.key_ptr.y * zoom_level)),
            }
        );
        const x: f32 = @floatFromInt(pos.x);
        const y: f32 = @floatFromInt(pos.y);
        const color = pixel.value_ptr.color;
        ray.DrawRectangleV(.{ .x = x, .y = y }, .{ .x = zoom, .y = zoom }, color);
    }
    ray.EndTextureMode();
}

fn drawCanvasTexture(
        target: *const ray.Texture2D,
        x_int: c_int,
        y_int: c_int,
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
    ray.DrawTextureRec(target.*, rect, origin, ray.WHITE);
}

// Function is very similar to updateCanvasTexture but it canvas is a PixelBuffer
// witch does have any value so its basicly a Set and the PixelBuffer is cleared
// after drawing
fn updatePreviewTexture(
        target: ray.RenderTexture2D,
        canvas: *PixelBuffer,
        zoom_level: c_int,
        current_color: ray.Color,
    ) void {
    ray.BeginTextureMode(target);
    ray.ClearBackground(ray.Color{ .r = 0, .g = 0, .b = 0, .a = 0 });
    var iter = canvas.iterator();
    const zoom: f32 = @floatFromInt(zoom_level);
    while (iter.next()) |pixel| {
        const pos = fix_point_to_grid(
            c_int,
            zoom_level,
            .{
                .x = @as(f32, @floatFromInt(pixel.key_ptr.x * zoom_level)),
                .y = @as(f32, @floatFromInt(pixel.key_ptr.y * zoom_level)),
            }
        );
        // zig fmt: off
        const x: f32 = @floatFromInt(pos.x);
        const y: f32 = @floatFromInt(pos.y);
        ray.DrawRectangleV(.{ .x = x, .y = y }, .{ .x = zoom, .y = zoom }, current_color);
    }
    ray.EndTextureMode();
    canvas.*.clearRetainingCapacity();
}

fn drawBrush(ctx: *const AppContext, mouse: ray.Vector2, is_mouse_on_canvas: bool, textures: *const Textures) void {
    const pos = fix_point_to_grid(c_int, ctx.zoom_level, mouse);
    const color = if (ctx.mode == Mode.Draw) ctx.color else ctx.erase_color;
    if (is_mouse_on_canvas) {
        ray.HideCursor();
        ray.DrawRectangle(pos.x, pos.y, ctx.zoom_level, ctx.zoom_level, color);
        const texture = switch (ctx.mode) {
            Mode.Erase => textures.eraser_texture,
            Mode.Fill => textures.bucket_texture,
            else => textures.pencil_texture,
        };
        const x: c_int = @intFromFloat(mouse.x);
        const y: c_int = @as(c_int, @intFromFloat(mouse.y)) - texture.height;
        ray.DrawTexture(texture, x, y, ray.BLACK);
    } else {
        ray.ShowCursor();
    }
}

fn drawSelectedTool(mode: Mode) void {
    const step: f32 = 64;
    const y = switch (mode) {
        Mode.Erase => step * 1,
        Mode.Draw => step * 2,
        Mode.Fill => step * 3,
        Mode.DrawLine => return,
    };
    const rect = ray.Rectangle{
        .x = 0,
        .y = y,
        .width = step,
        .height = step,

    };
    ray.DrawRectangleLinesEx(rect, 3, ray.BLACK);
}

fn fix_point_to_grid(comptime T: type, zoom_level: c_int, pos: ray.Vector2) Pixel {
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

fn mouseIsInCanvas(left: c_int, top: c_int, width: c_int, height: c_int) bool {
    const pos = ray.GetMousePosition();
    return ray.CheckCollisionPointRec(pos, ray.Rectangle{ .x = asF32(left), .y = asF32(top), .width = asF32(width), .height = asF32(height) });
}

fn saveCanvasToPng(
        canvas: *Canvas,
        screen_width: c_int,
        screen_height: c_int
    ) void {
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

fn bresenhamLine(xx1: c_int, yy1: c_int, x2: c_int, y2: c_int, out: *PixelBuffer) !void {
    var x1: c_int = xx1;
    var y1: c_int = yy1;
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

fn fillTool(alloc: Allocator, canvas: *Canvas, ctx: *AppContext, x: c_int, y: c_int) !void {

    var stack = std.ArrayList(Pixel).init(alloc);
    defer stack.deinit();

    // This is getting mutated some how??
    // HOOOOOOOWWWWWWWWWW??????????????
    const target_color =
        if (canvas.get(.{ .x = x, .y = y })) |value| value.color
        else ray.BLANK;
    // print("target: {}, {} == {}\n", .{x, y, target_color});
    const replacement_color = ctx.color;
    try stack.append(.{ .x = x, .y = y });

    while (stack.items.len > 0) {
        const pixel = stack.pop();
        const current_color =
            if (canvas.get(.{ .x = pixel.x, .y = pixel.y })) |value| value.color else ray.BLANK;

        // print("{}, {}, {} == {}\n", .{pixel.x, pixel.y, current_color, target_color});

        if ((0 <= pixel.x and pixel.x < ctx.canvas_width) and
            (0 <= pixel.y and pixel.y < ctx.canvas_height) and
            compareColors(current_color, target_color))
        {
            // print("{}, {} -- {}\n", .{pixel.x, pixel.y, replacement_color});
            try canvas.put(.{ .x = pixel.x, .y = pixel.y }, .{ .color = replacement_color });
            try stack.append(.{ .x = pixel.x + 1, .y = pixel.y    });
            try stack.append(.{ .x = pixel.x - 1, .y = pixel.y    });
            try stack.append(.{ .x = pixel.x    , .y = pixel.y + 1});
            try stack.append(.{ .x = pixel.x    , .y = pixel.y - 1});
        }
    }

    ctx.mode = Mode.Draw;
}


fn compareColors(c1: ray.Color, c2: ray.Color) bool {
    return c1.r == c2.r and c1.g == c2.g and c1.b == c2.b and c1.a == c2.a;
}
