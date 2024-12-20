const std = @import("std");
const Asset = @import("assets.zig");
const rl = @import("rl/mod.zig");
const event = @import("event.zig");
const ControlPannel = @import("ControlPannel.zig");

const State = enum {
    Draw,
    Line,
    Fill,
    Erase,
    ColorPicker,
    Select,
    None,
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
    try control_pannel.add_button("load image", .testing, Asset.loadTexture(Asset.LOAD_ICON));
    try control_pannel.add_button("save image", .testing, Asset.loadTexture(Asset.SAVE_ICON));
    try control_pannel.add_button("pencil tool", .testing, Asset.loadTexture(Asset.PENCIL_TOOL_ICON));
    try control_pannel.add_button("eraser tool", .testing, Asset.loadTexture(Asset.ERASER_TOOL_ICON));
    try control_pannel.add_button("bucket tool", .testing, Asset.loadTexture(Asset.BUCKET_TOOL_ICON));
    // try control_pannel.add_button(.testing, Asset.loadTexture(Asset.CROSS_HAIRS_ICON));
    try control_pannel.add_button("grid", .testing, Asset.loadTexture(Asset.GRID_ICON));
    try control_pannel.add_button("color picker", .testing, Asset.loadTexture(Asset.COLOR_PICKER_ICON));
    try control_pannel.add_button("color wheel", .testing, Asset.loadTexture(Asset.COLOR_WHEEL_ICON));
    try control_pannel.add_button("rotate left", .testing, Asset.loadTexture(Asset.ROTATE_LEFT_ICON));
    try control_pannel.add_button("play animation", .testing, Asset.loadTexture(Asset.PLAY_ICON));
    try control_pannel.add_button("next frame", .testing, Asset.loadTexture(Asset.RIGHT_ARROW_ICON));
    try control_pannel.add_button("previous frame", .testing, Asset.loadTexture(Asset.LEFT_ARROW_ICON));
    try control_pannel.add_button("rotate right", .testing, Asset.loadTexture(Asset.ROTATE_RIGHT_ICON));
    try control_pannel.add_button("draw line tool", .testing, Asset.loadTexture(Asset.LINE_TOOL_ICON));
    try control_pannel.add_button("flip vertical", .testing, Asset.loadTexture(Asset.FLIP_VERTICAL_ICON));
    try control_pannel.add_button("flip horizontal", .testing, Asset.loadTexture(Asset.FLIP_HORIZONTAL_ICON));
    try control_pannel.add_button("frames tool", .testing, Asset.loadTexture(Asset.FRAMES_ICON));
    try control_pannel.add_button("selection tool", .testing, Asset.loadTexture(Asset.SELECTION_ICON));

    var events = std.ArrayList(event.Event).init(allocator);
    defer events.deinit();

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
            }
        }
        events.clearRetainingCapacity();

        // -------- DRAW --------
        rl.beginDrawing();
        rl.clearBackground(rl.Color.black);
        rl.endDrawing();

        control_pannel.draw();
    }
}
