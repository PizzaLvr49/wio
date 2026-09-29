const std = @import("std");
const wio = @import("wio.zig");
const internal = @import("wio.internal.zig");
const log = std.log.scoped(.wio);

pub fn init(options: wio.InitOptions) !void {
    _ = options;
}

pub fn deinit() void {}

pub fn run(func: fn () anyerror!bool) !void {
    _ = func;
}

pub fn update() void {}

pub fn wait(options: wio.WaitOptions) void {
    _ = options;
}

pub fn cancelWait() void {}

pub fn messageBox(style: wio.MessageBoxStyle, title: []const u8, message: []const u8) void {
    _ = style;
    _ = title;
    _ = message;
}

pub fn openUri(uri: []const u8) void {
    _ = uri;
}

pub const Window = struct {
    pub fn create(options: wio.CreateWindowOptions) !*Window {
        const self = try internal.allocator.create(Window);
        _ = options;
        return self;
    }

    pub fn destroy(self: *Window) void {
        internal.allocator.destroy(self);
    }

    pub fn enableTextInput(self: *Window, options: wio.TextInputOptions) void {
        _ = self;
        _ = options;
    }

    pub fn disableTextInput(self: *Window) void {
        _ = self;
    }

    pub fn enableRelativeMouse(self: *Window, _: wio.RelativeMouseOptions) void {
        _ = self;
    }

    pub fn disableRelativeMouse(self: *Window) void {
        _ = self;
    }

    pub fn enableDrawAvailableEvents(self: *Window) void {
        _ = self;
    }

    pub fn disableDrawAvailableEvents(self: *Window) void {
        _ = self;
    }

    pub fn setTitle(self: *Window, title: []const u8) void {
        _ = self;
        _ = title;
    }

    pub fn setMode(self: *Window, mode: wio.WindowMode) void {
        _ = self;
        _ = mode;
    }

    pub fn setPosition(self: *Window, position: wio.Position) void {
        _ = self;
        _ = position;
    }

    pub fn setSize(self: *Window, size: wio.Size) void {
        _ = self;
        _ = size;
    }

    pub fn setParent(self: *Window, parent: usize) void {
        _ = self;
        _ = parent;
    }

    pub fn setCursor(self: *Window, shape: wio.Cursor) void {
        _ = self;
        _ = shape;
    }

    pub fn minimize(self: *Window) void {
        _ = self;
    }

    pub fn requestAttention(self: *Window) void {
        _ = self;
    }

    pub fn setClipboardText(self: *Window, text: []const u8) void {
        _ = self;
        _ = text;
    }

    pub fn getClipboardText(self: *Window, clipboardTextFn: *const fn (?*anyopaque, []const u8) void, clipboard_text_fn_data: ?*anyopaque) void {
        _ = self;
        _ = clipboardTextFn;
        _ = clipboard_text_fn_data;
    }

    pub fn getDropData(self: *Window, allocator: std.mem.Allocator) wio.DropData {
        _ = self;
        _ = allocator;
        return .{ .files = &.{}, .text = null };
    }

    pub fn vkCreateSurface(self: *Window, instance: usize, allocation_callbacks: ?*const anyopaque, surface: *u64) i32 {
        _ = self;
        _ = instance;
        _ = allocation_callbacks;
        _ = surface;
        return 0;
    }
};

pub fn vkGetInstanceProcAddr(instance: usize, name: [*:0]const u8) ?*const fn () void {
    _ = instance;
    _ = name;
    return null;
}

pub fn getRequiredVulkanInstanceExtensions() []const [*:0]const u8 {
    return &.{};
}

pub const JoystickDeviceIterator = struct {
    pub fn init() JoystickDeviceIterator {
        return .{};
    }

    pub fn deinit(self: *JoystickDeviceIterator) void {
        _ = self;
    }

    pub fn next(self: *JoystickDeviceIterator) ?JoystickDevice {
        _ = self;
        return null;
    }
};

pub const JoystickDevice = struct {
    pub fn release(self: JoystickDevice) void {
        _ = self;
    }

    pub fn open(self: JoystickDevice) !Joystick {
        _ = self;
        return error.Unexpected;
    }

    pub fn getId(self: JoystickDevice, allocator: std.mem.Allocator) ![]u8 {
        _ = self;
        _ = allocator;
        return error.Unexpected;
    }

    pub fn getName(self: JoystickDevice, allocator: std.mem.Allocator) ![]u8 {
        _ = self;
        _ = allocator;
        return error.Unexpected;
    }
};

pub const Joystick = struct {
    pub fn close(self: *Joystick) void {
        _ = self;
    }

    pub fn poll(self: *Joystick) ?wio.JoystickState {
        _ = self;
        return null;
    }
};
