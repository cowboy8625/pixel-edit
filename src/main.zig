const std = @import("std");
const Allocator = std.mem.Allocator;
const rl = @import("raylib");
const rg = @import("raygui");
const utils = @import("utils.zig");
const cast = utils.cast;

test {
    _ = @import("Canvas.zig");
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    _ = allocator;

    const screen_width = 800;
    const screen_height = 600;
    rl.initWindow(screen_width, screen_height, "Pixel Edit");
    defer rl.closeWindow();
    rl.setExitKey(rl.KeyboardKey.key_null);

    var camera = rl.Camera2D{
        .offset = rl.Vector2{ .x = @divFloor(screen_width, 2), .y = @divFloor(screen_height, 2) },
        .target = rl.Vector2{ .x = 0, .y = 0 },
        .rotation = 0,
        .zoom = 1,
    };

    rl.setTargetFPS(60);
    var color = rl.Color{ .r = 255, .g = 255, .b = 255, .a = 255 };
    rg.guiSetStyle(
        rg.GuiState.state_normal,
        rg.GuiControlProperty.border_width,
        20,
    );

    while (!rl.windowShouldClose()) {
        // -------   UPDATE   -------

        camera.target = cameraMovementUpdate();

        // ------- END UPDATE -------
        // -------    DRAW    -------
        rl.beginDrawing();
        rl.clearBackground(rl.Color.dark_gray);
        defer rl.endDrawing();
        rl.beginMode2D(camera);

        rl.endMode2D();
        // -------    GUI     -------
        _ = rg.guiColorPicker(.{ .x = 10, .y = 10, .width = 200, .height = 200 }, "Color Picker", &color);
        // if (cast(bool, rg.guiPanel(.{ .x = 10, .y = 10, .width = 200, .height = 200 }, "Panel"))) {
        //     std.debug.print("Panel\n", .{});
        // }

        _ = rg.guiLabel(.{ .x = 100, .y = 10, .width = 200, .height = 20 }, rl.textFormat("Color: %d, %d, %d, %d", .{ color.r, color.g, color.b, color.a }));

        // -------  END GUI   -------
        // -------  END DRAW  -------
    }
}

fn cameraMovementUpdate() rl.Vector2 {
    return rl.Vector2{
        .x = cast(f32, rl.isKeyDown(rl.KeyboardKey.key_d)) - cast(f32, rl.isKeyDown(rl.KeyboardKey.key_a)),
        .y = cast(f32, rl.isKeyDown(rl.KeyboardKey.key_w)) - cast(f32, rl.isKeyDown(rl.KeyboardKey.key_s)),
    };
}
