const std = @import("std");
const rl = @import("raylib");
const Cursor = @import("Cursor.zig");
const Allocator = std.mem.Allocator;
const Self = @This();

const Buffer = struct {
    const ExpandSize = 1024;
    text: *[]u8,
    size: usize,
    index: usize = 0,
    alloc: Allocator,

    fn init(alloc: Allocator, size: usize) anyerror!Buffer {
        return .{
            .text = try alloc.alloc(u8, size),
            .size = size,
        };
    }

    fn deinit(self: *Buffer) void {
        self.alloc.free(self.text);
    }

    fn expand_size(self: *Buffer) void {
        self.text = try self.alloc.realloc(self.text, self.size + Buffer.ExpandSize);
        self.size += Buffer.ExpandSize;
    }

    fn clear(self: *Buffer) void {
        self.index = 0;
    }

    fn insert(self: *Buffer, char: u8) void {
        if (self.index >= self.size) {
            self.expand_size();
        }
        self.text[self.index] = char;
        self.index += 1;
    }

    fn remove(self: *Buffer, at: usize) u8 {
        _ = at;
        _ = self;
    }
};

cursor: Cursor,
buffer: Buffer,

pub fn init(alloc: Allocator) !Self {
    return .{
        .cursor = Cursor.init(),
        .buffer = Buffer.init(alloc, Buffer.ExpandSize),
    };
}

pub fn deinit(self: Self) void {
    self.buffer.deinit();
}

test "insert and expand" {
    const alloc = std.testing.allocator;
    var buffer = try Buffer.init(alloc, 10);
    defer buffer.deinit();
    buffer.insert('a'); // 1
    buffer.insert('b'); // 2
    buffer.insert('c'); // 3
    buffer.insert('d'); // 4
    buffer.insert('e'); // 5
    buffer.insert('f'); // 6
    buffer.insert('g'); // 7
    buffer.insert('h'); // 8
    buffer.insert('i'); // 9
    buffer.insert('j'); // 10
    try std.testing.expectEqualStrings("abcdefghij", buffer.text[0..buffer.index]);
    try std.testing.expectEqual(@as(usize, 10), buffer.index);
    try std.testing.expectEqual(@as(usize, 10), buffer.size);
    buffer.insert('k'); // 11
    try std.testing.expectEqual(@as(usize, 1034), buffer.size);
}
