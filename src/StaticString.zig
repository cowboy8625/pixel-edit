const std = @import("std");

pub fn StaticString(comptime SIZE: comptime_int) type {
    return struct {
        const Self = @This();
        chars: [SIZE]u8 = [_]u8{0} ** SIZE,
        len: usize = 0,

        pub fn init() Self {
            return .{};
        }

        pub fn initWithText(input: []const u8) Self {
            var chars: [SIZE]u8 = undefined;
            std.mem.copy(u8, &chars, input);
            return .{
                .chars = chars,
                .len = input.len,
            };
        }

        pub fn clear(self: *Self) void {
            self.len = 0;
        }

        pub fn string(self: *Self) []const u8 {
            return self.chars[0..self.len];
        }

        pub fn push(self: *Self, char: u8) void {
            if (self.len < SIZE) {
                self.chars[self.len] = char;
                self.len += 1;
            }
        }

        pub fn pop(self: *Self) void {
            if (self.len > 0) {
                self.len -= 1;
                self.chars[self.len] = 0;
            }
        }

        pub fn findIndexRev(self: *Self, char: u8) ?usize {
            var i: usize = self.len;
            while (i > 0) : (i -= 1) {
                if (self.chars[i - 1] == char) {
                    return i - 1;
                }
            }
            return null;
        }

        pub fn last(self: *Self) u8 {
            return self.chars[self.len - 1];
        }

        pub fn iterator(self: *Self) Iterator {
            return .{ .chars = self.chars[0..self.len], .len = self.len };
        }

        pub const Iterator = struct {
            chars: []u8,
            len: usize,
            index: usize = 0,

            pub fn next(self: *Iterator) ?u8 {
                if (self.index < self.len) {
                    defer self.index += 1;
                    return self.chars[self.index];
                }
                return null;
            }
        };
    };
}
