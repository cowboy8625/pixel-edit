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

const Self = @This();
color_picker: Dragable(*rl.Color),
color_picker_is_active: bool = false,
open_menu_button: Button(*bool) = undefined,
is_menu_open: bool = false,
toggle_grid: Button(*bool) = undefined,
// menu_bar: MenuBar,

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
        .{ .x = 2, .y = button.pos.y + button.hitbox.height + 20 },
        struct {
            fn callback(arg: *bool) void {
                arg.* = !arg.*;
            }
        }.callback,
    );

    return .{
        .color_picker = Dragable(*rl.Color).init(
            .{ .x = 10, .y = 10, .width = 200, .height = 200 },
            .mouse_button_middle,
            struct {
                fn callback(rect: rl.Rectangle, arg: *rl.Color) void {
                    _ = rg.guiColorPicker(rect, "Color Picker", arg);
                }
            }.callback,
        ),
        .open_menu_button = button,
        .toggle_grid = toggle_grid,

        // .menu_bar = MenuBar.init(),
    };
}

pub fn deinit(self: *Self) void {
    self.open_menu_button.deinit();
}

fn keyboardHandler(self: *Self) void {
    if (rl.isKeyReleased(.key_c)) {
        self.color_picker_is_active = !self.color_picker_is_active;
    }
}

pub fn update(self: *Self, mouse_pos: rl.Vector2, settings: *Settings) bool {
    var active = false;
    self.keyboardHandler();
    if (self.color_picker_is_active) {
        active = self.color_picker.update(mouse_pos);
    }
    if (self.open_menu_button.update(mouse_pos, &self.is_menu_open)) {
        active = true;
    }
    if (self.toggle_grid.update(mouse_pos, &settings.draw_grid)) {
        active = true;
    }
    return active;
}

pub fn draw(self: *Self, brush_color: *rl.Color) void {
    drawMenu(self);
    if (self.color_picker_is_active) self.color_picker.draw(brush_color);
    self.open_menu_button.draw();

    // self.menu_bar.draw();
}

pub fn drawMenu(self: *Self) void {
    if (!self.is_menu_open) return;
    // const start_y = cast(i32, self.open_menu_button.hitbox.y + self.open_menu_button.hitbox.height) + 10;
    _ = rl.drawRectangle(0, 0, 100, rl.getScreenHeight(), rl.Color.init(0x32, 0x30, 0x2f, 0xff));
    self.toggle_grid.draw();
}
