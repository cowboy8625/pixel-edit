const std = @import("std");
const rl = @import("raylib");

const Button = @import("Button.zig").Button;

pub fn Grid(comptime T: type, comptime W: comptime_int, comptime H: comptime_int) type {
    return struct {
        const Self = @This();

        items: [W * H]Button(T) = undefined,
        len: usize = 0,

        pub fn init() Self {
            return .{};
        }

        pub fn deinit(self: *Self) void {
            var iter = self.iterator();
            while (iter.next()) |item| {
                item.deinit();
            }
        }

        pub fn push(self: *Self, item: T) void {
            self.items[self.len] = item;
            self.len += 1;
        }

        pub fn update(self: *Self, mouse_pos: rl.Vector2, items: [W * H]?T) void {
            var iter = self.iterator();
            var i: usize = 0;
            while (iter.next()) |item| {
                const t = if (items[i]) |t| t else continue;

                item.update(mouse_pos, t);
            }
        }

        pub fn draw(self: *Self) void {}

        pub fn iterator(self: *Self) Iterator {
            return .{ .items = self.items, .len = self.len };
        }

        const Iterator = struct {
            items: [W * H]T,
            index: usize = 0,
            len: usize,
            pub fn next(self: *Iterator) ?T {
                if (self.index >= self.len) return null;
                const index = self.index;
                self.index += 1;
                return self.items[index];
            }
        };
    };
}
