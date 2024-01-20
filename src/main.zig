const std = @import("std");
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;
const print = std.debug.print;

const gui = @import("gui/mod.zig");
const nfd = @import("nfd");
const ray = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

const ArrayVec = std.ArrayList(ray.Vector2);
const Canvas = std.AutoHashMap(Pixel, struct { color: ray.Color });
const PixelBuffer = std.AutoHashMap(Pixel, void);

const FONT_SIZE: c_int = 20;

const Mode = enum {
    Draw,
    Shade,
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
    color_index: usize = 0,
    color: ray.Color = ray.DARKGRAY,
    erase_color: ray.Color = ray.WHITE,
    is_drawing: bool = false,
    mode: Mode = Mode.Draw,
    zoom_level: c_int = 10,
    canvas_width: c_int = 64,
    canvas_height: c_int = 64,
    last_pixel: Pixel = .{ .x = 0, .y = 0 },
    playing: bool = false,
    selected_option: usize = 0,
    step: u8 = 1,
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

    pub fn get(self: *Self, pixel: Pixel) ray.Color {
        return if (self.frames.items[self.index].get(pixel)) |c| c.color else ray.BLANK;
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
    // if (builtin.mode != .Debug) {
    //     ray.SetTraceLogLevel(ray.LOG_NONE);
    // }
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

    var camera = ray.Camera2D{
        .offset = .{ .x = 0, .y = 0 },
        .target = .{ .x = 0, .y = 0 },
        .rotation = 0,
        .zoom = 1,
    };

    // ray.SetWindowIcon(textures.getAsImage(.Icon));
    // ray.ToggleBorderlessWindowed();

    // Canvas Texture
    const canvasTexture = ray.LoadRenderTexture(ctx.canvas_width * ctx.zoom_level, ctx.canvas_height * ctx.zoom_level);
    defer ray.UnloadTexture(canvasTexture.texture);

    const previousCanvasTexture = ray.LoadRenderTexture(ctx.canvas_width * ctx.zoom_level, ctx.canvas_height * ctx.zoom_level);
    defer ray.UnloadTexture(previousCanvasTexture.texture);

    // Preview Texture
    const previewTexture = ray.LoadRenderTexture(ctx.canvas_width * ctx.zoom_level, ctx.canvas_height * ctx.zoom_level);
    defer ray.UnloadTexture(previewTexture.texture);

    // Text UI
    var status_text_buffer = try allocator.alloc(u8, 100);
    defer allocator.free(status_text_buffer);

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
        const is_mouse_on_canvas = mouseIsInCanvas(camera, canvas_x, canvas_y, ctx.canvas_width * ctx.zoom_level, ctx.canvas_height * ctx.zoom_level);
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
            const pos = fix_point_to_grid(c_int, ctx.zoom_level, ray.GetScreenToWorld2D(ray.GetMousePosition(), camera));
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
            const pos = fix_point_to_grid(c_int, ctx.zoom_level, ray.GetScreenToWorld2D(ray.GetMousePosition(), camera));
            const grid_x = pos.x - canvas_x;
            const grid_y = pos.y - canvas_y;
            const x = @divTrunc(grid_x, ctx.zoom_level);
            const y = @divTrunc(grid_y, ctx.zoom_level);
            switch (ctx.mode) {
                Mode.Draw => {
                    try ctx.canvas.put(.{ .x = x, .y = y }, ctx.color);
                },
                Mode.Shade => if (ctx.last_pixel.x != x or ctx.last_pixel.y != y) {
                    const current = ctx.canvas.get(.{ .x = x, .y = y });
                    const color = .{
                        .r = current.r -| 5,
                        .g = current.g -| 5,
                        .b = current.b -| 5,
                        .a = current.a,
                    };
                    try ctx.canvas.put(.{ .x = x, .y = y }, color);
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
            ctx.last_pixel = .{ .x = x, .y = y };
        }

        if (button_open.update()) |_| {
            // Get path of image
            const open_path = try nfd.openDialog(allocator, null, null);
            // only if path is not null
            if (open_path) |path| {
                // Load image
                const image = ray.LoadImage(@as([*c]u8, @constCast(path.ptr)));
                // Unload image when out of scope
                defer ray.UnloadImage(image);
                // get the number of frames
                const frame_count: usize = @intCast(@divTrunc(image.width, ctx.canvas_width));
                // for each frame
                for (0..frame_count) |offset| {
                    // get the frame
                    const frame = ray.ImageFromImage(image, .{
                        .x = @as(f32, @floatFromInt(offset * @as(usize, @intCast(ctx.canvas_width)))),
                        .y = 0,
                        .width = @as(f32, @floatFromInt(ctx.canvas_width)),
                        .height = @as(f32, @floatFromInt(ctx.canvas_height)),
                    });
                    // insert each pixel into the canvas
                    for (0..@as(usize, @intCast(frame.width))) |x| {
                        for (0..@as(usize, @intCast(frame.height))) |y| {
                            const color = ray.GetImageColor(frame, @intCast(x), @intCast(y));
                            try ctx.canvas.put(.{ .x = @intCast(x), .y = @intCast(y) }, color);
                        }
                    }
                    // only if a new frame is needed
                    if (frame_count - 1 != offset) {
                        try ctx.canvas.nextOrCreate();
                    }
                }
            }
        }

        if (button_save.update()) |_| {
            const save_path = try nfd.saveDialog(allocator, null, null);
            if (save_path) |path| {
                saveCanvasToPng(path, &ctx.canvas, ctx.canvas_width, ctx.canvas_height);
                textures.update();
            }
        }

        if (button_eraser.update()) |_| {
            ctx.mode = Mode.Erase;
        }

        if (button_pencil.update()) |mouse_button| {
            switch (mouse_button) {
                .Right => ctx.mode = .Shade,
                .Left => ctx.mode = .Draw,
            }
        }

        if (button_bucket.update()) |_| {
            ctx.mode = Mode.Fill;
        }

        if (button_play.update()) |_| {
            ctx.playing = !ctx.playing;
        }

        if (button_plus_frame.update()) |_| {
            switch (ctx.selected_option) {
                0 => try ctx.canvas.nextOrCreate(),
                1 => ctx.canvas.opacity +|= ctx.step,
                2 => color_pallet.colors.items[ctx.color_index].r += ctx.step,
                3 => color_pallet.colors.items[ctx.color_index].g +|= ctx.step,
                4 => color_pallet.colors.items[ctx.color_index].b +|= ctx.step,
                5 => color_pallet.colors.items[ctx.color_index].a +|= ctx.step,
                6 => ctx.step +|= 5,
                else => {},
            }
        }

        if (button_minus_frame.update()) |_| {
            switch (ctx.selected_option) {
                0 => ctx.canvas.prev(),
                1 => ctx.canvas.opacity -|= ctx.step,
                2 => color_pallet.colors.items[ctx.color_index].r -|= ctx.step,
                3 => color_pallet.colors.items[ctx.color_index].g -|= ctx.step,
                4 => color_pallet.colors.items[ctx.color_index].b -|= ctx.step,
                5 => color_pallet.colors.items[ctx.color_index].a -|= ctx.step,
                6 => ctx.step -|= 5,
                else => {},
            }
        }

        // color pallet
        if (try color_pallet.update()) |index| {
            const r = color_pallet.colors.items[index].r;
            const g = color_pallet.colors.items[index].g;
            const b = color_pallet.colors.items[index].b;
            const a = color_pallet.colors.items[index].a;
            ctx.color = ray.Color{ .r = r, .g = g, .b = b, .a = a };
            ctx.color_index = index;
        }

        frames_counter += 1;
        if (ctx.playing and frames_counter >= (@divTrunc(60, frames_speed))) {
            frames_counter = 0;
            ctx.canvas.next();
        }

        if (ray.IsMouseButtonDown(ray.MOUSE_RIGHT_BUTTON)) {
            var delta = ray.GetMouseDelta();
            delta = ray.Vector2Scale(delta, -1.0 / camera.zoom);
            camera.target = ray.Vector2Add(camera.target, delta);
        }

        // zig fmt: off
        if (!(
                ray.IsKeyDown(ray.KEY_R) or
                ray.IsKeyDown(ray.KEY_G) or
                ray.IsKeyDown(ray.KEY_B) or
                ray.IsKeyDown(ray.KEY_A) or
                ray.IsKeyDown(ray.KEY_O)
            )) {
            camera.zoom += ray.GetMouseWheelMove() * 0.05;
        }

        if (camera.zoom > 3) camera.zoom = 3;
        if (camera.zoom < 0.1) camera.zoom = 0.1;
        if (ray.IsKeyReleased(ray.KEY_SPACE)) {
            ctx.selected_option = @mod(ctx.selected_option + 1, 7);
        }

        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------

        const pos = ray.GetMousePosition();
        const mouse = ray.GetScreenToWorld2D(pos, camera);
        updateCanvasTexture(canvasTexture, ctx.canvas.getCurrent(), ctx.zoom_level);
        if (ctx.canvas.getPreviousFrame()) |previousFrameCanvas| {
            updateCanvasTexture(previousCanvasTexture, previousFrameCanvas, ctx.zoom_level);
        }
        updatePreviewTexture(previewTexture, &pixel_buffer, ctx.zoom_level, ctx.color);

        ray.BeginDrawing();
        ray.ClearBackground(ray.LIGHTGRAY);
        ray.BeginMode2D(camera);

        gui.drawTexture(&previousCanvasTexture.texture, canvas_x, canvas_y, 255);
        gui.drawTexture(&canvasTexture.texture, canvas_x, canvas_y, ctx.canvas.opacity);
        gui.drawTexture(&previewTexture.texture, canvas_x, canvas_y, 255);
        // Brush
        drawBrush(&ctx, mouse, is_mouse_on_canvas);
        ray.EndMode2D();

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
        try drawStatusTextItems(&status_text_buffer, &ctx);

        drawSelectedTool(ctx.mode);

        ray.EndDrawing();
        //----------------------------------------------------------------------------------
    }
    ray.ShowCursor();
}

fn drawStatusTextItems(buffer: *[]u8, ctx: *AppContext) !void {
    var x: c_int = 100;
    for (0..7) |i| {
        const string = switch(i) {
            0 => try std.fmt.bufPrintZ(buffer.*, "Frames: {d}/{d}", .{ctx.canvas.current_frame(), ctx.canvas.len()}),
            1 => try std.fmt.bufPrintZ(buffer.*, "Opacity: {d}", .{ctx.canvas.opacity}),
            2 => try std.fmt.bufPrintZ(buffer.*, "r: {d}", .{ctx.color.r}),
            3 => try std.fmt.bufPrintZ(buffer.*, "g: {d}", .{ctx.color.g}),
            4 => try std.fmt.bufPrintZ(buffer.*, "b: {d}", .{ctx.color.b}),
            5 => try std.fmt.bufPrintZ(buffer.*, "a: {d}", .{ctx.color.a}),
            6 => try std.fmt.bufPrintZ(buffer.*, "step: {d}", .{ctx.step}),
            else => unreachable,
        };
        const c_string: [*c]u8 = @constCast(string.ptr);
        const text_width: c_int = @intFromFloat(ray.MeasureTextEx(ray.GetFontDefault(), c_string, FONT_SIZE, 2).x);
        if (i == ctx.selected_option) {
            ray.DrawRectangle(x, 0, text_width, FONT_SIZE, ray.RED);
        }
        ray.DrawText(c_string, x, 0, FONT_SIZE, ray.BLACK);
        x += text_width + 20;
    }
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
    const color = switch (ctx.mode) {
        .Draw, .DrawLine, .Fill, .Shade => ctx.color,
        else => ctx.erase_color,
    };
    ray.DrawRectangle(pos.x, pos.y, ctx.zoom_level, ctx.zoom_level, color);
    ray.DrawRectangleLines(pos.x, pos.y, ctx.zoom_level, ctx.zoom_level, ray.WHITE);
}

fn drawSelectedTool(mode: Mode) void {
    const step: f32 = 64;
    const y = switch (mode) {
        .Erase => step * 2,
        .Draw, .DrawLine, .Shade => step * 3,
        .Fill => step * 4,
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

fn mouseIsInCanvas(camera: ray.Camera2D, left: c_int, top: c_int, width: c_int, height: c_int) bool {
    const mouse = ray.GetMousePosition();
    const pos = ray.GetScreenToWorld2D(mouse, camera);
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
