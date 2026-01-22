const builtin = @import("builtin");

pub usingnamespace @cImport({
    // GLFW
    @cInclude("GLFW/glfw3.h");
    if (builtin.os.tag == .linux) {
        @cDefine("GLFW_EXPOSE_NATIVE_WAYLAND", "1");
        @cInclude("GLFW/glfw3native.h");
    }

    // @cInclude("extern/futureproof.h");
    // @cInclude("extern/preview.h");

    if (builtin.os.tag == .macos) {
        @cInclude("objc/message.h");
    }
});
