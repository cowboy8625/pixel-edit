pub const WidgetEvent = enum {
    width_input,
    height_input,
};

pub const Event = union(enum) {
    testing: void,
    draw: void,
    erase: void,
    bucket: void,
    color_picker: void,
    close_control_pannel: void,
    open_control_pannel: void,
    clicked: WidgetEvent,
    open_color_wheel: void,
    close_color_wheel: void,
    set_canvas_width: i32,
    set_canvas_height: i32,
    open_save_file_browser: void,
    open_load_file_browser: void,
    rotate_left: void,
    rotate_right: void,
};
