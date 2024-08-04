const std = @import("std");
const Allocator = std.mem.Allocator;
const Ui = @import("Ui.zig");
const Canvas = @import("Canvas.zig");
const rl = @import("raylib");
const rg = @import("raygui");
const utils = @import("utils.zig");
const cast = utils.cast;
const Settings = @import("Settings.zig");
// const nfd = @import("nfd");

const Button = @import("Button.zig").Button;

const Brush = @import("Brush.zig");

test {
    _ = @import("Canvas.zig");
    _ = @import("Dragable.zig");
    _ = @import("utils.zig");
}

pub fn main() !void {
    var settings = Settings{};
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const screen_width = 800;
    const screen_height = 600;
    rl.initWindow(screen_width, screen_height, "Pixel Edit");
    defer rl.closeWindow();

    // guiSetup();

    var canvas = try Canvas.init(
        allocator,
        .{ .x = 0, .y = 0, .width = 16, .height = 16 },
        .{ .x = 16, .y = 16 },
    );
    defer canvas.deinit();

    var camera = rl.Camera2D{
        .offset = rl.Vector2{
            .x = @divFloor(screen_width, 2) - @divFloor(canvas.rect.width, 2),
            .y = @divFloor(screen_height, 2) - @divFloor(canvas.rect.height, 2),
        },
        .target = rl.Vector2{ .x = 0, .y = 0 },
        .rotation = 0,
        .zoom = 1,
    };

    var brush = Brush.init();
    defer brush.deinit();
    var ui = Ui.init();
    defer ui.deinit();

    // -----  In World Space  ----
    var change_canvas_width = IncCanvasWidth.init();
    defer change_canvas_width.deinit();
    var change_canvas_height = IncCanvasHeight.init();
    defer change_canvas_height.deinit();
    // ---------------------------

    // var is_saving = true;
    rl.setTargetFPS(60);
    while (!rl.windowShouldClose()) {
        // -------   UPDATE   -------
        const pos = rl.getMousePosition();
        const worldMosusePosition = rl.getScreenToWorld2D(pos, camera);
        // if (is_saving) {
        //     _ = try nfd.saveDialog(allocator, null, null);
        //     is_saving = false;
        // }

        ui.file_manager.save(&canvas);
        const gui_active = try ui.update(pos, &settings);
        if (!gui_active and
            rl.checkCollisionPointRec(worldMosusePosition, canvas.rect) and
            rl.isMouseButtonDown(.mouse_button_middle))
        {
            var delta = rl.getMouseDelta();
            delta = delta.scale(-1.0 / camera.zoom);
            camera.target = camera.target.add(delta);
        }

        updateCameraZoom(&camera, pos, worldMosusePosition);

        if (!gui_active and rl.checkCollisionPointRec(worldMosusePosition, canvas.rect)) {
            rl.hideCursor();
            brush.showOutline();
            if (rl.isMouseButtonDown(.mouse_button_left)) {
                try canvas.insert(worldMosusePosition.divide(canvas.cell_size), brush.color);
            } else if (rl.isMouseButtonDown(.mouse_button_right)) {
                canvas.remove(worldMosusePosition.divide(canvas.cell_size));
            }
        } else {
            brush.hideOutline();
            rl.showCursor();
        }

        canvas.update();
        change_canvas_width.update(worldMosusePosition, &canvas.size_in_pixels.x);
        change_canvas_height.update(worldMosusePosition, &canvas.size_in_pixels.y);

        // ------- END UPDATE -------
        // -------    DRAW    -------
        rl.beginDrawing();
        rl.clearBackground(rl.Color.dark_gray);
        defer rl.endDrawing();
        rl.beginMode2D(camera);

        change_canvas_width.draw(canvas.size_in_pixels.x);
        change_canvas_height.draw(canvas.size_in_pixels.y);
        canvas.draw();
        brush.draw(worldMosusePosition, canvas.cell_size);
        if (settings.draw_grid) {
            drawGrid(canvas.size_in_pixels, canvas.cell_size);
        }

        rl.endMode2D();
        // -------    GUI     -------

        try ui.draw(&brush.color);

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
        30,
    );

    rg.guiSetStyle(
        cast(i32, rg.GuiControl.default),
        cast(i32, rg.GuiControlProperty.text_color_normal),
        rl.Color.white.toInt(),
    );
}
