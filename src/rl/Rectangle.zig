const std = @import("std");
const rl = @import("raylib");
const Vector2 = @import("Vector2.zig").Vector2;
const utils = @import("utils.zig");

pub fn Rectangle(comptime T: type) type {
    return extern struct {
        x: T,
        y: T,
        width: T,
        height: T,

        const Self = @This();

        pub fn init(x: T, y: T, width: T, height: T) Rectangle(T) {
            return .{ .x = x, .y = y, .width = width, .height = height };
        }

        pub fn from2vec2(point: Vector2(T), size: Vector2(T)) Rectangle(T) {
            return .{ .x = point.x, .y = point.y, .width = size.x, .height = size.y };
        }

        pub fn center(self: *const Self) Vector2(T) {
            return self.getPos().add(self.getSize()).div(2);
        }

        pub fn top(self: *const Self) T {
            return self.y;
        }

        pub fn bottom(self: *const Self) T {
            return self.y + self.height;
        }

        pub fn left(self: *const Self) T {
            return self.x;
        }

        pub fn right(self: *const Self) T {
            return self.x + self.width;
        }

        pub fn contains(self: Self, point: Vector2(T)) bool {
            return point.x >= self.x and point.x <= self.x + self.width and point.y >= self.y and point.y <= self.y + self.height;
        }

        /// Same as calling `topLeft`
        pub fn pos(self: Self, comptime U: type) Vector2(U) {
            return .{ .x = self.x, .y = self.y };
        }

        /// Same as calling `pos`
        pub fn topLeft(self: *const Self) Vector2(T) {
            return .{ .x = self.x, .y = self.y };
        }

        pub fn bottomRight(self: *const Self) Vector2(T) {
            return .{ .x = self.x + self.width, .y = self.y + self.height };
        }

        pub fn eq(self: Self, other: Self) bool {
            return std.meta.eql(self, other);
        }

        pub fn addPoint(self: Self, point: Vector2(T)) Self {
            return .{
                .x = self.x + point.x,
                .y = self.y + point.y,
                .width = self.width,
                .height = self.height,
            };
        }

        pub fn scale(self: Self, value: anytype) Self {
            const size = self.getSize();
            const scale_factor = size.div(value);
            const local_pos = self.getPos().sub(scale_factor);
            return Self.from2vec2(local_pos, size.add(scale_factor.mul(value)));
        }

        pub fn expand(self: Self, value: Vector2(T)) Self {
            const half_value = value.div(@as(T, 2));

            const new_pos = self.getPos().sub(half_value);
            const new_size = self.getSize().add(value);
            return Self.from2vec2(new_pos, new_size);
        }

        pub fn getPos(self: Self) Vector2(T) {
            return .{ .x = self.x, .y = self.y };
        }

        pub fn getSize(self: Self) Vector2(T) {
            return .{ .x = self.width, .y = self.height };
        }

        pub fn sizeDiv(self: Self, value: anytype) Self {
            const local_pos = self.getPos();
            const size = self.getSize().div(value);
            return Self.from2vec2(local_pos, size);
        }

        pub fn as(self: Self, comptime U: type) if (U == rl.Rectangle) rl.Rectangle else Rectangle(U) {
            switch (U) {
                rl.Rectangle => return self.asRl(),
                else => {
                    const x: U = utils.numberCast(T, U, self.x);
                    const y: U = utils.numberCast(T, U, self.y);
                    const width: U = utils.numberCast(T, U, self.width);
                    const height: U = utils.numberCast(T, U, self.height);
                    return .{ .x = x, .y = y, .width = width, .height = height };
                },
            }
        }

        pub fn asRl(self: Self) rl.Rectangle {
            const x: f32 = utils.numberCast(f32, T, self.x);
            const y: f32 = utils.numberCast(f32, T, self.y);
            const width: f32 = utils.numberCast(f32, T, self.width);
            const height: f32 = utils.numberCast(f32, T, self.height);
            return .{ .x = x, .y = y, .width = width, .height = height };
        }
    };
}
