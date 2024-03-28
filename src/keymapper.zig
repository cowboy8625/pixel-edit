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

        fn init(alloc: Allocator) !*Node {
            const self = try alloc.create(Node);
            self.* = .{
                .alloc = alloc,
                .children = std.ArrayList(*Node).init(alloc),
            };
            return self;
        }

        fn deinit(self: *Node) void {
            for (self.children.items) |child| {
                child.deinit();
            }
            self.children.deinit();
            self.alloc.destroy(self);
        }

        fn insert(self: *Node, keys: []const rl.KeyboardKey, command: Command) !void {
            if (keys.len == 1) {
                self.command = command;
                self.key = keys[0];
                return;
            }
            self.key = keys[0];
            for (self.children.items) |child| {
                try child.*.insert(keys[1..], command);
            }
            const node = try Node.init(self.alloc);
            errdefer node.*.deinit();
            try node.*.insert(keys[1..], command);
            try self.children.append(node);
        }

        fn is_possible_combination(self: *Node, keys: []const rl.KeyboardKey) bool {
            if (self.key) |key| {
                if (key != keys[0]) {
                    return false;
                }
            }

            if (self.command) |_| if (keys.len == 1) {
                return true;
            };

            for (self.children.items) |child| {
                if (child.is_possible_combination(keys[1..])) {
                    return true;
                }
            }
            return false;
        }

        fn get(self: *Node, keys: []const rl.KeyboardKey) ?Command {
            if (self.key) |key| {
                if (key != keys[0]) {
                    return null;
                }
            }

            if (self.command) |cmd| if (keys.len == 1) {
                return cmd;
            };

            for (self.children.items) |child| {
                if (child.get(keys[1..])) |cmd| {
                    return cmd;
                }
            }
            return null;
        }
    };

    pub fn init(alloc: Allocator) Self {
        return .{
            .alloc = alloc,
            .branch = std.ArrayList(*Node).init(alloc),
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.branch.items) |node| {
            node.deinit();
        }
        self.branch.deinit();
    }

    pub fn insert(self: *Self, keys: []const rl.KeyboardKey, command: Command) !void {
        for (self.branch.items) |node| {
            if (node.key) |key| if (key == keys[0]) {
                try node.insert(keys, command);
            };
        }
        const branch = try Self.Node.init(self.alloc);
        errdefer branch.*.deinit();
        try branch.*.insert(keys, command);
        try self.branch.append(branch);
    }

    pub fn is_possible_combination(self: *Self, keys: []const rl.KeyboardKey) bool {
        for (self.branch.items) |node| {
            if (node.is_possible_combination(keys)) {
                return true;
            }
        }
        return false;
    }

    pub fn get(self: *Self, keys: []const rl.KeyboardKey) ?Command {
        for (self.branch.items) |node| {
            if (node.get(keys)) |cmd| {
                return cmd;
            }
        }
        return null;
    }
};

test "insert into TrieKeyMap" {
    var trie = TrieKeyMap.init(std.testing.allocator);
    defer trie.deinit();
    const command = Command{ .name = "cursor_up", .action = &commands.cursor_up };
    try trie.insert(&[_]rl.KeyboardKey{ .LEFT_CONTROL, .C }, command);
    const result = trie.is_possible_combination(&[_]rl.KeyboardKey{ .LEFT_CONTROL, .C });
    try std.testing.expect(result);
}

test "get command from TrieKeyMap" {
    var trie = TrieKeyMap.init(std.testing.allocator);
    defer trie.deinit();
    const command = Command{ .name = "cursor_up", .action = &commands.cursor_up };
    try trie.insert(&[_]rl.KeyboardKey{ .LEFT_CONTROL, .C }, command);
    const result = trie.get(&[_]rl.KeyboardKey{ .LEFT_CONTROL, .C });
    try std.testing.expectEqualDeep(command, result.?);
}
