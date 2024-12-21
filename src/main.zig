const std = @import("std");
const Asset = @import("assets.zig");
const rl = @import("rl/mod.zig");
const event = @import("event.zig");
const ControlPannel = @import("ControlPannel.zig");
const ColorWheel = @import("ColorWheel.zig");
const Canvas = @import("Canvas.zig");

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

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    rl.initWindow(800, 600, "Pixel Edit");
    defer rl.closeWindow();

    var control_pannel = try ControlPannel.init(allocator);
    defer control_pannel.deinit();
    var events = std.ArrayList(event.Event).init(allocator);
    defer events.deinit();
    var state: State = .none;

    var canvas = try Canvas.init(.{ .x = centerScreenX(i32), .y = centerScreenY(i32), .width = 16, .height = 16 }, allocator);
    defer canvas.deinit();

    var color_wheel = ColorWheel.init(.{ .x = 200, .y = 200, .width = 200, .height = 200 });

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
            }
        }

        events.clearRetainingCapacity();

        switch (state) {
            .draw => {
                const cursor = rl.getMousePosition();
                if (rl.isMouseButtonDown(.mouse_button_left)) {
                    _ = try canvas.insert(cursor.as(i32));
                }
            },
            .line => std.debug.print("line\n", .{}),
            .fill => std.debug.print("fill\n", .{}),
            .erase => std.debug.print("erase\n", .{}),
            .color_picker => std.debug.print("color_picker\n", .{}),
            .select => std.debug.print("select\n", .{}),
            .widget_width_input => {
                control_pannel.update_input(.width_input, &state);
            },
            .widget_height_input => {
                control_pannel.update_input(.height_input, &state);
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
