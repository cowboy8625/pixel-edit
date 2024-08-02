const std = @import("std");
const Allocator = std.mem.Allocator;
const Ui = @import("Ui.zig");
const Canvas = @import("Canvas.zig");
const rl = @import("raylib");
const rg = @import("raygui");
const utils = @import("utils.zig");
const cast = utils.cast;

const Button = @import("Button.zig").Button;

const Brush = @import("Brush.zig");

test {
    _ = @import("Canvas.zig");
    _ = @import("Dragable.zig");
    _ = @import("utils.zig");
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const screen_width = 800;
    const screen_height = 600;
    rl.initWindow(screen_width, screen_height, "Pixel Edit");
    defer rl.closeWindow();
    guiSetup();

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
    var ui = Ui.init();
    defer ui.deinit();

    rl.setTargetFPS(60);
    while (!rl.windowShouldClose()) {
        // -------   UPDATE   -------
        const pos = rl.getMousePosition();
        const worldMosusePosition = rl.getScreenToWorld2D(pos, camera);

        const gui_active = ui.update(pos);
        if (!gui_active and
            rl.checkCollisionPointRec(worldMosusePosition, canvas.rect) and
            rl.isMouseButtonDown(.mouse_button_middle))
        {
            var delta = rl.getMouseDelta();
            delta = delta.scale(-1.0 / camera.zoom);
            camera.target = camera.target.add(delta);
        }

        const wheel = rl.getMouseWheelMove();

        if (wheel != 0) {
            const zoomIncrement = 0.1;
            camera.zoom += wheel * zoomIncrement;

            if (camera.zoom < 0.1) camera.zoom = 0.1; // Minimum zoom level
            if (camera.zoom > 3.0) camera.zoom = 3.0; // Maximum zoom level

            // Adjust camera target based on zoom
            const mousePositionAfter = rl.getScreenToWorld2D(pos, camera);
            camera.target.x -= (mousePositionAfter.x - worldMosusePosition.x);
            camera.target.y -= (mousePositionAfter.y - worldMosusePosition.y);
        }

        if (rl.checkCollisionPointRec(worldMosusePosition, canvas.rect)) {
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

        // ------- END UPDATE -------
        // -------    DRAW    -------
        rl.beginDrawing();
        rl.clearBackground(rl.Color.dark_gray);
        defer rl.endDrawing();
        rl.beginMode2D(camera);

        canvas.draw();
        brush.draw(worldMosusePosition, canvas.cell_size);

        rl.endMode2D();
        // -------    GUI     -------

        ui.draw(&brush.color);

        // -------  END GUI   -------
        // -------  END DRAW  -------
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
