const std = @import("std");
const Allocator = std.mem.Allocator;
const Cursor = @import("Cursor.zig");

const Self = @This();

alloc: Allocator,
cursor: *Cursor,

pub fn init(alloc: Allocator) !Self {
    const cursor = try alloc.create(Cursor);
    errdefer alloc.destroy(cursor);
    cursor.* = Cursor.init();

    return .{
        .alloc = alloc,
        .cursor = cursor,
    };
}

pub fn deinit(self: Self) void {
    self.alloc.destroy(self.cursor);
}
