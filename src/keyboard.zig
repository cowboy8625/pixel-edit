const std = @import("std");
const rl = @import("raylib");

const State = enum { Open, Closed };

/// places result in out buffer and returns the new length
pub fn to_string(keys: *std.ArrayList(rl.KeyboardKey), out: *[]u8) usize {
    var ip: usize = 0;
    for (keys.items) |key| {
        ip += get_string_value_of_key(key, ip, out);
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

pub fn get_string_value_of_key(key: rl.KeyboardKey, buf: []u8) ![]const u8 {
    const value = switch (key) {
        .key_null => "<NULL>", // Key: NULL, used for no key pressed
        // Alphanumeric keys
        .key_apostrophe => "'", // Key: '
        .key_comma => ",", // Key: ,
        .key_minus => "-", // Key: -
        .key_period => ".", // Key: .
        .key_slash => "/", // Key: /
        .key_zero => "0", // Key: 0
        .key_one => "1", // Key: 1
        .key_two => "2", // Key: 2
        .key_three => "3", // Key: 3
        .key_four => "4", // Key: 4
        .key_five => "5", // Key: 5
        .key_six => "6", // Key: 6
        .key_seven => "7", // Key: 7
        .key_eight => "8", // Key: 8
        .key_nine => "9", // Key: 9
        .key_semicolon => ";", // Key: ;
        .key_equal => "=", // Key: =
        .key_a => "a", // Key: A | a
        .key_b => "b", // Key: B | b
        .key_c => "c", // Key: C | c
        .key_d => "d", // Key: D | d
        .key_e => "e", // Key: E | e
        .key_f => "f", // Key: F | f
        .key_g => "g", // Key: G | g
        .key_h => "h", // Key: H | h
        .key_i => "i", // Key: I | i
        .key_j => "j", // Key: J | j
        .key_k => "k", // Key: K | k
        .key_l => "l", // Key: L | l
        .key_m => "m", // Key: M | m
        .key_n => "n", // Key: N | n
        .key_o => "o", // Key: O | o
        .key_p => "p", // Key: P | p
        .key_q => "q", // Key: Q | q
        .key_r => "r", // Key: R | r
        .key_s => "s", // Key: S | s
        .key_t => "t", // Key: T | t
        .key_u => "u", // Key: U | u
        .key_v => "v", // Key: V | v
        .key_w => "w", // Key: W | w
        .key_x => "x", // Key: X | x
        .key_y => "y", // Key: Y | y
        .key_z => "z", // Key: Z | z
        .key_left_bracket => "[", // Key: [
        .key_backslash => "\\", // Key: '\'
        .key_right_bracket => "]", // Key: ]
        .key_grave => "`", // Key: `
        // Function keys
        .key_space => "<space>", // Key: Space
        .key_escape => "<esc>", // Key: Esc
        .key_enter => "<enter>", // Key: Enter
        .key_tab => "<tab>", // Key: Tab
        .key_backspace => "<backspace>", // Key: Backspace
        .key_insert => "<insert>", // Key: Ins
        .key_delete => "<delete>", // Key: Del
        .key_right => "<right>", // Key: Cursor right
        .key_left => "<left>", // Key: Cursor left
        .key_down => "<down>", // Key: Cursor down
        .key_up => "<up>", // Key: Cursor up
        .key_page_up => "<pageUp>", // Key: Page up
        .key_page_down => "<pageDown>", // Key: Page down
        .key_home => "<home>", // Key: Home
        .key_end => "<end>", // Key: End
        .key_caps_lock => "<capsLock>", // Key: Caps lock
        .key_scroll_lock => "<scrollDown>", // Key: Scroll down
        .key_num_lock => "<numLock>", // Key: Num lock
        .key_print_screen => "<screenPrint>", // Key: Print screen
        .key_pause => "<pause>", // Key: Pause
        .key_f1 => "<F1>", // Key: F1
        .key_f2 => "<F2>", // Key: F2
        .key_f3 => "<F3>", // Key: F3
        .key_f4 => "<F4>", // Key: F4
        .key_f5 => "<F5>", // Key: F5
        .key_f6 => "<F6>", // Key: F6
        .key_f7 => "<F7>", // Key: F7
        .key_f8 => "<F8>", // Key: F8
        .key_f9 => "<F9>", // Key: F9
        .key_f10 => "<F10>", // Key: F10
        .key_f11 => "<F11>", // Key: F11
        .key_f12 => "<F12>", // Key: F12
        .key_left_shift => "<shiftL>", // Key: Shift left
        .key_left_control => "<leftCtrl>", // Key: Control left
        .key_left_alt => "<leftAlt>", // Key: Alt left
        .key_left_super => "<leftSuper>", // Key: Super left
        .key_right_shift => "<rightShift>", // Key: Shift right
        .key_right_control => "<rightCtrl>", // Key: Control right
        .key_right_alt => "<rightAlt>", // Key: Alt right
        .key_right_super => "<rightSuper>", // Key: Super right
        .key_kb_menu => "<menu>", // Key: KB menu
        // Keypad keys
        .key_kp_0 => "0", // Key: Keypad 0
        .key_kp_1 => "1", // Key: Keypad 1
        .key_kp_2 => "2", // Key: Keypad 2
        .key_kp_3 => "3", // Key: Keypad 3
        .key_kp_4 => "4", // Key: Keypad 4
        .key_kp_5 => "5", // Key: Keypad 5
        .key_kp_6 => "6", // Key: Keypad 6
        .key_kp_7 => "7", // Key: Keypad 7
        .key_kp_8 => "8", // Key: Keypad 8
        .key_kp_9 => "9", // Key: Keypad 9
        .key_kp_decimal => ".", // Key: Keypad .
        .key_kp_divide => "/", // Key: Keypad /
        .key_kp_multiply => "*", // Key: Keypad *
        .key_kp_subtract => "-", // Key: Keypad -
        .key_kp_add => "+", // Key: Keypad +
        .key_kp_enter => "<kpenter>", // Key: Keypad Enter
        .key_kp_equal => "=", // Key: Keypad =
        // Android key buttons
        .key_back => "<androidBack>", // Key: Android back button
        // .key_menu => "<androidMenu>", // Key: Android menu button
        .key_volume_up => "<androidVolumeUp>", // Key: Android volume up button
        .key_volume_down => "<androidVolumeDown>", // Key: Android volume down button
        // Additional keys not included in raylib.h
        //.key_COLON => ":", // Key: :
    };
    return try std.fmt.bufPrintZ(buf, "{s}", .{value});
}
