// const std = @import("std");
// const Allocator = std.mem.Allocator;
// const rl = @import("raylib");
// const utils = @import("utils.zig");
// const cast = utils.cast;
//
// const Pixels = std.AutoHashMap(Point, rl.Color);
// const Point = struct {
//     x: usize,
//     y: usize,
// };
//
// const Self = @This();
// alloc: Allocator,
// pixels: Pixels,
// width: u32,
// height: u32,
//
// pub fn init(alloc: Allocator, width: u32, height: u32) !Self {
//     var pixels = Pixels.init(alloc);
//     errdefer pixels.deinit();
//
//     return .{
//         .alloc = alloc,
//         .pixels = pixels,
//         .width = width,
//         .height = height,
//     };
// }
//
// pub fn deinit(self: *Self) void {
//     self.pixels.deinit();
// }
//
// pub fn clear(self: *Self) void {
//     self.pixels.clearRetainingCapacity();
// }
//
// pub fn insert(self: *Self, pos: anytype, color: rl.Color) !void {
//     const p = convertToPoint(pos);
//     try self.pixels.put(p, color);
// }
//
// pub fn remove(self: *Self, pos: anytype) void {
//     const p = convertToPoint(pos);
//     _ = self.pixels.remove(p);
// }
//
// pub fn get(self: *const Self, pos: anytype) ?rl.Color {
//     switch (@TypeOf(pos)) {
//         rl.Vector2 => {
//             const x = cast(usize, pos.x);
//             const y = cast(usize, pos.y);
//             return self.pixels.get(.{ .x = x, .y = y });
//         },
//         Point => {
//             return self.pixels.get(pos);
//         },
//         else => {
//             @compileError("Invalid type: " ++ @typeName(@TypeOf(pos)));
//         },
//     }
//     return self.pixels.get(pos);
// }
//
// fn drawBackground(self: *const Self) void {
//     const pos = .{ .x = 0, .y = 0 };
//     const size = .{
//         .x = cast(f32, self.width),
//         .y = cast(f32, self.height),
//     };
//     rl.drawRectangleV(pos, size, rl.Color.white);
// }
//
// pub fn draw(self: *const Self, ctx: *Context) void {
//     self.drawBackground();
//     const size = ctx.cursor.size;
//     var iter = self.pixels.iterator();
//     while (iter.next()) |entry| {
//         const pos: rl.Vector2 = .{
//             .x = cast(f32, entry.key_ptr.*.x),
//             .y = cast(f32, entry.key_ptr.*.y),
//         };
//         const color = entry.value_ptr.*;
//         rl.drawRectangleV(pos.multiply(size), size, color);
//     }
// }
//
// fn convertToPoint(pos: anytype) Point {
//     return switch (@TypeOf(pos)) {
//         rl.Vector2 => {
//             const x = cast(usize, pos.x);
//             const y = cast(usize, pos.y);
//             return .{ .x = x, .y = y };
//         },
//         Point => {
//             return pos;
//         },
//         else => {
//             @compileError("Invalid type: " ++ @typeName(@TypeOf(pos)));
//         },
//     };
// }
