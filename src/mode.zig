const std = @import("std");

pub const Mode = enum {
    Normal,
    Insert,
    Command,
    Visual,
};
