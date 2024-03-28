const std = @import("std");

pub const MajorMode = enum {
    Text,
    PixelEditor,
};

// pub const MinorMode = enum {
//
// };

pub const State = enum {
    Normal,
    Insert,
    Visual,
};
