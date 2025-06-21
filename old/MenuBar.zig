const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const utils = @import("utils.zig");
const cast = utils.cast;

pub const MenuItem = struct {
    name: []const u8,
    options: []const []const u8,
    optionsCount: usize,
    currentOption: bool = false,
};

const MENU_ITEM_COUNT = 4;
const Self = @This();

const fileOptions: []const []const u8 = &[_][]const u8{ "New", "Open", "Save", "Exit" };
const toolOptions: []const []const u8 = &[_][]const u8{ "Pencil", "Eraser", "Bucket", "Line", "Rec" };
const editOptions: []const []const u8 = &[_][]const u8{ "Undo", "Redo", "Cut", "Copy", "Paste" };
const viewOptions: []const []const u8 = &[_][]const u8{ "Zoom In", "Zoom Out", "Reset Zoom" };

menuItems: [MENU_ITEM_COUNT]MenuItem = [_]MenuItem{
    .{ .name = "File", .options = fileOptions, .optionsCount = 4 },
    .{ .name = "Tool", .options = toolOptions, .optionsCount = 5 },
    .{ .name = "Edit", .options = editOptions, .optionsCount = 5 },
    .{ .name = "View", .options = viewOptions, .optionsCount = 3 },
},

pub fn init() Self {
    return .{};
}

pub fn draw(self: *Self) void {
    const menuBarRect: rl.Rectangle = .{
        .x = 0,
        .y = 0,
        .width = cast(f32, rl.getScreenWidth()),
        .height = 30,
    };
    drawMenuBar(&self.menuItems, self.menuItems.len, menuBarRect);
}

fn drawMenuBar(menuItems: *[MENU_ITEM_COUNT]MenuItem, menuItemCount: usize, barRect: rl.Rectangle) void {
    const spacing = 10;
    var xOffset = cast(usize, barRect.x) + spacing;
    const yOffset = cast(usize, barRect.y);

    for (0..menuItemCount) |i| {
        const item = &menuItems[i];
        const ctext: [*:0]const u8 = @ptrCast(item.name);
        const w = cast(f32, rl.measureText(ctext, 20) + 40);
        const buttonRect: rl.Rectangle = .{
            .x = cast(f32, xOffset),
            .y = cast(f32, yOffset),
            .width = w,
            .height = 30,
        };

        const dropdownRect: rl.Rectangle = .{
            .x = cast(f32, xOffset),
            .y = cast(f32, yOffset + 30),
            .width = 150,
            .height = cast(f32, item.optionsCount * 30),
        };
        if (item.currentOption and rl.isMouseButtonReleased(.mouse_button_left) and !rl.checkCollisionPointRec(rl.getMousePosition(), dropdownRect)) {
            item.currentOption = false;
            return;
        }

        if (cast(bool, rg.guiButton(buttonRect, ctext))) {
            item.currentOption = !item.currentOption;
        }

        if (item.currentOption) {
            _ = rg.guiPanel(dropdownRect, "");

            for (0..item.optionsCount) |j| {
                const optionRect: rl.Rectangle = .{
                    .x = cast(f32, xOffset + 10),
                    .y = cast(f32, yOffset + 30 + j * 30),
                    .width = 130,
                    .height = 30,
                };
                const option_text: [*:0]const u8 = @ptrCast(item.options[j]);
                if (cast(bool, rg.guiButton(optionRect, option_text))) {
                    item.currentOption = false; // Close dropdown after selection
                }
            }
        }

        xOffset += cast(usize, buttonRect.width) + spacing;
    }
}
