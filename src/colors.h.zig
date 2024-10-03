pub const YELLOW_COLOR: c_int = 1;
pub const BLUE_COLOR: c_int = 2;
pub const GREEN_COLOR: c_int = 3;
pub const RED_COLOR: c_int = 4;
pub const CYAN_COLOR: c_int = 5;
pub const MAGENTA_COLOR: c_int = 6;

pub const Color_Pairs = c_uint;
pub const Custom_Color = extern struct {
    custom_slot: Color_Pairs = @import("std").mem.zeroes(Color_Pairs),
    custom_id: c_int = @import("std").mem.zeroes(c_int),
    custom_r: c_int = @import("std").mem.zeroes(c_int),
    custom_g: c_int = @import("std").mem.zeroes(c_int),
    custom_b: c_int = @import("std").mem.zeroes(c_int),
};
pub const Color_Arr = extern struct {
    arr: *Custom_Color = @import("std").mem.zeroes(*Custom_Color),
    arr_s: usize = @import("std").mem.zeroes(usize),
};
