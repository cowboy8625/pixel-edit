const std = @import("std");

pub fn numberCast(comptime T: type, comptime U: type, num: T) U {
    if (T == U) return num;
    return switch (@typeInfo(T)) {
        .Int => switch (@typeInfo(U)) {
            .Int => @as(U, @intCast(num)),
            .Float => @as(U, @floatFromInt(num)),
            .Bool => castToBool(T, num),
            else => @compileError("Unsupported type"),
        },
        .Float => switch (@typeInfo(U)) {
            .Int => @as(U, @floatFromInt(num)),
            .Float => @as(U, @floatCast(num)),
            .Bool => castToBool(T, num),
            else => @compileError("Unsupported type"),
        },
        .ComptimeInt, .ComptimeFloat => switch (@typeInfo(U)) {
            .Int => @as(U, @intFromFloat(num)),
            .Float => @as(U, @floatFromInt(num)),
            .Bool => castToBool(T, num),
            else => @compileError("Unsupported type"),
        },
        .Bool => switch (@typeInfo(U)) {
            .Int => @intFromBool(num),
            .Float => @as(U, @floatFromInt(@intFromBool(num))),
            .Bool => castToBool(T, num),
            else => @compileError("Unsupported type"),
        },
        else => @compileError("Unsupported type"),
    };
}

fn castToBool(comptime T: type, item: T) bool {
    return switch (@typeInfo(T)) {
        .Int => item != 0,
        .Float => item != 0.0,
        .Bool => item,
        else => @compileError("Unsupported type"),
    };
}

pub fn cast(comptime T: type, item: anytype) T {
    switch (@typeInfo(@TypeOf(item))) {
        .Int, .Float, .Bool, .ComptimeInt, .ComptimeFloat => return numberCast(@TypeOf(item), T, item),
        else => @compileError("cast function unsupported type " ++ @typeInfo(@TypeOf(item))),
    }
}

test "cast int to bool" {
    try std.testing.expectEqual(true, cast(bool, 1));
    try std.testing.expectEqual(false, cast(bool, 0));
    try std.testing.expectEqual(false, cast(bool, 100));
    const num: i32 = 1;
    try std.testing.expectEqual(true, cast(bool, num));
}

test "cast bool to int" {
    try std.testing.expectEqual(1, cast(u8, true));
    try std.testing.expectEqual(0, cast(u8, false));
}

test "cast bool to float" {
    try std.testing.expectEqual(1.0, cast(f32, true));
    try std.testing.expectEqual(0.0, cast(f32, false));
}
