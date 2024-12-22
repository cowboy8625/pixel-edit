const std = @import("std");
const Asset = @import("assets.zig");
const rl = @import("rl/mod.zig");
const event = @import("event.zig");
const ControlPannel = @import("ControlPannel.zig");
const ColorWheel = @import("ColorWheel.zig");
const Canvas = @import("Canvas.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // ---------- SETUP ----------

    rl.initWindow(800, 600, "Pixel Edit");
    defer rl.closeWindow();

    var canvas = try Canvas.init(.{
        .x = centerScreenX(i32),
        .y = centerScreenY(i32),
        .width = 16,
        .height = 16,
    }, allocator);
    defer canvas.deinit();

    var control_pannel = try ControlPannel.init(
        allocator,
        canvas.bounding_box.getSize().div(canvas.pixels_size),
    );
    defer control_pannel.deinit();

    var events = std.ArrayList(event.Event).init(allocator);
    defer events.deinit();

    var state: State = .none;

    var color_wheel = ColorWheel.init(.{ .x = 200, .y = 200, .width = 200, .height = 200 });

    // -------- END SETUP --------

    rl.setTargetFPS(60);
    while (!rl.windowShouldClose()) {
        color_wheel.update();
        try control_pannel.update(rl.getMousePosition(), &events);

        for (events.items) |e| {
            switch (e) {
                .testing => {
                    std.debug.print("testing\n", .{});
                },
                .draw => {
                    state = .draw;
                    std.debug.print("draw tool\n", .{});
                },
                .close_control_pannel => {
                    std.debug.print("close control pannel\n", .{});
                    control_pannel.hide();
                },
                .open_control_pannel => {
                    std.debug.print("open control pannel\n", .{});
                    control_pannel.show();
                },
                .clicked => |we| switch (we) {
                    .width_input => state = .widget_width_input,
                    .height_input => state = .widget_height_input,
                },
                .open_color_wheel => color_wheel.show(),
                .close_color_wheel => color_wheel.hide(),
                .set_canvas_width => |width| canvas.setWidth(width),
                .set_canvas_height => |height| canvas.setHeight(height),
            }
        }

        events.clearRetainingCapacity();

        switch (state) {
            .draw => {
                const cursor = rl.getMousePosition();
                if (rl.isMouseButtonDown(.mouse_button_left)) {
                    _ = try canvas.insert(cursor.as(i32), color_wheel.getSelectedColor());
                }
            },
            .line => std.debug.print("line\n", .{}),
            .fill => std.debug.print("fill\n", .{}),
            .erase => std.debug.print("erase\n", .{}),
            .color_picker => std.debug.print("color_picker\n", .{}),
            .select => std.debug.print("select\n", .{}),
            .widget_width_input => {
                try control_pannel.updateInput(.width_input, &state, &events);
            },
            .widget_height_input => {
                try control_pannel.updateInput(.height_input, &state, &events);
            },
            .none => {},
        }

        // -------- DRAW --------
        rl.beginDrawing();
        rl.clearBackground(rl.Color.fromInt(0x21242bFF));
        rl.endDrawing();

        color_wheel.draw();
        canvas.draw();
        control_pannel.draw();
    }
}

fn centerScreenX(comptime T: type) T {
    const value = @divFloor(rl.getScreenWidth(), 2);
    return rl.cast(T, value);
}

fn centerScreenY(comptime T: type) T {
    const value = @divFloor(rl.getScreenHeight(), 2);
    return rl.cast(T, value);
}

pub const State = enum {
    draw,
    line,
    fill,
    erase,
    color_picker,
    select,
    widget_width_input,
    widget_height_input,
    none,
};
