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
color_picker_is_open: bool = false,
menu_rect: rl.Rectangle,
grid: UiGrid,
open_menu_button: Button(*Context),
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
            fn callback(ctx: *Context) void {
                ctx.command = if (ctx.flags.load_file_manager_is_open) .CloseLoadFileManager else .OpenLoadFileManager;
            }
        }.callback,
    ));

    grid.push(Button(*Context).initWithTextureNoVec(
        assets.loadTexture(assets.SAVE_ICON),
        struct {
            fn callback(ctx: *Context) void {
                ctx.command = if (ctx.flags.save_file_manager_is_open) .CloseSaveFileManager else .OpenSaveFileManager;
            }
        }.callback,
    ));

    grid.push(Button(*Context).initWithTextureNoVec(
        assets.loadTexture(assets.GRID_ICON),
        struct {
            fn callback(ctx: *Context) void {
                ctx.command = if (ctx.flags.draw_grid) .TurnGridOff else .TurnGridOn;
            }
        }.callback,
    ));

    grid.push(Button(*Context).initWithTextureNoVec(
        assets.loadTexture(assets.ROTATE_LEFT_ICON),
        struct {
            fn callback(ctx: *Context) void {
                ctx.command = .RotateLeft;
            }
        }.callback,
    ));

    grid.push(Button(*Context).initWithTextureNoVec(
        assets.loadTexture(assets.ROTATE_RIGHT_ICON),
        struct {
            fn callback(ctx: *Context) void {
                ctx.command = .RotateRight;
            }
        }.callback,
    ));

    grid.push(Button(*Context).initWithTextureNoVec(
        assets.loadTexture(assets.LEFT_ARROW_ICON),
        struct {
            fn callback(arg: *Context) void {
                arg.command = .FrameLeft;
            }
        }.callback,
    ));

    grid.push(Button(*Context).initWithTextureNoVec(
        assets.loadTexture(assets.PLAY_ICON),
        struct {
            fn callback(arg: *Context) void {
                arg.command = if (arg.command == .Play) .Stop else .Play;
            }
        }.callback,
    ));

    grid.push(Button(*Context).initWithTextureNoVec(
        assets.loadTexture(assets.RIGHT_ARROW_ICON),
        struct {
            fn callback(arg: *Context) void {
                arg.command = .FrameRight;
            }
        }.callback,
    ));

    grid.push(Button(*Context).initWithTextureNoVec(
        assets.loadTexture(assets.FLIP_HORIZONTAL_ICON),
        struct {
            fn callback(ctx: *Context) void {
                ctx.command = .FlipHorizontal;
            }
        }.callback,
    ));

    grid.push(Button(*Context).initWithTextureNoVec(
        assets.loadTexture(assets.FLIP_VERTICAL_ICON),
        struct {
            fn callback(ctx: *Context) void {
                ctx.command = .FlipVertical;
            }
        }.callback,
    ));

    grid.push(Button(*Context).initWithTextureNoVec(
        assets.loadTexture(assets.PENCIL_TOOL_ICON),
        struct {
            fn callback(arg: *Context) void {
                arg.brush.mode = .Draw;
            }
        }.callback,
    ));

    grid.push(Button(*Context).initWithTextureNoVec(
        assets.loadTexture(assets.BUCKET_TOOL_ICON),
        struct {
            fn callback(arg: *Context) void {
                arg.brush.mode = .Fill;
            }
        }.callback,
    ));

    grid.push(Button(*Context).initWithTextureNoVec(
        assets.loadTexture(assets.LINE_TOOL_ICON),
        struct {
            fn callback(arg: *Context) void {
                arg.brush.mode = .Line;
            }
        }.callback,
    ));

    grid.push(Button(*Context).initWithTextureNoVec(
        assets.loadTexture(assets.COLOR_WHEEL_ICON),
        struct {
            fn callback(ctx: *Context) void {
                ctx.command = if (ctx.flags.color_picker_is_open) .CloseColorPicker else .OpenColorPicker;
            }
        }.callback,
    ));

    grid.push(Button(*Context).initWithTextureNoVec(
        assets.loadTexture(assets.COLOR_PICKER_ICON),
        struct {
            fn callback(ctx: *Context) void {
                ctx.brush.mode = .ColorPicker;
            }
        }.callback,
    ));

    grid.push(Button(*Context).initWithTextureNoVec(
        assets.loadTexture(assets.ERASER_TOOL_ICON),
        struct {
            fn callback(arg: *Context) void {
                arg.brush.mode = .Erase;
            }
        }.callback,
    ));

    var open_menu_button = Button(*Context).initWithTexture(
        assets.loadTexture(assets.MENU_ICON),
        .{ .x = 2, .y = 2 },
        struct {
            fn callback(ctx: *Context) void {
                ctx.command = if (ctx.flags.menu_is_open) .CloseMenu else .OpenMenu;
            }
        }.callback,
    );

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

pub fn openMenu(self: *Self) void {
    self.is_menu_open = true;
}

pub fn closeMenu(self: *Self) void {
    self.is_menu_open = false;
}

pub fn openColorPicker(self: *Self) void {
    self.color_picker_is_open = true;
}

pub fn closeColorPicker(self: *Self) void {
    self.color_picker_is_open = false;
}

pub fn openSaveFileManager(self: *Self) void {
    self.save_file_manager.is_open = true;
}

pub fn closeSaveFileManager(self: *Self) void {
    self.save_file_manager.is_open = false;
}

pub fn openLoadFileManager(self: *Self) void {
    self.load_file_manager.is_open = true;
}

pub fn closeLoadFileManager(self: *Self) void {
    self.load_file_manager.is_open = false;
}

fn keyboardHandler(_: *Self, context: *Context) void {
    if (rl.isKeyDown(.key_left_shift)) {
        context.brush.mode = .Line;
    } else if (rl.isKeyReleased(.key_left_shift)) {
        context.brush.mode = .Draw;
    }
}

pub fn update(self: *Self, mouse_pos: rl.Vector2, context: *Context) !void {
    if (rl.checkCollisionPointRec(mouse_pos, self.menu_rect) and self.is_menu_open) {
        context.flags.gui_active = true;
    }
    try self.grid.update(mouse_pos, context);
    _ = self.open_menu_button.update(mouse_pos, context);
    self.keyboardHandler(context);

    if (try self.save_file_manager.update(mouse_pos, context)) {
        context.flags.gui_active = true;
    }

    if (try self.load_file_manager.update(mouse_pos, context)) {
        context.flags.gui_active = true;
    }

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
    if (self.color_picker_is_open) {
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
}
