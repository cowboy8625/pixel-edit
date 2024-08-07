const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const utils = @import("utils.zig");
const cast = utils.cast;
const assets = @import("assets.zig");

const Context = @import("Context.zig");
const Dragable = @import("Dragable.zig").Dragable;
const MenuBar = @import("MenuBar.zig");
const Button = @import("Button.zig").Button;
const FileManager = @import("FileManager.zig");
const Grid = @import("Grid.zig").Grid;
const Widget = @import("Widget.zig").Widget;

// width in buttons
const WIDTH = 5;
// height in buttons
const HEIGHT = 20;
const UiGrid = Grid(*Context, WIDTH, HEIGHT);
const Self = @This();

is_menu_open: bool = false,
menu_rect: rl.Rectangle,
grid: UiGrid,
open_menu_button: Button(*bool),
save_file_manager: FileManager,
load_file_manager: FileManager,
color_picker: Dragable(*rl.Color),

pub fn init(menu_rect: rl.Rectangle) Self {
    var grid = UiGrid{
        .update_callback = struct {
            fn update(grid: *UiGrid, mouse_pos: rl.Vector2, context: *Context) anyerror!void {
                var active = false;
                var iter = grid.iterator();

                while (iter.next()) |*widget| {
                    if (widget.*.update(mouse_pos, context)) {
                        active = true;
                    }
                }
                context.flags.gui_active = active;
            }
        }.update,
        .draw_callback = struct {
            fn cords(i: usize) rl.Vector2 {
                return .{
                    .x = cast(f32, @mod(i, WIDTH)),
                    .y = cast(f32, @divFloor(i, HEIGHT)),
                };
            }
            fn draw(grid: *UiGrid, pos: rl.Vector2) anyerror!void {
                var iter = grid.iterator();
                var i: usize = 0;
                const padding = 5;
                const item_size = 16;

                while (iter.next()) |*widget| {
                    const row = cast(f32, @divFloor(i, WIDTH));
                    const col = cast(f32, @mod(i, WIDTH));

                    const widget_pos = rl.Vector2{
                        .x = pos.x + (col * (item_size + padding)),
                        .y = pos.y + (row * (item_size + padding)),
                    };

                    widget.*.pos = widget_pos;
                    widget.*.draw();
                    i += 1;
                }
            }
        }.draw,
        .deinit_callback = struct {
            fn deinit(grid: *UiGrid) void {
                var iter = grid.iterator();
                while (iter.next()) |*widget| {
                    widget.*.deinit();
                }
            }
        }.deinit,
    };

    grid.push(Button(*Context).initWithTextureNoVec(
        assets.loadTexture(assets.LOAD_ICON),
        struct {
            fn callback(arg: *Context) void {
                arg.flags.load_file_manager_is_open = !arg.flags.load_file_manager_is_open;
            }
        }.callback,
    ));

    grid.push(Button(*Context).initWithTextureNoVec(
        assets.loadTexture(assets.SAVE_ICON),
        struct {
            fn callback(arg: *Context) void {
                arg.flags.save_file_manager_is_open = !arg.flags.save_file_manager_is_open;
            }
        }.callback,
    ));

    grid.push(Button(*Context).initWithTextureNoVec(
        assets.loadTexture(assets.GRID_ICON),
        struct {
            fn callback(arg: *Context) void {
                arg.flags.draw_grid = !arg.flags.draw_grid;
            }
        }.callback,
    ));

    grid.push(Button(*Context).initWithTextureNoVec(
        assets.loadTexture(assets.COLOR_PICKER_ICON),
        struct {
            fn callback(arg: *Context) void {
                arg.flags.color_picker_is_open = !arg.flags.color_picker_is_open;
            }
        }.callback,
    ));

    grid.push(Button(*Context).initWithTextureNoVec(
        assets.loadTexture(assets.LINE_TOOL_ICON),
        struct {
            fn callback(arg: *Context) void {
                arg.mode = .Line;
            }
        }.callback,
    ));

    grid.push(Button(*Context).initWithTextureNoVec(
        assets.loadTexture(assets.BUCKET_TOOL_ICON),
        struct {
            fn callback(arg: *Context) void {
                arg.mode = .Fill;
            }
        }.callback,
    ));

    grid.push(Button(*Context).initWithTextureNoVec(
        assets.loadTexture(assets.PENCIL_TOOL_ICON),
        struct {
            fn callback(arg: *Context) void {
                arg.mode = .Draw;
            }
        }.callback,
    ));

    var open_menu_button = Button(*bool).initWithTexture(
        assets.loadTexture(assets.MENU_ICON),
        .{ .x = 2, .y = 2 },
        struct {
            fn callback(arg: *bool) void {
                arg.* = !arg.*;
            }
        }.callback,
    );

    open_menu_button.setHitBox(struct {
        fn callback(rect: rl.Rectangle) rl.Rectangle {
            return .{
                .x = rect.x + 10,
                .y = rect.y + 10,
                .width = @divFloor(rect.width, 10),
                .height = @divFloor(rect.height, 10),
            };
        }
    }.callback);
    errdefer open_menu_button.deinit();

    return .{
        .grid = grid,
        .open_menu_button = open_menu_button,
        .menu_rect = menu_rect,
        .save_file_manager = FileManager.init("Save", struct {
            fn action(self: *FileManager, context: *Context) void {
                self.close_with_picked_file = false;
                self.is_open = false;
                const path: []const u8 = self.text_input.text.chars[0..self.text_input.text.len];
                context.path = path;
                context.path_action = .Save;
            }
        }.action),
        .load_file_manager = FileManager.init("Load", struct {
            fn action(self: *FileManager, context: *Context) void {
                self.close_with_picked_file = false;
                self.is_open = false;
                const path: []const u8 = self.text_input.text.chars[0..self.text_input.text.len];
                context.path = path;
                context.path_action = .Load;
            }
        }.action),
        .color_picker = Dragable(*rl.Color).init(
            .{ .x = 200, .y = 10, .width = 200, .height = 200 },
            .mouse_button_right,
            struct {
                fn callback(rect: rl.Rectangle, arg: *rl.Color) void {
                    _ = rg.guiColorPicker(rect, "Color Picker", arg);
                }
            }.callback,
        ),
    };
}

pub fn deinit(self: *Self) void {
    self.grid.deinit();
    self.open_menu_button.deinit();
    self.save_file_manager.deinit();
}

fn keyboardHandler(_: *Self, context: *Context) void {
    if (rl.isKeyDown(.key_left_shift)) {
        context.mode = .Line;
    } else if (rl.isKeyReleased(.key_left_shift)) {
        context.mode = .Draw;
    }
}

pub fn update(self: *Self, mouse_pos: rl.Vector2, context: *Context) !void {
    if (rl.checkCollisionPointRec(mouse_pos, self.menu_rect) and self.is_menu_open) {
        context.flags.gui_active = true;
    }
    try self.grid.update(mouse_pos, context);
    _ = self.open_menu_button.update(mouse_pos, &self.is_menu_open);
    self.keyboardHandler(context);

    self.save_file_manager.is_open = context.flags.save_file_manager_is_open;
    if (try self.save_file_manager.update(mouse_pos, context)) {
        context.flags.gui_active = true;
    }
    context.flags.save_file_manager_is_open = self.save_file_manager.is_open;

    self.load_file_manager.is_open = context.flags.load_file_manager_is_open;
    if (try self.load_file_manager.update(mouse_pos, context)) {
        context.flags.gui_active = true;
    }
    context.flags.load_file_manager_is_open = self.load_file_manager.is_open;

    if (self.color_picker.update(mouse_pos)) {
        context.flags.gui_active = true;
    }
}

// FIXME: Remove the passing of context
pub fn draw(self: *Self, context: *Context) !void {
    try drawMenu(self, context);
    try self.save_file_manager.draw();
    try self.load_file_manager.draw();
    self.open_menu_button.draw();
    if (context.flags.color_picker_is_open) {
        self.color_picker.draw(&context.brush.color);
    }
}

pub fn drawMenu(self: *Self, _: *Context) !void {
    if (!self.is_menu_open) return;
    _ = rl.drawRectangleRec(self.menu_rect, rl.Color.init(0x32, 0x30, 0x2f, 0xff));

    const pos = .{
        .x = self.open_menu_button.pos.x,
        .y = self.open_menu_button.pos.y + self.open_menu_button.hitbox.height + 20,
    };
    try self.grid.draw(pos);
    // self.toggle_grid.draw();
    // self.file_manager_open_button.draw();
    // self.toggle_file_picker.draw();
    // self.line_tool_button.draw();
    // self.bucket_tool_button.draw();
}
