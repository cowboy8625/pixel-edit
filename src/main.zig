const std = @import("std");
const Asset = @import("assets.zig");
const rl = @import("rl/mod.zig");
const event = @import("event.zig");
const ControlPannel = @import("ControlPannel.zig");

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

const Frame = struct {
    const Self = @This();
    bounding_box: rl.Rectangle(i32),
    pixels: std.AutoHashMap(rl.Vector2(i32), rl.Color),

    pub fn init(bounding_box: rl.Rectangle(i32), allocator: std.mem.Allocator) Self {
        return Self{
            .bounding_box = bounding_box,
            .pixels = std.AutoHashMap(rl.Vector2(i32), rl.Color).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.pixels.deinit();
    }

    pub fn insert(self: *Self, pixel: rl.Vector2(i32), color: rl.Color) !bool {
        if (!self.bounding_box.contains(pixel)) return false;
        try self.pixels.put(pixel, color);
        return true;
    }
};

const Canvas = struct {
    const Self = @This();
    bounding_box: rl.Rectangle(i32),
    frames: std.ArrayList(Frame),
    current_frame: usize,
    // Defaults
    pixels_size: i32 = 16,
    selected_color: rl.Color = rl.Color.red,

    pub fn init(bounding_box: rl.Rectangle(i32), allocator: std.mem.Allocator) !Self {
        var self = Self{
            .bounding_box = bounding_box,
            .frames = std.ArrayList(Frame).init(allocator),
            .current_frame = 0,
        };
        errdefer self.deinit();

        const bb_size = bounding_box.getSize().sub(1).mul(self.pixels_size);
        const bb_pos = bounding_box.getPos();
        const bb = rl.Rectangle(i32).from2vec2(bb_pos, bb_size);
        self.bounding_box = bb;

        const frame_bb = rl.Rectangle(i32).from2vec2(.{ .x = 0, .y = 0 }, bounding_box.getSize().sub(1));
        const frame = Frame.init(frame_bb, allocator);
        try self.frames.append(frame);

        return self;
    }

    pub fn deinit(self: *Self) void {
        for (self.frames.items) |*frame| {
            frame.deinit();
        }
        self.frames.deinit();
    }

    pub fn getCurrentFramePtr(self: *Self) ?*Frame {
        if (self.current_frame >= self.frames.items.len) return null;
        return &self.frames.items[self.current_frame];
    }

    pub fn getCurrentFrameConstPtr(self: *const Self) ?*const Frame {
        if (self.current_frame >= self.frames.items.len) return null;
        return &self.frames.items[self.current_frame];
    }

    pub fn insert(self: *Self, cursor: rl.Vector2(i32)) !bool {
        if (!self.bounding_box.contains(cursor)) return false;
        const frame = self.getCurrentFramePtr() orelse return false;
        const pixel = cursor.sub(self.bounding_box.getPos()).div(self.pixels_size);
        return try frame.insert(pixel, self.selected_color);
    }

    pub fn draw(self: *const Self) void {
        rl.drawRectangleRec(
            self.bounding_box.as(f32),
            rl.Color.ray_white,
        );
        const frame = self.getCurrentFrameConstPtr() orelse return;
        var iter = frame.pixels.iterator();
        while (iter.next()) |kv| {
            const pos = kv.key_ptr.*.mul(self.pixels_size).add(self.bounding_box.getPos());
            const color = kv.value_ptr.*;
            const rect = rl.Rectangle(i32).from2vec2(pos, .{ .x = self.pixels_size, .y = self.pixels_size });
            rl.drawRectangleRec(rect.as(f32), color);
        }
    }
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

    rl.setTargetFPS(60);
    while (!rl.windowShouldClose()) {
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

        canvas.draw();
        control_pannel.draw();
    }
}
