const std = @import("std");

pub fn numberCast(comptime T: type, comptime U: type, num: T) U {
    if (T == U) return num;
    return switch (@typeInfo(T)) {
        .Int => if (@typeInfo(U) == .Float) @as(U, @floatFromInt(num)) else @as(U, @intCast(num)),
        .Float => if (@typeInfo(U) == .Int) @as(U, @intFromFloat(num)) else @as(U, @floatCast(num)),
        .ComptimeInt, .ComptimeFloat => switch (@typeInfo(U)) {
            .Int => @as(U, @intFromFloat(num)),
            .Float => @as(U, @floatFromInt(num)),
            .Bool => if (num == 1) true else false,
            else => @compileError("Unsupported type"),
        },
        .Bool => switch (@typeInfo(U)) {
            .Int => @intFromBool(num),
            .Float => @as(U, @floatFromInt(@intFromBool(num))),
            .Bool => if (num == 1) true else false,
            // else => @compileError("Unsupported cast from bool to " ++ @typeInfo(@TypeOf(U)) ++ ":" ++ @typeName(U)),
            else => @compileError("Unsupported type"),
        },
        // else => @compileError("Unsupported type " ++ @typeInfo(@TypeOf(T)) ++ ":" ++ @typeName(T) ++ " to " ++ @typeInfo(@TypeOf(U)) ++ ":" ++ @typeName(U)),
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
}

test "cast bool to int" {
    try std.testing.expectEqual(1, cast(u8, true));
    try std.testing.expectEqual(0, cast(u8, false));
}

test "cast bool to float" {
    try std.testing.expectEqual(1.0, cast(f32, true));
    try std.testing.expectEqual(0.0, cast(f32, false));
}
