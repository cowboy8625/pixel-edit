const std = @import("std");
const Allocator = std.mem.Allocator;
const Ui = @import("Ui.zig");
const Canvas = @import("Canvas.zig");
const rl = @import("raylib");
const rg = @import("raygui");
const utils = @import("utils.zig");
const cast = utils.cast;
const Context = @import("Context.zig");
const handleCliArgs = @import("args.zig").handleCliArgs;
const algorithms = @import("algorithms.zig");
const Button = @import("Button.zig").Button;
const Slider = @import("Slider.zig").Slider;

test {
    _ = @import("Canvas.zig");
    _ = @import("Dragable.zig");
    _ = @import("utils.zig");
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var canvas = try Canvas.init(
        allocator,
        .{ .x = 0, .y = 0, .width = 16, .height = 16 },
        .{ .x = 16, .y = 16 },
    );
    defer canvas.deinit();

    var canvas_overlay_pixels = std.ArrayList(rl.Vector2).init(allocator);
    defer canvas_overlay_pixels.deinit();

    try handleCliArgs(allocator, &canvas);

    const screen_width = 800;
    const screen_height = 600;
    rl.initWindow(screen_width, screen_height, "Pixel Edit");
    defer rl.closeWindow();

    var context = Context.init();
    defer context.deinit();

    guiSetup();

    var camera = rl.Camera2D{
        .offset = rl.Vector2{
            .x = @divFloor(screen_width, 2) - @divFloor(canvas.rect.width, 2),
            .y = @divFloor(screen_height, 2) - @divFloor(canvas.rect.height, 2),
        },
        .target = rl.Vector2{ .x = 0, .y = 0 },
        .rotation = 0,
        .zoom = 1,
    };

    var ui = Ui.init(.{ .x = 0, .y = 0, .width = 110, .height = screen_height });
    defer ui.deinit();
    var frame_opacity_slider = Slider(u8, *Context).init(
        context.frame_opacity,
        0,
        255,
        .{
            .x = 256,
            .y = 20,
        },
        struct {
            fn callback(value: u8, ctx: *Context) u8 {
                ctx.frame_opacity = value;
                return ctx.frame_opacity;
            }
        }.callback,
    );

    // -----  In World Space  ----
    var change_canvas_width = IncCanvasWidth.init();
    defer change_canvas_width.deinit();
    var change_canvas_height = IncCanvasHeight.init();
    defer change_canvas_height.deinit();
    // ---------------------------

    rl.setTargetFPS(60);
    while (!rl.windowShouldClose()) {
        // -------   UPDATE   -------
        const delta_time = rl.getFrameTime();
        const pos = rl.getMousePosition();
        const worldMosusePosition = rl.getScreenToWorld2D(pos, camera);

        if (context.path) |path| {
            switch (context.path_action) {
                .Save => canvas.save(path),
                .Load => try canvas.load(path),
            }
            context.path = null;
        }
        try ui.update(pos, &context);
        if (!context.flags.gui_active and
            rl.checkCollisionPointRec(worldMosusePosition, canvas.rect) and
            rl.isMouseButtonDown(.mouse_button_right))
        {
            var delta = rl.getMouseDelta();
            delta = delta.scale(-1.0 / camera.zoom);
            camera.target = camera.target.add(delta);
        }

        updateCameraZoom(&camera, pos, worldMosusePosition);

        canvas.update();
        change_canvas_width.update(worldMosusePosition, &canvas.size_in_pixels.x);
        change_canvas_height.update(worldMosusePosition, &canvas.size_in_pixels.y);

        if (!context.flags.gui_active and rl.checkCollisionPointRec(worldMosusePosition, canvas.rect)) {
            rl.hideCursor();
            context.brush.showOutline();
            switch (context.brush.mode) {
                .Draw => if (rl.isMouseButtonDown(.mouse_button_left)) {
                    try canvas.insert(worldMosusePosition.divide(canvas.cell_size), context.brush.color);
                    context.last_cell_position = worldMosusePosition;
                },
                .Erase => if (rl.isMouseButtonDown(.mouse_button_left)) {
                    canvas.remove(worldMosusePosition.divide(canvas.cell_size));
                },
                .Line => if (rl.isMouseButtonDown(.mouse_button_left)) {
                    context.last_cell_position = worldMosusePosition;
                    for (canvas_overlay_pixels.items) |pixel| {
                        try canvas.insert(pixel, context.brush.color);
                    }
                    canvas_overlay_pixels.clearRetainingCapacity();
                },
                .Fill => if (rl.isMouseButtonPressed(.mouse_button_left)) {
                    const x = cast(usize, @divFloor(worldMosusePosition.x, canvas.cell_size.x));
                    const y = cast(usize, @divFloor(worldMosusePosition.y, canvas.cell_size.y));
                    try algorithms.floodFill(allocator, &canvas, context.brush, .{ .x = x, .y = y });
                },
                .ColorPicker => if (rl.isMouseButtonPressed(.mouse_button_left)) {
                    const x = cast(usize, @divFloor(worldMosusePosition.x, canvas.cell_size.x));
                    const y = cast(usize, @divFloor(worldMosusePosition.y, canvas.cell_size.y));
                    const color = canvas.get(Canvas.Point{ .x = x, .y = y }) orelse rl.Color.blank;
                    context.brush.color = color;
                },
                .Select => if (rl.isMouseButtonPressed(.mouse_button_left)) {
                    context.brush.seletion_rect = .{
                        .x = @divFloor(worldMosusePosition.x, canvas.cell_size.x),
                        .y = @divFloor(worldMosusePosition.y, canvas.cell_size.y),
                        .width = 1,
                        .height = 1,
                    };
                } else if (rl.isMouseButtonReleased(.mouse_button_left)) {
                    // TODO: set to last mode;
                    context.brush.mode = .Draw;
                } else if (context.brush.seletion_rect != null) {
                    const x = @divFloor(worldMosusePosition.x, canvas.cell_size.x) + 1;
                    const y = @divFloor(worldMosusePosition.y, canvas.cell_size.y) + 1;
                    context.brush.seletion_rect.?.width = x - context.brush.seletion_rect.?.x;
                    context.brush.seletion_rect.?.height = y - context.brush.seletion_rect.?.y;
                },
            }
        } else {
            context.brush.hideOutline();
            rl.showCursor();
        }

        if (context.command) |command| {
            switch (command) {
                .IntoFrames => if (context.brush.seletion_rect != null and canvas.frames.items.len == 1) {
                    var rect = context.brush.seletion_rect.?;
                    const frames_x = cast(usize, @divTrunc(canvas.cell_size.x, rect.width));
                    const frames_y = cast(usize, @divTrunc(canvas.cell_size.y, rect.height));

                    for (0..frames_y) |y| {
                        for (0..frames_x) |x| {
                            rect.x = cast(f32, x) * rect.width;
                            rect.y = cast(f32, y) * rect.height;
                            try canvas.copyAeraToNewFrame(rect);
                        }
                    }
                    canvas.size_in_pixels.x = rect.width;
                    canvas.size_in_pixels.y = rect.height;
                    canvas.deleteFrame(0);
                    context.brush.seletion_rect = null;
                    context.command = null;
                } else {
                    context.command = null;
                },
                .OpenMenu => {
                    ui.openMenu();
                    context.flags.menu_is_open = true;
                    context.command = null;
                },
                .CloseMenu => {
                    ui.closeMenu();
                    context.flags.menu_is_open = false;
                    context.command = null;
                },
                .FlipHorizontal => {
                    canvas.flipHorizontal();
                    context.command = null;
                },
                .FlipVertical => {
                    canvas.flipVertical();
                    context.command = null;
                },
                .RotateLeft => {
                    canvas.rotateLeft();
                    context.command = null;
                },
                .RotateRight => {
                    canvas.rotateRight();
                    context.command = null;
                },
                .OpenColorPicker => {
                    ui.openColorPicker();
                    context.flags.color_picker_is_open = true;
                    context.command = null;
                },
                .CloseColorPicker => {
                    ui.closeColorPicker();
                    context.flags.color_picker_is_open = false;
                    context.command = null;
                },
                .OpenSaveFileManager => {
                    ui.openSaveFileManager();
                    context.flags.save_file_manager_is_open = true;
                    context.command = null;
                },
                .CloseSaveFileManager => {
                    ui.openSaveFileManager();
                    context.flags.save_file_manager_is_open = false;
                    context.command = null;
                },
                .OpenLoadFileManager => {
                    ui.openLoadFileManager();
                    context.flags.load_file_manager_is_open = true;
                    context.command = null;
                },
                .CloseLoadFileManager => {
                    ui.openLoadFileManager();
                    context.flags.load_file_manager_is_open = false;
                    context.command = null;
                },
                .TurnGridOn => {
                    context.flags.draw_grid = true;
                    context.command = null;
                },
                .TurnGridOff => {
                    context.flags.draw_grid = false;
                    context.command = null;
                },
                .FrameRight => {
                    if (canvas.frame_id < canvas.frames.items.len - 1) {
                        canvas.nextFrame();
                    } else {
                        try canvas.newFrame();
                        canvas.nextFrame();
                    }
                    context.command = null;
                },
                .FrameLeft => {
                    canvas.previousFrame();
                    context.command = null;
                },

                .Play => {
                    // TODO: implement flag for this
                    canvas.animate(delta_time);
                },
                .Stop => {
                    context.command = null;
                },
            }
        }

        if (context.brush.mode == .Line and rl.checkCollisionPointRec(worldMosusePosition, canvas.rect)) {
            canvas_overlay_pixels.clearRetainingCapacity();
            const x1 = cast(i32, @divFloor(context.last_cell_position.x, canvas.cell_size.x));
            const y1 = cast(i32, @divFloor(context.last_cell_position.y, canvas.cell_size.y));
            const x2 = cast(i32, @divFloor(worldMosusePosition.x, canvas.cell_size.x));
            const y2 = cast(i32, @divFloor(worldMosusePosition.y, canvas.cell_size.y));
            try algorithms.bresenhamLine(x1, y1, x2, y2, &canvas_overlay_pixels);
        } else {
            canvas_overlay_pixels.clearRetainingCapacity();
        }

        _ = frame_opacity_slider.update(pos, &context);

        // ------- END UPDATE -------
        // -------    DRAW    -------
        rl.beginDrawing();
        rl.clearBackground(rl.Color.dark_gray);
        defer rl.endDrawing();
        rl.beginMode2D(camera);

        change_canvas_width.draw(canvas.size_in_pixels.x);
        change_canvas_height.draw(canvas.size_in_pixels.y);
        canvas.draw(context.frame_opacity);
        if (context.brush.mode == .Line) {
            for (canvas_overlay_pixels.items) |p| {
                const rect = .{
                    .x = p.x * canvas.cell_size.x,
                    .y = p.y * canvas.cell_size.y,
                    .width = canvas.cell_size.x,
                    .height = canvas.cell_size.y,
                };
                rl.drawRectangleRec(rect, rl.Color.light_gray);
            }
        }
        context.brush.draw(worldMosusePosition, canvas.cell_size);
        if (context.flags.draw_grid) {
            drawGrid(canvas.size_in_pixels, canvas.cell_size);
        }

        if ((context.brush.mode == .Select and context.brush.seletion_rect != null) or context.brush.seletion_rect != null) {
            const section_area = .{
                .x = context.brush.seletion_rect.?.x * canvas.cell_size.x,
                .y = context.brush.seletion_rect.?.y * canvas.cell_size.y,
                .width = context.brush.seletion_rect.?.width * canvas.cell_size.x,
                .height = context.brush.seletion_rect.?.height * canvas.cell_size.y,
            };
            rl.drawRectangleLinesEx(section_area, 5, rl.Color.black);
        }

        rl.endMode2D();
        // -------    GUI     -------

        if (canvas.frames.items.len > 1) {
            rl.drawText(
                rl.textFormat("Frame: %d/%d", .{ canvas.frame_id + 1, canvas.frames.items.len }),
                screen_width - 150, // X
                20, // Y
                20,
                rl.Color.white,
            );

            frame_opacity_slider.draw(.{
                .x = screen_width - 500,
                .y = 20,
            });

            rl.drawText(
                rl.textFormat("%d", .{context.frame_opacity}),
                screen_width - 500 + 260,
                20, // Y
                20,
                rl.Color.white,
            );
        } else {
            context.frame_opacity = 255;
        }
        try ui.draw(&context);

        // -------  END GUI   -------
        // -------  END DRAW  -------
    }
}

const IncCanvasWidth = struct {
    const Self = @This();

    plus_button_one: Button(*f32),
    minus_button_one: Button(*f32),

    pub fn init() Self {
        var plus_button_one = Button(*f32).initWithText("+", .{ .x = 50, .y = -20 }, struct {
            fn callback(arg: *f32) void {
                arg.* += 1;
            }
        }.callback);
        errdefer plus_button_one.deinit();
        var minus_button_one = Button(*f32).initWithText("-", .{ .x = 0, .y = -20 }, struct {
            fn callback(arg: *f32) void {
                if (arg.* == 0) return;
                arg.* -= 1;
            }
        }.callback);
        errdefer minus_button_one.deinit();
        return .{
            .plus_button_one = plus_button_one,
            .minus_button_one = minus_button_one,
        };
    }

    pub fn deinit(self: *Self) void {
        self.plus_button_one.deinit();
        self.minus_button_one.deinit();
    }

    pub fn update(self: *Self, mouse_pos: rl.Vector2, size: *f32) void {
        _ = self.plus_button_one.update(mouse_pos, size);
        _ = self.minus_button_one.update(mouse_pos, size);
    }

    pub fn draw(self: *Self, size: f32) void {
        rl.drawText(rl.textFormat("%.0f", .{size}), 20, -20, 20, rl.Color.black);
        self.plus_button_one.draw();
        self.minus_button_one.draw();
    }
};

const IncCanvasHeight = struct {
    const Self = @This();

    plus_button_one: Button(*f32),
    minus_button_one: Button(*f32),

    pub fn init() Self {
        var plus_button_one = Button(*f32).initWithText("+", .{ .x = -20, .y = 40 }, struct {
            fn callback(arg: *f32) void {
                arg.* += 1;
            }
        }.callback);
        errdefer plus_button_one.deinit();
        var minus_button_one = Button(*f32).initWithText("-", .{ .x = -20, .y = 0 }, struct {
            fn callback(arg: *f32) void {
                if (arg.* == 0) return;
                arg.* -= 1;
            }
        }.callback);
        errdefer minus_button_one.deinit();
        return .{
            .plus_button_one = plus_button_one,
            .minus_button_one = minus_button_one,
        };
    }

    pub fn deinit(self: *Self) void {
        self.plus_button_one.deinit();
        self.minus_button_one.deinit();
    }

    pub fn update(self: *Self, mouse_pos: rl.Vector2, size: *f32) void {
        _ = self.plus_button_one.update(mouse_pos, size);
        _ = self.minus_button_one.update(mouse_pos, size);
    }

    pub fn draw(self: *Self, size: f32) void {
        rl.drawText(rl.textFormat("%.0f", .{size}), -25, 20, 20, rl.Color.black);
        self.plus_button_one.draw();
        self.minus_button_one.draw();
    }
};

fn updateCameraZoom(camera: *rl.Camera2D, pos: rl.Vector2, worldMosusePosition: rl.Vector2) void {
    const wheel = rl.getMouseWheelMove();

    if (wheel != 0) {
        const zoomIncrement = 0.1;
        camera.zoom += wheel * zoomIncrement;

        if (camera.zoom < 0.1) camera.zoom = 0.1; // Minimum zoom level
        if (camera.zoom > 3.0) camera.zoom = 3.0; // Maximum zoom level

        // Adjust camera target based on zoom
        const mousePositionAfter = rl.getScreenToWorld2D(pos, camera.*);
        camera.target.x -= (mousePositionAfter.x - worldMosusePosition.x);
        camera.target.y -= (mousePositionAfter.y - worldMosusePosition.y);
    }
}

fn drawGrid(size: rl.Vector2, cells: rl.Vector2) void {
    const px_width = cast(i32, size.x * cells.x);
    const px_height = cast(i32, size.y * cells.y);
    for (0..(cast(usize, size.x) + 1)) |x| {
        const ix = cast(i32, cells.x) * cast(i32, x);
        rl.drawLine(ix, 0, ix, px_height, rl.Color.white);
    }
    for (0..(cast(usize, size.y) + 1)) |y| {
        const iy = cast(i32, cells.y) * cast(i32, y);
        rl.drawLine(0, iy, px_width, iy, rl.Color.white);
    }
}

fn guiSetup() void {
    rl.setConfigFlags(
        rl.ConfigFlags{ .window_resizable = true },
    );
    rl.setExitKey(rl.KeyboardKey.key_null);

    rg.guiSetStyle(
        cast(i32, rg.GuiControl.default),
        cast(i32, rg.GuiDefaultProperty.text_size),
        20,
    );

    rg.guiSetStyle(
        cast(i32, rg.GuiControl.default),
        cast(i32, rg.GuiControlProperty.text_color_normal),
        rl.Color.black.toInt(),
    );
}
