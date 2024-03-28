const Context = @import("Context.zig");
const Self = @This();
name: []const u8,
action: *const fn (ctx: *Context) void,
