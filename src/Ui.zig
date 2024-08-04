const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const utils = @import("utils.zig");
const cast = utils.cast;
const assets = @import("assets.zig");

const Settings = @import("Settings.zig");
const Dragable = @import("Dragable.zig").Dragable;
const MenuBar = @import("MenuBar.zig");
const Button = @import("Button.zig").Button;
const FileManager = @import("FileManager.zig");

const Self = @This();
color_picker: Dragable(*rl.Color),
color_picker_is_active: bool = false,
toggle_file_picker: Button(*bool),
open_menu_button: Button(*bool),
is_menu_open: bool = false,
toggle_grid: Button(*bool),
file_manager_open_button: Button(*bool),
file_manager: FileManager,
line_tool_button: Button(*bool),

pub fn init() Self {
    var button = Button(*bool).initWithTexture(
        assets.loadTexture(assets.MENU_ICON),
        .{ .x = 2, .y = 2 },
        struct {
            fn callback(arg: *bool) void {
                arg.* = !arg.*;
            }
        }.callback,
    );
    button.setHitBox(struct {
        fn callback(rect: rl.Rectangle) rl.Rectangle {
            return .{
                .x = rect.x + 10,
                .y = rect.y + 10,
                .width = @divFloor(rect.width, 10),
                .height = @divFloor(rect.height, 10),
            };
        }
    }.callback);
    errdefer button.deinit();

    const toggle_grid = Button(*bool).initWithTexture(
        assets.loadTexture(assets.GRID_ICON),
        .{
            .x = 2,
            .y = button.pos.y + button.hitbox.height + 20,
        },
        struct {
            fn callback(arg: *bool) void {
                arg.* = !arg.*;
            }
        }.callback,
    );
    const file_manager_open_button = Button(*bool).initWithTexture(
        assets.loadTexture(assets.SAVE_ICON),
        .{
            .x = toggle_grid.pos.x + toggle_grid.hitbox.width + 5,
            .y = toggle_grid.pos.y,
        },
        struct {
            fn callback(arg: *bool) void {
                arg.* = !arg.*;
            }
        }.callback,
    );
    const toggle_file_picker = Button(*bool).initWithTexture(
        assets.loadTexture(assets.COLOR_PICKER_ICON),
        .{
            .x = file_manager_open_button.pos.x + file_manager_open_button.hitbox.width + 5,
            .y = file_manager_open_button.pos.y,
        },
        struct {
            fn callback(arg: *bool) void {
                arg.* = !arg.*;
            }
        }.callback,
    );

    const line_tool_button = Button(*bool).initWithTexture(
        assets.loadTexture(assets.LINE_TOOL_ICON),
        .{
            .x = toggle_file_picker.pos.x + toggle_file_picker.hitbox.width + 5,
            .y = toggle_file_picker.pos.y,
        },
        struct {
            fn callback(arg: *bool) void {
                arg.* = !arg.*;
            }
        }.callback,
    );

    return .{
        .color_picker = Dragable(*rl.Color).init(
            .{ .x = 200, .y = 10, .width = 200, .height = 200 },
            .mouse_button_middle,
            struct {
                fn callback(rect: rl.Rectangle, arg: *rl.Color) void {
                    _ = rg.guiColorPicker(rect, "Color Picker", arg);
                }
            }.callback,
        ),
        .open_menu_button = button,
        .toggle_grid = toggle_grid,
        .toggle_file_picker = toggle_file_picker,
        .file_manager = FileManager.init(),
        .file_manager_open_button = file_manager_open_button,
        .line_tool_button = line_tool_button,
        // .menu_bar = MenuBar.init(),
    };
}

pub fn deinit(self: *Self) void {
    self.open_menu_button.deinit();
    self.toggle_grid.deinit();
    self.toggle_file_picker.deinit();
    self.file_manager.deinit();
    self.file_manager_open_button.deinit();
    self.line_tool_button.deinit();
}

fn keyboardHandler(_: *Self, settings: *Settings) void {
    if (rl.isKeyDown(.key_left_shift)) {
        settings.line_tool = true;
    } else {
        settings.line_tool = false;
    }
}

pub fn update(self: *Self, mouse_pos: rl.Vector2, settings: *Settings) !bool {
    var active = false;
    self.keyboardHandler(settings);

    if (self.color_picker_is_active) {
        active = self.color_picker.update(mouse_pos);
    }

    if (self.open_menu_button.update(mouse_pos, &self.is_menu_open)) {
        active = true;
    }

    if (try self.file_manager.update(mouse_pos)) {
        active = true;
    }

    if (!self.is_menu_open) return active;

    if (self.toggle_grid.update(mouse_pos, &settings.draw_grid)) {
        active = true;
    }

    if (self.file_manager_open_button.update(mouse_pos, &self.file_manager.is_open)) {
        active = true;
    }

    if (self.toggle_file_picker.update(mouse_pos, &self.color_picker_is_active)) {
        active = true;
    }
    if (self.line_tool_button.update(mouse_pos, &settings.line_tool)) {
        active = true;
    }
    return active;
}

pub fn draw(self: *Self, brush_color: *rl.Color) !void {
    drawMenu(self);
    if (self.color_picker_is_active) self.color_picker.draw(brush_color);
    self.open_menu_button.draw();
    try self.file_manager.draw();
}

pub fn drawMenu(self: *Self) void {
    if (!self.is_menu_open) return;
    _ = rl.drawRectangle(0, 0, 100, rl.getScreenHeight(), rl.Color.init(0x32, 0x30, 0x2f, 0xff));
    self.toggle_grid.draw();
    self.file_manager_open_button.draw();
    self.toggle_file_picker.draw();
    self.line_tool_button.draw();
}
