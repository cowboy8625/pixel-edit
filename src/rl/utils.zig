pub fn numberCast(comptime T: type, comptime U: type, num: T) U {
    if (T == U) return num;
    return switch (@typeInfo(T)) {
        .Int => switch (@typeInfo(U)) {
            .Int => @as(U, @intCast(num)),
            .Float => @as(U, @floatFromInt(num)),
            .Bool => castToBool(T, num),
            else => @compileError("Unsupported type " ++ @typeName(U)),
        },
        .Float => switch (@typeInfo(U)) {
            .Int => @as(U, @intFromFloat(num)),
            .Float => @as(U, @floatCast(num)),
            .Bool => castToBool(T, num),
            else => @compileError("Unsupported type " ++ @typeName(U)),
        },
        .ComptimeInt, .ComptimeFloat => switch (@typeInfo(U)) {
            .Int => @as(U, @intFromFloat(num)),
            .Float => @as(U, @floatFromInt(num)),
            .Bool => castToBool(T, num),
            else => @compileError("Unsupported type " ++ @typeName(U)),
        },
        .Bool => switch (@typeInfo(U)) {
            .Int => @intFromBool(num),
            .Float => @as(U, @floatFromInt(@intFromBool(num))),
            .Bool => castToBool(T, num),
            else => @compileError("Unsupported type " ++ @typeName(U)),
        },
        .Enum => switch (@typeInfo(U)) {
            .Int => @intFromEnum(num),
            .Float => @as(U, @floatFromInt(@intFromEnum(num))),
            .Bool => castToBool(T, num),
            else => @compileError("Unsupported type " ++ @typeName(U)),
        },
        else => @compileError("Unsupported type " ++ @typeName(T)),
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
        .Int, .Float, .Bool => return numberCast(@TypeOf(item), T, item),
        else => @compileError("Unsupported type " ++ @typeName(@TypeOf(item))),
    }
}
