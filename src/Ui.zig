const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const utils = @import("utils.zig");
const cast = utils.cast;

const Dragable = @import("Dragable.zig").Dragable;
const MenuBar = @import("MenuBar.zig");
const Button = @import("Button.zig").Button;

const Self = @This();
color_picker: Dragable(*rl.Color),
color_picker_is_active: bool = false,
open_menu_button: Button(*bool) = undefined,
is_menu_open: bool = false,
// menu_bar: MenuBar,

pub fn init() Self {
    var button = Button(*bool).init(
        rl.loadTexture("assets/menu-icon.png"),
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

pub fn update(self: *Self, mouse_pos: rl.Vector2) bool {
    var active = false;
    self.keyboardHandler();
    if (self.color_picker_is_active) {
        active = self.color_picker.update(mouse_pos);
    }
    if (self.open_menu_button.update(mouse_pos, &self.is_menu_open)) {
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
    _ = rl.drawRectangle(0, 0, 100, rl.getScreenHeight(), rl.Color.violet);
}
