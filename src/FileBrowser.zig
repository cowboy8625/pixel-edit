const std = @import("std");
const rl = @import("rl/mod.zig");
const widget = @import("widget.zig");
const Asset = @import("assets.zig");
const Button = widget.Button(Event);
const Label = widget.Label(Event);
pub const Event = union(enum) {
    cancel: void,
    open: void,
    save: void,
    select: usize,
};

pub const Mode = enum {
    open,
    save,
};

pub const MAX_FILE_PATH = 256;
const Self = @This();

mode: Mode,
path: [MAX_FILE_PATH]u8,
path_len: usize,
allocator: std.mem.Allocator,
buttons: std.MultiArrayList(Button),
labels: std.MultiArrayList(Label),

pub fn init(allocator: std.mem.Allocator, mode: Mode) !Self {
    var self: Self = .{
        .mode = mode,
        .path = [_]u8{0} ** MAX_FILE_PATH,
        .path_len = 0,
        .allocator = allocator,
        .buttons = std.MultiArrayList(Button){},
        .labels = std.MultiArrayList(Label){},
    };

    self.path[0] = '.';
    self.path_len = 1;

    try self.buttons.append(self.allocator, .{
        .name = "Cancel",
        .event = .cancel,
        .action_left_click = struct {
            fn f(button: *Button) Event {
                _ = button;
                return .cancel;
            }
        }.f,
        .hover_color = rl.Color.fromInt(0x343028FF),
        .texture = Asset.loadTexture(Asset.SAVE_ICON),
    });

    return self;
}

pub fn deinit(self: *Self) void {
    for (0..self.labels.len) |i| {
        var label = self.labels.get(i);
        label.deinit(self.allocator);
    }
    self.labels.deinit(self.allocator);
    for (0..self.buttons.len) |i| {
        rl.unloadTexture(self.buttons.items(.texture)[i]);
    }
    self.buttons.deinit(self.allocator);
}

fn updateButtons(self: *Self, mouse_pos: rl.Vector2(f32), events: *std.ArrayList(Event)) !void {
    for (0..self.buttons.len) |i| {
        const pos = self.getButtonVector(i).as(i32);
        var button = self.buttons.get(i);
        const rect = rl.Rectangle(i32).from2vec2(
            pos,
            .{
                .x = button.texture.width,
                .y = button.texture.height,
            },
        );
        const is_hovered = rl.checkCollisionPointRec(mouse_pos, rect.as(f32));
        if (is_hovered and rl.isMouseButtonPressed(.mouse_button_left)) {
            const current_event = button.event;
            const new_event = button.action_left_click(&button);
            button.event = new_event;
            try events.append(current_event);
            self.buttons.items(.hovered)[i] = false;
        }
        button.hovered = is_hovered;
        self.buttons.set(i, button);
    }
}

fn getButtonVector(self: *const Self, i: usize) rl.Vector2(f32) {
    return switch (self.buttons.items(.event)[i]) {
        .cancel => rl.Vector2(i32).init(rl.getScreenWidth() - 100, rl.getScreenHeight() - 100).as(f32),
        .open => rl.Vector2(f32).init(0, 0),
        .save => rl.Vector2(f32).init(0, 0),
        else => unreachable,
    };
}

fn isImage(path: []const u8) bool {
    return std.mem.endsWith(u8, path, ".png") or
        std.mem.endsWith(u8, path, ".jpeg") or
        std.mem.endsWith(u8, path, ".jpg");
}

fn createLabelsForCurrentPath(self: *Self) !void {
    const cwd = std.fs.cwd();
    var dir = try cwd.openDir(self.path[0..self.path_len], .{ .iterate = true });
    defer dir.close();

    var iter = dir.iterate();

    while (try iter.next()) |entry| {
        switch (entry.kind) {
            .directory => {
                const index = self.labels.len;
                try self.labels.append(self.allocator, .{
                    .label = try self.allocator.dupeZ(u8, entry.name),
                    .event = .{ .select = index },
                    .action_left_click = struct {
                        fn f(l: *Label) Event {
                            return l.event;
                        }
                    }.f,
                    .hover_color = rl.Color.fromInt(0x343028FF),
                });
            },
            .file => if (isImage(entry.name)) {
                const index = self.labels.len;
                try self.labels.append(self.allocator, .{
                    .label = try self.allocator.dupeZ(u8, entry.name),
                    .event = .{ .select = index },
                    .action_left_click = struct {
                        fn f(l: *Label) Event {
                            return l.event;
                        }
                    }.f,
                    .hover_color = rl.Color.fromInt(0x343028FF),
                });
            } else {
                continue;
            },
            else => continue,
        }
        std.log.info("{s}: {s}", .{ @tagName(entry.kind), entry.name });
    }
}

fn updateLabels(self: *Self, mouse_pos: rl.Vector2(f32), events: *std.ArrayList(Event)) !void {
    const font = rl.getFontDefault();
    const font_size = 20;
    for (0..self.labels.len) |i| {
        const pos = .{ .x = 10, .y = rl.cast(f32, i * 20) };
        var label = self.labels.get(i);
        const text_dimentions = rl.measureTextEx(font, label.label, font_size, 1);
        const rect = rl.Rectangle(f32).from2vec2(
            pos,
            text_dimentions,
        );
        const is_hovered = rl.checkCollisionPointRec(mouse_pos, rect);
        if (is_hovered and rl.isMouseButtonPressed(.mouse_button_left)) {
            const current_event = label.event;
            const new_event = label.action_left_click(&label);
            label.event = new_event;
            try events.append(current_event);
            self.labels.items(.hovered)[i] = false;
        }
        label.hovered = is_hovered;
        self.labels.set(i, label);
    }
}

fn drawLabels(self: *const Self) void {
    const font_size = 20;
    for (0..self.labels.len) |i| {
        const x = 10;
        const y: i32 = @intCast(i * 20);
        const label = self.labels.items(.label)[i];
        rl.drawText(label, x, y, font_size, rl.Color.white);
    }
}

fn drawButton(self: *const Self) void {
    for (0..self.buttons.len) |i| {
        const event = self.buttons.items(.event)[i];
        if (event == .save and self.mode == .open) continue;
        if (event == .open and self.mode == .save) continue;
        const texture = self.buttons.items(.texture)[i];
        const pos = self.getButtonVector(i);
        rl.drawTextureEx(texture, pos, 0, 1, rl.Color.white);
    }
}

pub fn open(self: *Self) !void {
    var events = std.ArrayList(Event).init(self.allocator);
    defer events.deinit();

    try self.createLabelsForCurrentPath();

    while (!rl.windowShouldClose()) {
        const mouse = rl.getMousePosition();

        if (rl.isKeyReleased(.key_enter)) break;

        for (events.items) |event| {
            switch (event) {
                .cancel => return,
                .open => {
                    std.log.info("open", .{});
                },
                .save => {
                    std.log.info("save", .{});
                },
                .select => |idx| {
                    const cwd = std.fs.cwd();
                    var dir = try cwd.openDir(self.path[0..self.path_len], .{ .iterate = true });
                    defer dir.close();

                    var iter = dir.iterate();

                    var i: usize = 0;
                    while (try iter.next()) |entry| {
                        switch (entry.kind) {
                            .directory => if (i == idx) {
                                self.path[self.path_len] = '/';
                                self.path_len += 1;
                                std.mem.copyForwards(u8, self.path[self.path_len..], entry.name);
                                self.path_len += entry.name.len;
                                break;
                            } else {
                                i += 1;
                            },
                            .file => if (i == idx) {
                                self.path[self.path_len] = '/';
                                self.path_len += 1;
                                std.mem.copyForwards(u8, self.path[self.path_len..], entry.name);
                                self.path_len += entry.name.len;
                                break;
                            } else {
                                i += 1;
                            },
                            else => continue,
                        }
                    }
                    std.log.info("select {d}", .{idx});
                    std.log.info("{s}", .{self.path[0..self.path_len]});
                },
            }
        }
        events.clearRetainingCapacity();

        try self.updateButtons(mouse, &events);
        try self.updateLabels(mouse, &events);

        rl.beginDrawing();
        rl.clearBackground(rl.Color.fromInt(0x21242bFF));
        defer rl.endDrawing();

        self.drawLabels();

        self.drawButton();
    }
}
