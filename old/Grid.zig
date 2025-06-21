const std = @import("std");
const rl = @import("raylib");

const Button = @import("Button.zig").Button;

pub fn Grid(comptime T: type, comptime W: comptime_int, comptime H: comptime_int) type {
    return struct {
        const Self = @This();

        items: [W * H]Button(T) = undefined,
        len: usize = 0,
        update_callback: (*const fn (*Self, rl.Vector2, T) anyerror!void),
        draw_callback: (*const fn (*Self, rl.Vector2) anyerror!void),
        deinit_callback: (*const fn (*Self) void),

        pub fn deinit(self: *Self) void {
            self.deinit_callback(self);
        }

        pub fn update(self: *Self, mouse_pos: rl.Vector2, args: T) anyerror!void {
            try self.update_callback(self, mouse_pos, args);
        }
        pub fn draw(self: *Self, pos: rl.Vector2) anyerror!void {
            try self.draw_callback(self, pos);
        }

        pub fn push(self: *Self, item: Button(T)) void {
            self.items[self.len] = item;
            self.len += 1;
        }

        pub fn iterator(self: *Self) Iterator {
            return .{ .grid = self, .len = self.len };
        }

        const Iterator = struct {
            grid: *Self,
            index: usize = 0,
            len: usize,
            pub fn next(self: *Iterator) ?*Button(T) {
                if (self.index >= self.len) return null;
                const index = self.index;
                self.index += 1;
                return &self.grid.items[index];
            }
        };
    };
}
