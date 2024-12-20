const rg = @import("raygui");
const og = @import("raylib");
const Rectangle = @import("Rectangle.zig");
const Vector2 = @import("Vector2.zig");
const rl = @import("mod.zig");

pub const GuiControl = rg.GuiControl;
const GuiControlProperty = rg.GuiControlProperty;
const GuiDefaultProperty = rg.GuiDefaultProperty;

pub const GuiProperty = union(enum) {
    ControlProperty: GuiControlProperty,
    DefaultProperty: GuiDefaultProperty,

    pub fn controlProperty(value: GuiControlProperty) GuiProperty {
        return .{ .ControlProperty = value };
    }

    pub fn defaultProperty(value: GuiDefaultProperty) GuiProperty {
        return .{ .DefaultProperty = value };
    }

    fn toInt(self: GuiProperty) c_int {
        return switch (self) {
            .ControlProperty => |v| @intFromEnum(v),
            .DefaultProperty => |v| @intFromEnum(v),
        };
    }
};

pub fn guiSetStyle(control: GuiControl, property: GuiProperty, value: anytype) void {
    const v = switch (@TypeOf(value)) {
        i32, comptime_int => value,
        rl.Color => value.toInt(),
        else => unreachable,
    };
    rg.guiSetStyle(@intFromEnum(control), property.toInt(), v);
}

pub fn guiCheckBox(rect: rl.Rectangle(f32), text: []const u8, checked: *bool) bool {
    const text_ptr: [*:0]const u8 = @ptrCast(text.ptr);
    return if (rg.guiCheckBox(rect.as(og.Rectangle), text_ptr, checked) == 1) true else false;
}

pub fn guiButton(rect: rl.Rectangle(f32), text: []const u8) bool {
    const text_ptr: [*:0]const u8 = @ptrCast(text.ptr);
    return if (rg.guiButton(rect.as(og.Rectangle), text_ptr) == 1) true else false;
}
