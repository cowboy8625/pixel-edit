const std = @import("std");
const rl = @import("raylib_zig");
const Allocator = std.mem.Allocator;
const testing = std.testing;
const Mode = @import("mode.zig").Mode;
const commands = @import("commands.zig");
const Command = @import("Command.zig");

/// Builds mapping for major mode `text` and state `normal`
fn build_normal_mode(key_map: *TrieKeyMap) !void {
    try key_map.insert(
        &[_]rl.KeyboardKey{.J},
        Command{
            .name = "cursor_down",
            .action = &commands.cursor_down,
        },
    );
    try key_map.insert(
        &[_]rl.KeyboardKey{.DOWN},
        Command{
            .name = "cursor_down",
            .action = &commands.cursor_down,
        },
    );

    try key_map.insert(
        &[_]rl.KeyboardKey{.UP},
        Command{
            .name = "cursor_up",
            .action = &commands.cursor_up,
        },
    );
    try key_map.insert(
        &[_]rl.KeyboardKey{.K},
        Command{
            .name = "cursor_up",
            .action = &commands.cursor_up,
        },
    );

    try key_map.insert(
        &[_]rl.KeyboardKey{.H},
        Command{
            .name = "cursor_left",
            .action = &commands.cursor_left,
        },
    );
    try key_map.insert(
        &[_]rl.KeyboardKey{.LEFT},
        Command{
            .name = "cursor_left",
            .action = &commands.cursor_left,
        },
    );

    try key_map.insert(
        &[_]rl.KeyboardKey{.L},
        Command{
            .name = "cursor_right",
            .action = &commands.cursor_right,
        },
    );
    try key_map.insert(
        &[_]rl.KeyboardKey{.RIGHT},
        Command{
            .name = "cursor_right",
            .action = &commands.cursor_right,
        },
    );
    try key_map.insert(
        &[_]rl.KeyboardKey{.COLON},
        Command{
            .name = "change_mode_to_command",
            .action = &commands.change_mode_to_command,
        },
    );

    try key_map.insert(
        &[_]rl.KeyboardKey{.I},
        Command{
            .name = "change_mode_to_insert",
            .action = &commands.change_mode_to_insert,
        },
    );
}

/// Builds mapping for major mode `text` and state `command`
fn build_command_mode(key_map: *TrieKeyMap) !void {
    try key_map.insert(
        &[_]rl.KeyboardKey{.ESCAPE},
        Command{
            .name = "change_mode_to_normal",
            .action = &commands.change_mode_to_normal,
        },
    );
    try key_map.insert(
        &[_]rl.KeyboardKey{.NULL},
        Command{
            .name = "insert_char",
            .action = &commands.insert_char,
        },
    );
}

fn build_insert_mode(key_map: *TrieKeyMap) !void {
    try key_map.insert(
        &[_]rl.KeyboardKey{.ESCAPE},
        Command{
            .name = "change_mode_to_normal",
            .action = &commands.change_mode_to_normal,
        },
    );

    try key_map.insert(
        &[_]rl.KeyboardKey{.J},
        Command{
            .name = "draw_cursor_down",
            .action = &commands.draw_cursor_down,
        },
    );
    try key_map.insert(
        &[_]rl.KeyboardKey{.DOWN},
        Command{
            .name = "draw_cursor_down",
            .action = &commands.draw_cursor_down,
        },
    );

    try key_map.insert(
        &[_]rl.KeyboardKey{.UP},
        Command{
            .name = "draw_cursor_up",
            .action = &commands.draw_cursor_up,
        },
    );
    try key_map.insert(
        &[_]rl.KeyboardKey{.K},
        Command{
            .name = "draw_cursor_up",
            .action = &commands.draw_cursor_up,
        },
    );

    try key_map.insert(
        &[_]rl.KeyboardKey{.H},
        Command{
            .name = "draw_cursor_left",
            .action = &commands.draw_cursor_left,
        },
    );
    try key_map.insert(
        &[_]rl.KeyboardKey{.LEFT},
        Command{
            .name = "draw_cursor_left",
            .action = &commands.draw_cursor_left,
        },
    );

    try key_map.insert(
        &[_]rl.KeyboardKey{.L},
        Command{
            .name = "draw_cursor_right",
            .action = &commands.draw_cursor_right,
        },
    );
    try key_map.insert(
        &[_]rl.KeyboardKey{.RIGHT},
        Command{
            .name = "cursor_right",
            .action = &commands.draw_cursor_right,
        },
    );
}

const ModeMap = std.EnumArray(Mode, TrieKeyMap);
pub const KeyMapper = struct {
    alloc: Allocator,
    modes: ModeMap,

    const Self = @This();

    pub fn init(alloc: Allocator) !Self {
        var normal_keys = TrieKeyMap.init(alloc);
        try build_normal_mode(&normal_keys);
        var command_keys = TrieKeyMap.init(alloc);
        try build_command_mode(&command_keys);
        var insert_keys = TrieKeyMap.init(alloc);
        try build_insert_mode(&insert_keys);
        return .{ .alloc = alloc, .modes = ModeMap.init(.{
            .Normal = normal_keys,
            .Command = command_keys,
            .Visual = TrieKeyMap.init(alloc),
            .Insert = insert_keys,
        }) };
    }

    pub fn deinit(self: *Self) void {
        var modes_iter = self.modes.iterator();
        while (modes_iter.next()) |m| {
            m.value.deinit();
        }
    }

    pub fn get(
        self: Self,
        mode: Mode,
        keys: []const rl.KeyboardKey,
    ) ?Command {
        if (self.modes.get(mode).get(keys)) |cmd| {
            return cmd;
        }
        return null;
    }

    pub fn is_possible_combination(
        self: Self,
        mode: Mode,
        keys: []const rl.KeyboardKey,
    ) bool {
        if (self.modes.get(mode).is_possible_combination(keys)) {
            return true;
        }
        return false;
    }
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

        fn is_possible_combination(self: Node, keys: []const rl.KeyboardKey) bool {
            if (self.key) |key| {
                if (key != keys[0]) {
                    if (key != .NULL) {
                        return false;
                    }
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
                    if (key != .NULL) {
                        return null;
                    }
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

    pub fn is_possible_combination(self: Self, keys: []const rl.KeyboardKey) bool {
        if (keys.len == 0) {
            return false;
        }
        for (self.branch.items) |node| {
            if (node.is_possible_combination(keys)) {
                return true;
            }
        }
        return false;
    }

    pub fn get(self: Self, keys: []const rl.KeyboardKey) ?Command {
        if (keys.len == 0) {
            return null;
        }
        for (self.branch.items) |node| {
            if (node.get(keys)) |cmd| {
                return cmd;
            }
        }
        return null;
    }
};
test "trigger on any key if key value is set to NULL" {
    var trie = TrieKeyMap.init(std.testing.allocator);
    defer trie.deinit();
    const command = Command{ .name = "cursor_up", .action = &commands.cursor_up };
    try trie.insert(&[_]rl.KeyboardKey{.NULL}, command);
    const result = trie.is_possible_combination(&[_]rl.KeyboardKey{.C});
    try std.testing.expect(result);
    const c = trie.get(&[_]rl.KeyboardKey{.C});
    try std.testing.expectEqualDeep(command, c.?);
}

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
