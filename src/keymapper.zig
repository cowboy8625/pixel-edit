const std = @import("std");
const rl = @import("raylib_zig");
const Allocator = std.mem.Allocator;
const testing = std.testing;
const mode = @import("mode.zig");
const commands = @import("commands.zig");
const Command = @import("Command.zig");

const KeyMap = std.StringHashMap(Command);
const StateMap = std.StringHashMap(KeyMap);
const ModeMap = std.StringHashMap(StateMap);
pub const KeyMapper = struct {
    alloc: Allocator,
    modes: ModeMap,

    const Self = @This();

    pub fn init(alloc: Allocator) !Self {
        var key_map = KeyMap.init(alloc);
        try key_map.put("j", Command{ .name = "cursor_down", .action = &commands.cursor_down });
        try key_map.put("<down>", Command{ .name = "cursor_down", .action = &commands.cursor_down });
        try key_map.put("k", Command{ .name = "cursor_up", .action = &commands.cursor_up });
        try key_map.put("<up>", Command{ .name = "cursor_up", .action = &commands.cursor_up });
        var normal_state = StateMap.init(alloc);
        try normal_state.put("normal", key_map);
        var modes = ModeMap.init(alloc);
        try modes.put("text", normal_state);
        return .{ .alloc = alloc, .modes = modes };
    }

    pub fn deinit(self: *Self) void {
        var modes_iter = self.modes.valueIterator();
        while (modes_iter.next()) |state| {
            var state_iter = state.valueIterator();
            while (state_iter.next()) |keys| {
                keys.deinit();
            }
            state.deinit();
        }
        self.modes.deinit();
    }

    // pub fn get(self: Self, major_mode: mode.MajorMode, state: mode.State, keys: []const u8) ?Command {
    pub fn get(self: Self, major_mode: []const u8, state: []const u8, keys: []const u8) ?Command {
        if (self.modes.get(major_mode)) |state_map| {
            if (state_map.get(state)) |key_map| {
                return key_map.get(keys) orelse null;
            }
        }
        return null;
    }

    // pub fn is_possible_combination(self: Self, major_mode: []const u8, state: []const u8, keys: []const u8) bool {
    //
    // }
};

const TrieKeyMap = struct {
    const Self = @This();

    alloc: Allocator,
    branch: std.ArrayList(*Node),

    const Node = struct {
        alloc: Allocator,
        children: std.ArrayList(*Node),
        key: ?rl.KeyboardKey = null,
        command: ?Command = null,

        pub fn init(alloc: Allocator) Self {
            return .{
                .alloc = alloc,
                .children = std.ArrayList(*Node).init(alloc),
            };
        }

        pub fn deinit(self: *Self) void {
            for (self.children.items) |child| {
                child.deinit();
            }
            self.children.deinit();
            self.alloc.destroy(self);
        }

        pub fn insert(self: *Self, keys: []const rl.KeyboardKey, command: Command) !void {
            if (keys.len == 1) {
                self.command = command;
                self.key = keys[0];
                return;
            }
            if (keys.len > 0) {
                return;
            }
            self.key = keys[0];
            for (self.children.items) |child| {
                try child.insert(keys[1..], command);
            }
            const node = try self.alloc.create(Node);
            errdefer self.alloc.destroy(node);
            node.* = Node.init(self.alloc);
            try node.*.insert(keys[1..], command);
            try self.children.append(node);
        }

        // pub fn get(self: *Self, keys: []const rl.KeyboardKey) ?rl.KeyboardKey {
        //
        // }
    };

    pub fn init(alloc: Allocator) Self {
        return .{
            .alloc = alloc,
            .branch = std.ArrayList(*Node).init(alloc),
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.nodes.items) |node| {
            node.deinit();
        }
        self.nodes.deinit();
    }

    pub fn insert(self: *Self, keys: []const rl.KeyboardKey, command: Command) !void {
        for (self.branch.items) |node| {
            if (node.key == keys[0]) {
                try node.*.insert(keys[1..], command);
            }
        }
        const branch = try Self.Node.init(self.alloc);
        errdefer branch.deinit();
        try branch.*.insert(keys, command);
        try self.branch.append(branch);
    }
};

test "insert into TrieKeyMap" {
    var trie = TrieKeyMap.init(std.testing.allocator);
    defer trie.deinit();
    const command = Command{ .name = "cursor_up", .action = &commands.cursor_up };
    try trie.insert(&[_]rl.KeyboardKey{ rl.KeyboardKey.LEFT_CONTROL, rl.KeyboardKey.C }, command);
    std.testing.expect(trie.is_possible_combination(&[_]rl.KeyboardKey{ rl.KeyboardKey.LEFT_CONTROL, rl.KeyboardKey.C }));
    std.testing.expect(false);
}
