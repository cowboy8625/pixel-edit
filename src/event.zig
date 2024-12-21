pub const WidgetEvent = enum {
    width_input,
    height_input,
};

pub const Event = union(enum) {
    testing: void,
    draw: void,
    close_control_pannel: void,
    open_control_pannel: void,
    clicked: WidgetEvent,
};
