const std = @import("std");

pub const MajorMode = enum {
    Text,
    PixelEditor,
    // const Self = @This();
    // pub fn to_string(
    //     self: Self,
    // ) []const u8 {
    //     return @tagName(self);
    // }
};

// pub const MinorMode = enum {
//
// };

pub const State = enum {
    Normal,
    Insert,
    Visual,
    // const Self = @This();
    // pub fn to_string(
    //     self: Self,
    // ) []const u8 {
    //     return @tagName(self);
    // }
};
