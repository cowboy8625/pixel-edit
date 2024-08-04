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
    };
}
