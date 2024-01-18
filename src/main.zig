const std = @import("std");
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const ray = @cImport(@cInclude("raylib.h"));
const raygui = @cImport(@cInclude("raygui.h"));
const gui = @import("gui/mod.zig");
const nfd = @import("nfd");

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
    canvas_width: c_int = 64,
    canvas_height: c_int = 64,
    last_pixel: Pixel = .{ .x = 0, .y = 0 },
    playing: bool = false,
    canvas: CanvasManager,

    const Self = @This();

    pub fn init(alloc: Allocator) !Self {
        return Self{
            .canvas = try CanvasManager.init(alloc),
        };
    }

    pub fn deinit(self: *Self) void {
        self.canvas.deinit();
    }
};

const CanvasManager = struct {
    alloc: Allocator,
    index: usize = 0,
    frames: std.ArrayList(Canvas),
    opacity: u8 = 255,
    // TODO: layers will go here too

    const Self = @This();
    pub fn init(alloc: Allocator) !Self {
        var frames = try std.ArrayList(Canvas).initCapacity(alloc, 1);
        errdefer frames.deinit();
        var canvas = Canvas.init(alloc);
        errdefer canvas.deinit();
        try frames.append(canvas);
        return Self{
            .alloc = alloc,
            .frames = frames,
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.frames.items) |*frame| {
            frame.*.deinit();
        }
        self.frames.deinit();
    }

    pub fn current_frame(self: *const Self) c_int {
        return @intCast(self.index + 1);
    }

    pub fn len(self: *const Self) c_int {
        return @intCast(self.frames.items.len);
    }

    pub fn add_frame(self: *Self) !void {
        try self.frames.append(Canvas.init(self.alloc));
    }

    pub fn clear(self: *Self) void {
        self.frames.items[self.index].clearRetainingCapacity();
    }

    pub fn remove(self: *Self, pixel: Pixel) bool {
        return self.frames.items[self.index].remove(pixel);
    }

    pub fn getCurrent(self: *Self) *Canvas {
        return &self.frames.items[self.index];
    }

    pub fn getPreviousFrame(self: *Self) ?*Canvas {
        if (self.index == 0) return null;
        return &self.frames.items[self.index - 1];
    }

    pub fn next(self: *Self) void {
        self.index = (self.index + 1) % self.frames.items.len;
    }

    pub fn nextOrCreate(self: *Self) !void {
        if (self.index + 1 == self.frames.items.len) {
            const new_frame = Canvas.init(self.alloc);
            try self.frames.append(new_frame);
        }
        self.index += 1;
    }

    pub fn prev(self: *Self) void {
        if (self.index > 0) self.index -= 1;
    }

    pub fn put(self: *Self, pixel: Pixel, color: ray.Color) !void {
        try self.frames.items[self.index].put(pixel, .{ .color = color });
    }
};

const Textures = struct {
    const Self = @This();

    // TODO: make this generate at compile time?
    pub const TextureType = enum { Icon, File, Save, Eraser, Pencil, Bucket, Plus, Minus, Play };

    names: []const []const u8,

    items: std.ArrayList(ray.Texture2D),
    mod_times: std.ArrayList(c_long),

    pub fn init(alloc: Allocator, names: []const []const u8) !Self {
        var items = std.ArrayList(ray.Texture2D).init(alloc);
        errdefer items.deinit();
        var mod_times = std.ArrayList(c_long).init(alloc);
        errdefer mod_times.deinit();
        for (names) |name| {
            const c_name: [*c]u8 = @constCast(name.ptr);
            try items.append(ray.LoadTexture(c_name));
            const mod_time = ray.GetFileModTime(c_name);
            try mod_times.append(mod_time);
        }

        return Self{
            .items = items,
            .mod_times = mod_times,
            .names = names,
        };
    }

    pub fn deinit(self: Self) void {
        for (self.items.items) |item| {
            ray.UnloadTexture(item);
        }
        self.items.deinit();
        self.mod_times.deinit();
    }

    pub fn get(self: *const Self, textureType: Self.TextureType) ray.Texture2D {
        return self.items.items[@intFromEnum(textureType)];
    }

    pub fn getAsImage(self: *const Self, textureType: Self.TextureType) ray.Image {
        const texture = self.get(textureType);
        return ray.LoadImageFromTexture(texture);
    }

    pub fn len(self: *Self) usize {
        return self.items.len;
    }

    pub fn update(self: *Self) void {
        for (0.., self.names, self.mod_times.items) |i, *name, *mod_time| {
            const c_name: [*c]u8 = @constCast(name.ptr);
            const new_mod_time = ray.GetFileModTime(c_name);
            if (new_mod_time > mod_time.*) {
                ray.UnloadTexture(self.items.items[i]);
                self.items.items[i] = ray.LoadTexture(c_name);
            }
        }
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize Canvas
    var pixel_buffer = PixelBuffer.init(allocator);
    defer pixel_buffer.deinit();

    // Initialize variables
    var ctx = try AppContext.init(allocator);
    defer ctx.deinit();

    // Initialize ray
    ray.SetConfigFlags(ray.FLAG_WINDOW_RESIZABLE);
    if (builtin.mode != .Debug) {
        ray.SetTraceLogLevel(ray.LOG_NONE);
    }
    ray.InitWindow(0, 0, "pixel edit");
    defer ray.CloseWindow();
    const monitor = ray.GetCurrentMonitor();
    const screen_width = ray.GetMonitorWidth(monitor);
    const screen_height = ray.GetMonitorHeight(monitor);
    ray.SetWindowMinSize(400, 400);
    ray.SetWindowMaxSize(screen_width, screen_height);
    var textures = try Textures.init(allocator, &[_][]const u8{
        "assets/icon.png",
        "assets/file_icon.png",
        "assets/save_icon.png",
        "assets/eraser_icon.png",
        "assets/pencil_icon.png",
        "assets/bucket_icon.png",
        "assets/plus_icon.png",
        "assets/minus_icon.png",
        "assets/play_icon.png",
    });
    defer textures.deinit();

    // ray.SetWindowIcon(textures.getAsImage(.Icon));
    // ray.ToggleBorderlessWindowed();

    // App Texture
    const appTexture = ray.LoadRenderTexture(screen_width, screen_height);
    defer ray.UnloadTexture(appTexture.texture);

    // Canvas Texture
    const canvasTexture = ray.LoadRenderTexture(ctx.canvas_width * ctx.zoom_level, ctx.canvas_height * ctx.zoom_level);
    defer ray.UnloadTexture(canvasTexture.texture);

    const previousCanvasTexture = ray.LoadRenderTexture(ctx.canvas_width * ctx.zoom_level, ctx.canvas_height * ctx.zoom_level);
    defer ray.UnloadTexture(previousCanvasTexture.texture);

    // Preview Texture
    const previewTexture = ray.LoadRenderTexture(ctx.canvas_width * ctx.zoom_level, ctx.canvas_height * ctx.zoom_level);
    defer ray.UnloadTexture(previewTexture.texture);

    // Initialize GUI
    var button_y: f32 = 0;
    var button_open = gui.Button{
        .text = "Open",
        .position = .{ .x = 0, .y = button_y },
        .texture = textures.get(.File),
    };
    button_y += button_open.height();

    var button_save = gui.Button{
        .text = "Save",
        .position = .{ .x = 0, .y = button_y },
        .texture = textures.get(.Save),
    };
    button_y += button_save.height();

    var button_eraser = gui.Button{
        .text = "Eraser",
        .position = .{ .x = 0, .y = button_y },
        .texture = textures.get(.Eraser),
    };
    button_y += button_eraser.height();

    var button_pencil = gui.Button{
        .text = "Pencil",
        .position = .{ .x = 0, .y = button_y },
        .texture = textures.get(.Pencil),
    };
    button_y += button_pencil.height();

    var button_bucket = gui.Button{
        .text = "Fill",
        .position = .{ .x = 0, .y = button_y },
        .texture = textures.get(.Bucket),
    };
    button_y += button_bucket.height();

    var button_play = gui.Button{
        .text = "Play",
        .position = .{ .x = 0, .y = button_y },
        .texture = textures.get(.Play),
    };
    button_y += button_play.height();

    var button_minus_frame = gui.Button{
        .text = "Minus",
        .position = .{ .x = 0, .y = button_y },
        .texture = textures.get(.Minus),
    };

    var button_plus_frame = gui.Button{
        .text = "Plus",
        .position = .{ .x = button_minus_frame.width(), .y = button_y },
        .texture = textures.get(.Plus),
    };

    button_y += button_plus_frame.height();

    const colors = [_]ray.Color{ ray.BLACK, ray.DARKGRAY, ray.GRAY, ray.DARKBLUE, ray.MAGENTA, ray.YELLOW, ray.WHITE, ray.BLUE, ray.RED, ray.GREEN };
    var color_pallet = try gui.ColorPallet.init(allocator, .{ .x = 0, .y = button_y }, &colors);
    defer color_pallet.deinit();
    button_y += color_pallet.height();

    const gui_max_width = @as(c_int, @intFromFloat(button_save.width()));
    const canvas_x = (ctx.zoom_level - @mod(gui_max_width, ctx.zoom_level)) + gui_max_width;
    const canvas_y = ctx.zoom_level * 2;

    var frames_counter: c_int = 0;
    const frames_speed: c_int = 8;
    ray.SetTargetFPS(60);
    while (!ray.WindowShouldClose()) {
        const is_mouse_on_canvas = mouseIsInCanvas(canvas_x, canvas_y, ctx.canvas_width * ctx.zoom_level, ctx.canvas_height * ctx.zoom_level);
        // Update
        //----------------------------------------------------------------------------------

        // seems a bit dangerous without a undo button

        const mouse_wheel = ray.GetMouseWheelMove();
        const is_ctrl_pressed = ray.IsKeyDown(ray.KEY_LEFT_CONTROL) or ray.IsKeyDown(ray.KEY_RIGHT_CONTROL);

        if (is_ctrl_pressed and ray.IsKeyReleased(ray.KEY_R)) {
            ctx.canvas.clear();
        }

        if (is_ctrl_pressed and mouse_wheel > 0) {
            ctx.brush_size += 1;
        }

        if (is_ctrl_pressed and mouse_wheel < 0 and ctx.brush_size > 1) {
            ctx.brush_size -= 1;
        }

        if (ray.IsKeyDown(ray.KEY_O)) {
            const d = ray.GetMouseWheelMove();
            if (d > 0 and ctx.canvas.opacity < 255) {
                ctx.canvas.opacity += 1;
            }
            if (d < 0 and ctx.canvas.opacity > 0) {
                ctx.canvas.opacity -= 1;
            }
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
                    try ctx.canvas.put(.{ .x = x, .y = y }, ctx.color);
                },
                Mode.DrawLine => {
                    var iter = pixel_buffer.iterator();
                    while (iter.next()) |pixel| {
                        try ctx.canvas.put(.{
                            .x = pixel.key_ptr.x,
                            .y = pixel.key_ptr.y,
                        }, ctx.color);
                    }
                    ctx.mode = Mode.Draw;
                },
                Mode.Erase => {
                    _ = ctx.canvas.remove(.{ .x = x, .y = y });
                },
                Mode.Fill => try fillTool(allocator, ctx.canvas.getCurrent(), &ctx, x, y),
            }
        }

        if (button_open.update()) {
            const open_path = try nfd.openDialog(allocator, null, null);
            if (open_path) |path| {
                const image = ray.LoadImage(@as([*c]u8, @constCast(path.ptr)));
                defer ray.UnloadImage(image);
                for (0..@as(usize, @intCast(image.width))) |x| {
                    for (0..@as(usize, @intCast(image.height))) |y| {
                        const color = ray.GetImageColor(image, @intCast(x), @intCast(y));
                        try ctx.canvas.put(.{ .x = @intCast(x), .y = @intCast(y) }, color);
                    }
                }
            }
        }

        if (button_save.update()) {
            const save_path = try nfd.saveDialog(allocator, null, null);
            if (save_path) |path| {
                saveCanvasToPng(path, &ctx.canvas, ctx.canvas_width, ctx.canvas_height);
                textures.update();
            }
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

        if (button_play.update()) {
            ctx.playing = !ctx.playing;
        }

        if (button_plus_frame.update()) {
            try ctx.canvas.nextOrCreate();
        }

        if (button_minus_frame.update()) {
            ctx.canvas.prev();
        }

        // color pallet
        if (try color_pallet.update(&appTexture.texture)) |index| {
            const r = color_pallet.colors.items[index].r;
            const g = color_pallet.colors.items[index].g;
            const b = color_pallet.colors.items[index].b;
            const a = color_pallet.colors.items[index].a;
            ctx.color = ray.Color{ .r = r, .g = g, .b = b, .a = a };
        }

        frames_counter += 1;
        if (ctx.playing and frames_counter >= (@divTrunc(60, frames_speed))) {
            frames_counter = 0;
            ctx.canvas.next();
        }

        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------

        const mouse = ray.GetMousePosition();
        updateCanvasTexture(canvasTexture, ctx.canvas.getCurrent(), ctx.zoom_level);
        if (ctx.canvas.getPreviousFrame()) |previousFrameCanvas| {
            updateCanvasTexture(previousCanvasTexture, previousFrameCanvas, ctx.zoom_level);
        }
        updatePreviewTexture(previewTexture, &pixel_buffer, ctx.zoom_level, ctx.color);

        ray.BeginTextureMode(appTexture);
        ray.ClearBackground(ray.LIGHTGRAY);

        gui.drawTexture(&previousCanvasTexture.texture, canvas_x, canvas_y, 255);
        gui.drawTexture(&canvasTexture.texture, canvas_x, canvas_y, ctx.canvas.opacity);
        gui.drawTexture(&previewTexture.texture, canvas_x, canvas_y, 255);

        // GUI
        button_open.draw();
        button_save.draw();
        button_eraser.draw();
        button_pencil.draw();
        button_bucket.draw();
        button_play.draw();
        button_plus_frame.draw();
        button_minus_frame.draw();

        color_pallet.draw();

        drawSelectedTool(ctx.mode);
        ray.DrawText(ray.TextFormat("Frames: %d/%d", ctx.canvas.current_frame(), ctx.canvas.len()), 100, 0, 20, ray.BLACK);
        ray.DrawText(ray.TextFormat("Opacity: %d", ctx.canvas.opacity), 300, 0, 20, ray.BLACK);
        ray.DrawText(ray.TextFormat("r: %d, g: %d, b: %d, a: %d", ctx.color.r, ctx.color.g, ctx.color.b, ctx.color.a), 500, 0, 20, ray.BLACK);

        // Brush
        drawBrush(&ctx, mouse, is_mouse_on_canvas);
        ray.EndTextureMode();

        ray.BeginDrawing();
        gui.drawTexture(&appTexture.texture, 0, 0, 255);
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

fn drawBrush(
        ctx: *const AppContext,
        mouse: ray.Vector2,
        is_mouse_on_canvas: bool,
    ) void {
    if (!is_mouse_on_canvas) {
        ray.ShowCursor();
        return;
    }
    ray.HideCursor();
    const pos = fix_point_to_grid(c_int, ctx.zoom_level, mouse);
    const color = if (
            ctx.mode == Mode.Draw or
            ctx.mode == Mode.DrawLine or
            ctx.mode == Mode.Fill
        ) ctx.color
        else ctx.erase_color;
    ray.DrawRectangle(pos.x, pos.y, ctx.zoom_level, ctx.zoom_level, color);
    ray.DrawRectangleLines(pos.x, pos.y, ctx.zoom_level, ctx.zoom_level, ray.WHITE);
}

fn drawSelectedTool(mode: Mode) void {
    const step: f32 = 64;
    const y = switch (mode) {
        Mode.Erase => step * 2,
        Mode.Draw, Mode.DrawLine => step * 3,
        Mode.Fill => step * 4,
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
        save_file_path: []const u8,
        manager: *CanvasManager,
        screen_width: c_int,
        screen_height: c_int
    ) void {
    const length: c_int = @intCast(manager.frames.items.len);
    const target = ray.LoadRenderTexture(screen_width * length, screen_height);
    defer ray.UnloadTexture(target.texture);

    ray.BeginTextureMode(target);


    var offset: c_int = 0;
    for (manager.frames.items) |frame| {
        var iter_canvas = frame.iterator();
        while (iter_canvas.next()) |pixel| {
            // zig fmt: off
            ray.DrawPixel(
                @intCast(pixel.key_ptr.x + offset),
                @intCast(pixel.key_ptr.y),
                pixel.value_ptr.color
            );
        }
        offset += screen_width;
    }

    ray.EndTextureMode();
    var image = ray.LoadImageFromTexture(target.texture);
    ray.ImageFlipVertical(&image);
    const path = @as([*c]u8, @constCast(save_file_path.ptr));
    _ = ray.ExportImage(image, path);
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

    const target_color =
        if (canvas.get(.{ .x = x, .y = y })) |value| value.color
        else ray.BLANK;
    const replacement_color = ctx.color;
    try stack.append(.{ .x = x, .y = y });

    while (stack.items.len > 0) {
        const pixel = stack.pop();
        const current_color =
            if (canvas.get(.{ .x = pixel.x, .y = pixel.y })) |value| value.color else ray.BLANK;

        if ((0 <= pixel.x and pixel.x < ctx.canvas_width) and
            (0 <= pixel.y and pixel.y < ctx.canvas_height) and
            compareColors(current_color, target_color))
        {
            try ctx.canvas.put(pixel, replacement_color);
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
