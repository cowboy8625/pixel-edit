const std = @import("std");
const rl = @import("raylib");
const Button = @import("Button.zig").Button;
const TextInput = @import("TextInput.zig");
const Dragable = @import("Dragable.zig").Dragable;

pub fn Widget(comptime T: type) type {
    return union(enum) {
        Button: Button(T),
        TextInput: TextInput,
        Dragable: Dragable(T),
    };
}
