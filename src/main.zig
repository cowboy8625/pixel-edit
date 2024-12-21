const std = @import("std");
const Asset = @import("assets.zig");
const rl = @import("rl/mod.zig");
const event = @import("event.zig");
const ControlPannel = @import("ControlPannel.zig");

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

const Canvas = struct {
    width: i32,
    height: i32,
    pixels: std.AutoHashMap(rl.Vector2(usize), rl.Color),
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

    rl.setTargetFPS(60);
    while (!rl.windowShouldClose()) {
        try control_pannel.update(rl.getMousePosition(), &events);

        for (events.items) |e| {
            switch (e) {
                .testing => {
                    std.debug.print("testing\n", .{});
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
            }
        }

        switch (state) {
            .draw => std.debug.print("draw\n", .{}),
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

        events.clearRetainingCapacity();

        // -------- DRAW --------
        rl.beginDrawing();
        rl.clearBackground(rl.Color.black);
        rl.endDrawing();

        control_pannel.draw();
    }
}
