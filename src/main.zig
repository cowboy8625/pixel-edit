const std = @import("std");
const Allocator = std.mem.Allocator;
const Dragable = @import("Dragable.zig").Dragable;
const Canvas = @import("Canvas.zig");
const rl = @import("raylib");
const rg = @import("raygui");
const utils = @import("utils.zig");
const cast = utils.cast;

test {
    _ = @import("Canvas.zig");
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

    // var camera_offset: ?rl.Vector2 = null;
    var camera = rl.Camera2D{
        .offset = rl.Vector2{
            .x = @divFloor(screen_width, 2) - @divFloor(canvas.rect.width, 2),
            .y = @divFloor(screen_height, 2) - @divFloor(canvas.rect.height, 2),
        },
        .target = rl.Vector2{ .x = 0, .y = 0 },
        .rotation = 0,
        .zoom = 1,
    };

    // var color = rl.Color{ .r = 255, .g = 255, .b = 255, .a = 255 };
    // var colorPicker = Dragable(*rl.Color).init(
    //     .{ .x = 10, .y = 10, .width = 200, .height = 200 },
    //     .mouse_button_middle,
    //     struct {
    //         fn callback(rect: rl.Rectangle, arg: *rl.Color) void {
    //             _ = rg.guiColorPicker(rect, "Color Picker", arg);
    //         }
    //     }.callback,
    // );

    rl.setTargetFPS(60);
    while (!rl.windowShouldClose()) {
        // -------   UPDATE   -------
        const pos = rl.getMousePosition();

        if (rl.isMouseButtonDown(.mouse_button_middle)) {
            const wp = rl.getScreenToWorld2D(pos, camera);
            camera.target = wp.scale(-1.0);
        }
        if (rl.isMouseButtonPressed(.mouse_button_left)) {
            camera.target = .{ .x = 0, .y = 0 };
        }
        // updateCameraTarget(pos, canvas.rect, &camera, &camera_offset);
        // colorPicker.update(pos);

        // ------- END UPDATE -------
        // -------    DRAW    -------
        rl.beginDrawing();
        rl.clearBackground(rl.Color.dark_gray);
        defer rl.endDrawing();
        rl.beginMode2D(camera);

        canvas.draw();
        rl.drawRectangleRec(.{
            .x = camera.target.x,
            .y = camera.target.y,
            .width = canvas.cell_size.x,
            .height = canvas.cell_size.y,
        }, rl.Color.magenta);

        rl.drawRectangleRec(.{
            .x = pos.x - camera.offset.x,
            .y = pos.y - camera.offset.y,
            .width = canvas.cell_size.x,
            .height = canvas.cell_size.y,
        }, rl.Color.red);
        const wp = rl.getScreenToWorld2D(pos, camera);
        rl.drawRectangleRec(.{
            .x = wp.x,
            .y = wp.y,
            .width = canvas.cell_size.x,
            .height = canvas.cell_size.y,
        }, rl.Color.yellow);

        rl.endMode2D();
        // -------    GUI     -------

        // colorPicker.draw(&color);

        rl.drawText(rl.textFormat("%.2f, %.2f", .{ camera.target.x, camera.target.y }), 10, 10, 20, rl.Color.black);
        rl.drawText(rl.textFormat("%.2f, %.2f", .{ pos.x - camera.offset.x, pos.y - camera.offset.y }), 10, 30, 20, rl.Color.black);
        rl.drawText(rl.textFormat("%.2f, %.2f", .{ canvas.rect.x, canvas.rect.x }), 10, 50, 20, rl.Color.black);
        // -------  END GUI   -------
        // -------  END DRAW  -------
    }
}

fn updateCameraTarget(pos: rl.Vector2, rect: rl.Rectangle, camera: *rl.Camera2D, offset: *?rl.Vector2) void {
    const world_pos = rl.getScreenToWorld2D(pos, camera.*);
    if (rl.isMouseButtonReleased(.mouse_button_middle)) {
        offset.* = null;
        return;
    }
    if (!rl.checkCollisionPointRec(world_pos, rect)) {
        return;
    }
    if (rl.isMouseButtonPressed(.mouse_button_middle)) {
        const canvas_pos: rl.Vector2 = .{
            .x = rect.x,
            .y = rect.y,
        };
        offset.* = world_pos.subtract(canvas_pos);
    }
    if (offset.* == null) {
        return;
    }

    camera.*.target.x = world_pos.x - offset.*.?.x;
    camera.*.target.y = world_pos.y - offset.*.?.y;
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
