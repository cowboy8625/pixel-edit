const std = @import("std");
const Asset = @import("assets.zig");
const rl = @import("rl/mod.zig");
const event = @import("event.zig");
const ControlPannel = @import("ControlPannel.zig");
const ColorWheel = @import("ColorWheel.zig");
const Canvas = @import("Canvas.zig");
const algorithms = @import("algorithms.zig");
const nfd = @import("nfd");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // ---------- SETUP ----------

    rl.setConfigFlags(.{
        .window_resizable = true,
    });
    rl.initWindow(0, 0, "Pixel Edit");
    defer rl.closeWindow();

    var canvas = try Canvas.init(
        allocator,
        .{
            .x = 0,
            .y = 0,
            .width = 15,
            .height = 15,
        },
        16,
    );
    defer canvas.deinit();

    var control_pannel = try ControlPannel.init(
        allocator,
        canvas.bounding_box.getSize(),
    );
    defer control_pannel.deinit();

    var events = std.ArrayList(event.Event).init(allocator);
    defer events.deinit();

    var state: State = .none;
    var annimation = Annimation{
        .speed = 0.5,
    };

    var color_wheel = ColorWheel.init(.{ .x = 200, .y = 200, .width = 200, .height = 200 });

    var camera = rl.Camera2D{
        .offset = rl.Vector2(i32).init(rl.getScreenWidth(), rl.getScreenHeight()).div(2).sub(canvas.getVisiableRect(i32).getSize().div(2)).asRl(),
        .target = .{ .x = 0, .y = 0 },
        .rotation = 0,
        .zoom = 1,
    };

    // -------- END SETUP --------

    rl.setTargetFPS(60);
    while (!rl.windowShouldClose()) {
        const delta_time = rl.getFrameTime();
        const mouse = rl.getMousePosition();
        const world_mouse = rl.getScreenToWorld2D(mouse, camera);
        color_wheel.update(mouse, ControlPannel.getWidth(f32), control_pannel.state);
        try control_pannel.update(mouse, &events);
        const isMouseOverCanvas = rl.checkCollisionPointRec(world_mouse, canvas.getVisiableRect(f32));

        if (rl.isMouseButtonDown(.mouse_button_right) and
            rl.checkCollisionPointRec(world_mouse, canvas.getVisiableRect(f32)) and
            !(color_wheel.state == .visible and isMouseOverCanvas))
        {
            var delta = rl.getMouseDelta();
            delta = delta.scale(-1.0 / camera.zoom);
            camera.target = camera.target.add(delta);
        }
        updateCameraZoom(&camera, mouse, world_mouse);

        if (rl.isKeyPressed(.key_f)) {
            state = .fill;
        } else if (rl.isKeyPressed(.key_b)) {
            state = .draw;
        } else if (rl.isKeyPressed(.key_l)) {
            state = .line;
        } else if (rl.isKeyPressed(.key_e)) {
            state = .erase;
        } else if (rl.isKeyPressed(.key_c) and color_wheel.state == .hidden) {
            try events.append(.open_color_wheel);
        } else if (rl.isKeyPressed(.key_c) and color_wheel.state == .visible) {
            try events.append(.close_color_wheel);
        }

        for (events.items) |e| {
            switch (e) {
                .draw => state = .draw,
                .draw_line => state = .line,
                .erase => state = .erase,
                .bucket => state = .fill,
                .color_picker => state = .color_picker,
                .close_control_pannel => control_pannel.hide(),
                .open_control_pannel => control_pannel.show(),
                .clicked => |we| switch (we) {
                    .width_input => state = .widget_width_input,
                    .height_input => state = .widget_height_input,
                    .frame_speed_input => state = .widget_frame_speed_input,
                },
                .open_color_wheel => color_wheel.show(),
                .close_color_wheel => color_wheel.hide(),
                .set_frame_speed => |speed| annimation.speed = speed,
                .set_canvas_width => |width| canvas.setWidth(width),
                .set_canvas_height => |height| canvas.setHeight(height),
                .open_save_file_browser => {
                    const file_path = try nfd.saveFileDialog(null, null);
                    if (file_path) |path| canvas.save(path);
                },
                .open_load_file_browser => {
                    const file_path = try nfd.openFileDialog(null, null);
                    if (file_path) |path| try canvas.load(path);
                },
                .rotate_left => canvas.rotateLeft(),
                .rotate_right => canvas.rotateRight(),
                .flip_vertical => canvas.flipVertical(),
                .flip_horizontal => canvas.flipHorizontal(),
                .display_canvas_grid => canvas.toggleGrid(),
                .play_animation => annimation.state = .play,
                .stop_animation => annimation.state = .stop,
                .next_frame => canvas.nextFrame(),
                .previous_frame => canvas.previousFrame(),
                .new_frame => try canvas.newFrame(),
                .delete_frame => canvas.deleteFrame(),
                .frame_tool => std.log.info("frame_tool", .{}),
                .selection_tool => std.log.info("selection_tool", .{}),
            }
        }

        events.clearRetainingCapacity();

        const isControlDown = rl.isKeyDown(.key_left_control) or rl.isKeyDown(.key_right_control);

        switch (state) {
            .draw => if (rl.isMouseButtonDown(.mouse_button_left) and !isControlDown) {
                _ = try canvas.insert(world_mouse.as(i32), color_wheel.getSelectedColor());
            } else if (isControlDown and rl.isMouseButtonReleased(.mouse_button_left) and isMouseOverCanvas) {
                try canvas.applyOverlay(color_wheel.getSelectedColor());
            } else if (isControlDown and isMouseOverCanvas) {
                try canvas.applyLineToOverlay(world_mouse.as(i32));
            } else {
                canvas.clearOverlay();
            },
            .line => if (rl.isMouseButtonDown(.mouse_button_left) and isMouseOverCanvas) {
                try canvas.applyLineToOverlay(world_mouse.as(i32));
            } else if (rl.isMouseButtonReleased(.mouse_button_left) and isMouseOverCanvas) {
                try canvas.applyOverlay(color_wheel.getSelectedColor());
            } else {
                canvas.clearOverlay();
            },
            .fill => if (rl.isMouseButtonPressed(.mouse_button_left)) {
                const starting_point = world_mouse.as(i32);
                const color = color_wheel.getSelectedColor();
                try algorithms.floodFill(allocator, &canvas, color, starting_point);
            },
            .erase => if (rl.isMouseButtonDown(.mouse_button_left)) {
                const cursor = world_mouse.as(i32).sub(canvas.bounding_box.getPos()).div(canvas.pixels_size);
                const frame = canvas.getCurrentFramePtr() orelse @panic("No frame");
                if (frame.bounding_box.contains(cursor)) {
                    _ = frame.pixels.remove(cursor);
                }
            },
            .color_picker => if (rl.isMouseButtonPressed(.mouse_button_left)) {
                const cursor = world_mouse.as(i32).sub(canvas.bounding_box.getPos()).div(canvas.pixels_size);
                const frame = canvas.getCurrentFramePtr() orelse @panic("No frame");
                if (frame.bounding_box.contains(cursor)) {
                    if (frame.pixels.get(cursor)) |color| {
                        color_wheel.setColor(color);
                    }
                }
            },
            .select => std.log.info("select\n", .{}),
            .widget_width_input => {
                try control_pannel.updateInput(.width_input, &state, &events);
            },
            .widget_height_input => {
                try control_pannel.updateInput(.height_input, &state, &events);
            },
            .widget_frame_speed_input => {
                try control_pannel.updateInput(.frame_speed_input, &state, &events);
            },
            .none => {},
        }

        annimation.nextFrame(&canvas, delta_time);

        // -------- DRAW --------
        rl.beginDrawing();
        rl.clearBackground(rl.Color.fromInt(0x21242bFF));
        defer rl.endDrawing();

        rl.beginMode2D(camera);
        const m = if (isMouseOverCanvas) world_mouse else null;
        canvas.draw(m);
        rl.endMode2D();

        color_wheel.draw();
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
    widget_frame_speed_input,
    none,
};

pub const Annimation = struct {
    const Self = @This();
    const State = enum {
        play,
        stop,
    };

    state: Self.State = .stop,
    speed: f32 = 2.0,
    frame_length: f32 = 0.0,

    pub fn nextFrame(self: *Self, canvas: *Canvas, delta: f32) void {
        self.frame_length += delta;
        if (self.state == .play and self.frame_length >= self.speed) {
            canvas.nextFrame();
            self.frame_length = 0.0;
        }
    }
};

fn updateCameraZoom(camera: *rl.Camera2D, pos: rl.Vector2(f32), worldMousePosition: rl.Vector2(f32)) void {
    const wheel = rl.getMouseWheelMove();

    if (wheel != 0) {
        const zoomIncrement = 0.1;
        camera.zoom += wheel * zoomIncrement;

        if (camera.zoom < 0.1) camera.zoom = 0.1; // Minimum zoom level
        if (camera.zoom > 3.0) camera.zoom = 3.0; // Maximum zoom level

        // Adjust camera target based on zoom
        const mousePositionAfter = rl.getScreenToWorld2D(pos, camera.*);
        camera.target.x -= (mousePositionAfter.x - worldMousePosition.x);
        camera.target.y -= (mousePositionAfter.y - worldMousePosition.y);
    }
}
