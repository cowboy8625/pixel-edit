const std = @import("std");
const rl = @import("raylib_zig");

const State = enum { Open, Closed };

/// places result in out buffer and returns the new length
pub fn to_string(keys: *std.ArrayList(rl.KeyboardKey), out: *[]u8) usize {
    var ip: usize = 0;
    var ctrl: ?rl.KeyboardKey = null;
    var state: State = .Closed;
    for (keys.items) |key| {
        const str = get_string_value_of_key(key);
        if (str.len > 1 and ctrl == null and state == .Closed) {
            ctrl = key;
            state = .Open;
            out.*[ip] = '<';
            ip += 1;
            for (str[0 .. str.len - 1]) |c| {
                out.*[ip] = c;
                ip += 1;
            }
        } else if (str.len == 1 and ctrl != null and state == .Open) {
            out.*[ip] = '-';
            ip += 1;
            out.*[ip] = str[0];
            ip += 1;
            out.*[ip] = '>';
            ip += 1;
            ctrl = null;
            state = .Closed;
        } else if (str.len == 1 and ctrl != null and state == .Closed) {
            const ctrl_str = get_string_value_of_key(ctrl.?);
            out.*[ip] = '<';
            ip += 1;
            for (ctrl_str) |c| {
                out.*[ip] = c;
                ip += 1;
            }
            out.*[ip] = '-';
            ip += 1;
            out.*[ip] = str[0];
            ip += 1;
        } else {
            out.*[ip] = str[0];
            ip += 1;
        }
        // .Released => if (str.len > 1 and ctrl != null and key == ctrl.?) {
        //     ctrl = null;
        //     out.*[ip] = '>';
        //     ip += 1;
        //     state = .Closed;
        // },
    }
    return ip;
}

// test "to_string" {
//     var keys = std.ArrayList(rl.KeyboardKey).init(std.testing.allocator);
//     defer keys.deinit();
//     try keys.append(rl.KeyboardKey.LEFT_CONTROL);
//     try keys.append(rl.KeyboardKey.C);
//
//     var out = try std.testing.allocator.alloc(u8, 10);
//     defer std.testing.allocator.free(out);
//
//     try keyboard.to_string(&keys, &out);
//     const found: []const u8 = out[0..9];
//     print("'{s}'\n", .{found});
//     try std.testing.expectEqualStrings("<ctrlL-c>", found);
// }

pub fn get_string_value_of_key(key: rl.KeyboardKey) []const u8 {
    return switch (key) {
        .NULL => "NULL", // Key: NULL, used for no key pressed
        // Alphanumeric keys
        .APOSTROPHE => "'", // Key: '
        .COMMA => ",", // Key: ,
        .MINUS => "-", // Key: -
        .PERIOD => ".", // Key: .
        .SLASH => "/", // Key: /
        .ZERO => "0", // Key: 0
        .ONE => "1", // Key: 1
        .TWO => "2", // Key: 2
        .THREE => "3", // Key: 3
        .FOUR => "4", // Key: 4
        .FIVE => "5", // Key: 5
        .SIX => "6", // Key: 6
        .SEVEN => "7", // Key: 7
        .EIGHT => "8", // Key: 8
        .NINE => "9", // Key: 9
        .SEMICOLON => ";", // Key: ;
        .EQUAL => "=", // Key: =
        .A => "a", // Key: A | a
        .B => "b", // Key: B | b
        .C => "c", // Key: C | c
        .D => "d", // Key: D | d
        .E => "e", // Key: E | e
        .F => "f", // Key: F | f
        .G => "g", // Key: G | g
        .H => "h", // Key: H | h
        .I => "i", // Key: I | i
        .J => "j", // Key: J | j
        .K => "k", // Key: K | k
        .L => "l", // Key: L | l
        .M => "m", // Key: M | m
        .N => "n", // Key: N | n
        .O => "o", // Key: O | o
        .P => "p", // Key: P | p
        .Q => "q", // Key: Q | q
        .R => "r", // Key: R | r
        .S => "s", // Key: S | s
        .T => "t", // Key: T | t
        .U => "u", // Key: U | u
        .V => "v", // Key: V | v
        .W => "w", // Key: W | w
        .X => "x", // Key: X | x
        .Y => "y", // Key: Y | y
        .Z => "z", // Key: Z | z
        .LEFT_BRACKET => "[", // Key: [
        .BACKSLASH => "\\", // Key: '\'
        .RIGHT_BRACKET => "]", // Key: ]
        .GRAVE => "`", // Key: `
        // Function keys
        .SPACE => "space", // Key: Space
        .ESCAPE => "esc", // Key: Esc
        .ENTER => "enter", // Key: Enter
        .TAB => "tab", // Key: Tab
        .BACKSPACE => "backspace", // Key: Backspace
        .INSERT => "ins", // Key: Ins
        .DELETE => "del", // Key: Del
        .RIGHT => "right", // Key: Cursor right
        .LEFT => "left", // Key: Cursor left
        .DOWN => "down", // Key: Cursor down
        .UP => "up", // Key: Cursor up
        .PAGE_UP => "pageUp", // Key: Page up
        .PAGE_DOWN => "pageDown", // Key: Page down
        .HOME => "home", // Key: Home
        .END => "end", // Key: End
        .CAPS_LOCK => "capsLock", // Key: Caps lock
        .SCROLL_LOCK => "scrollDown", // Key: Scroll down
        .NUM_LOCK => "numLock", // Key: Num lock
        .PRINT_SCREEN => "screenPrint", // Key: Print screen
        .PAUSE => "pause", // Key: Pause
        .F1 => "F1", // Key: F1
        .F2 => "F2", // Key: F2
        .F3 => "F3", // Key: F3
        .F4 => "F4", // Key: F4
        .F5 => "F5", // Key: F5
        .F6 => "F6", // Key: F6
        .F7 => "F7", // Key: F7
        .F8 => "F8", // Key: F8
        .F9 => "F9", // Key: F9
        .F10 => "F10", // Key: F10
        .F11 => "F11", // Key: F11
        .F12 => "F12", // Key: F12
        .LEFT_SHIFT => "shiftL", // Key: Shift left
        .LEFT_CONTROL => "ctrlL", // Key: Control left
        .LEFT_ALT => "altL", // Key: Alt left
        .LEFT_SUPER => "superL", // Key: Super left
        .RIGHT_SHIFT => "shiftR", // Key: Shift right
        .RIGHT_CONTROL => "ctrlR", // Key: Control right
        .RIGHT_ALT => "altR", // Key: Alt right
        .RIGHT_SUPER => "superR", // Key: Super right
        .KB_MENU => "menu", // Key: KB menu
        // Keypad keys
        .KP_0 => "0", // Key: Keypad 0
        .KP_1 => "1", // Key: Keypad 1
        .KP_2 => "2", // Key: Keypad 2
        .KP_3 => "3", // Key: Keypad 3
        .KP_4 => "4", // Key: Keypad 4
        .KP_5 => "5", // Key: Keypad 5
        .KP_6 => "6", // Key: Keypad 6
        .KP_7 => "7", // Key: Keypad 7
        .KP_8 => "8", // Key: Keypad 8
        .KP_9 => "9", // Key: Keypad 9
        .KP_DECIMAL => ".", // Key: Keypad .
        .KP_DIVIDE => "/", // Key: Keypad /
        .KP_MULTIPLY => "*", // Key: Keypad *
        .KP_SUBTRACT => "-", // Key: Keypad -
        .KP_ADD => "+", // Key: Keypad +
        .KP_ENTER => "kpenter", // Key: Keypad Enter
        .KP_EQUAL => "=", // Key: Keypad =
        // Android key buttons
        .BACK => "androidBack", // Key: Android back button
        .MENU => "androidMenu", // Key: Android menu button
        .VOLUME_UP => "androidVolumeUp", // Key: Android volume up button
        .VOLUME_DOWN => "androidVolumeDown", // Key: Android volume down button
    };
}
