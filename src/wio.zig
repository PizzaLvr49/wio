const std = @import("std");
const builtin = @import("builtin");
pub const build_options = @import("build_options");
const internal = @import("wio.internal.zig");

pub const backend_name: enum {
    win32,
    unix,
} = switch (builtin.os.tag) {
    .windows => .win32,
    .macos => @compileError("unsupported platform"),
    .linux => if (builtin.target.abi.isAndroid()) @compileError("unsupported platform") else .unix,
    .openbsd, .netbsd, .freebsd, .dragonfly, .illumos => .unix,
    .haiku => @compileError("unsupported platform"),
    else => if (builtin.target.cpu.arch.isWasm()) @compileError("unsupported platform"),
};

pub const backend = switch (backend_name) {
    .win32 => @import("win32.zig"),
    .unix => @import("unix.zig"),
};

comptime {
    _ = backend;
}

pub const logFn = if (@hasDecl(backend, "logFn")) backend.logFn else std.log.defaultLog;

pub const InitOptions = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    eventFn: *const fn (?*anyopaque, Event) void,
    /// Free with `JoystickDevice.release()`.
    joystickConnectedFn: ?*const fn (JoystickDevice) void = null,
};

/// Must be called only once.
///
/// Unless otherwise noted, all calls to wio functions must be made on the same thread.
///
/// `eventFn` is the low-level window event callback which may run on other threads,
/// using `EventQueue.eventFn` is recommended.
pub fn init(options: InitOptions) !void {
    internal.allocator = options.allocator;
    internal.io = options.io;
    internal.eventFn = options.eventFn;
    try backend.init(options);
}

/// All windows and devices must be closed before calling.
pub fn deinit() void {
    backend.deinit();
}

/// Begins the main loop, which continues as long as `func` returns true.
///
/// This must be the final call on its thread, and there must be no uses of `defer` in the same scope
/// (depending on the platform, it may return immediately, never, or when the main loop exits).
pub fn run(func: fn () anyerror!bool) !void {
    return backend.run(func);
}

/// Alternative to `run()`, providing user control over the main loop.
///
/// **WebAssembly** - Not available.
pub fn update() void {
    backend.update();
}

pub const WaitOptions = struct {
    timeout_ns: ?u64 = null,
};

/// Sleep until an event is received.
pub fn wait(options: WaitOptions) void {
    backend.wait(options);
}

/// May be called from any thread.
pub fn cancelWait() void {
    backend.cancelWait();
}

pub const MessageBoxStyle = enum { info, warn, err };

pub fn messageBox(style: MessageBoxStyle, title: []const u8, message: []const u8) void {
    backend.messageBox(style, title, message);
}

pub fn openUri(uri: []const u8) void {
    backend.openUri(uri);
}

pub const Size = struct {
    width: u16,
    height: u16,

    pub fn multiply(self: Size, scale: f32) Size {
        const width: f32 = @floatFromInt(self.width);
        const height: f32 = @floatFromInt(self.height);
        return .{
            .width = @round(width * scale),
            .height = @round(height * scale),
        };
    }
};

pub const Position = struct { x: i16, y: i16 };

pub const CreateWindowOptions = struct {
    event_fn_data: ?*anyopaque,

    title: []const u8 = "wio",
    /// Application identifier used as the window class (X11) or app_id (Wayland).
    app_id: ?[]const u8 = null,

    mode: WindowMode = .normal,
    position: ?Position = null,
    size: Size = .{ .width = 640, .height = 480 },
    /// Base scale factor for `size`. If set, adjusts for high-DPI on relevant platforms.
    ///
    /// Recommended to set to 1 initially, or the last `Event.scale` when restoring dimensions.
    scale: ?f32 = null,

    /// Window handle, for embedding.
    ///
    /// Only functional on Windows and X11.
    parent: usize = 0,
};

pub const Window = struct {
    backend: @typeInfo(@typeInfo(@TypeOf(backend.Window.create)).@"fn".return_type.?).error_union.payload,

    pub fn create(options: CreateWindowOptions) !Window {
        return .{ .backend = try backend.Window.create(options) };
    }

    pub fn destroy(self: *Window) void {
        self.backend.destroy();
    }

    /// When enabled, character keys will send `.char` events instead of `.button_press`.
    ///
    /// Text input is disabled by default.
    ///
    /// May be called repeatedly to change `options`.
    pub fn enableTextInput(self: *Window, options: TextInputOptions) void {
        self.backend.enableTextInput(options);
    }

    pub fn disableTextInput(self: *Window) void {
        self.backend.disableTextInput();
    }

    /// When enabled, `.mouse_relative` events will be sent instead of `.mouse` and the
    /// cursor will be hidden.
    ///
    /// Relative mouse is disabled by default.
    ///
    /// May be called repeatedly to change `options`.
    pub fn enableRelativeMouse(self: *Window, options: RelativeMouseOptions) void {
        self.backend.enableRelativeMouse(options);
    }

    pub fn disableRelativeMouse(self: *Window) void {
        self.backend.disableRelativeMouse();
    }

    /// When enabled, `.draw` events will be sent whenever a new frame can be rendered.
    ///
    /// Draw available events are disabled by default.
    pub fn enableDrawAvailableEvents(self: *Window) void {
        self.backend.enableDrawAvailableEvents();
    }

    pub fn disableDrawAvailableEvents(self: *Window) void {
        self.backend.disableDrawAvailableEvents();
    }

    pub fn setTitle(self: *Window, title: []const u8) void {
        self.backend.setTitle(title);
    }

    pub fn setMode(self: *Window, mode: WindowMode) void {
        self.backend.setMode(mode);
    }

    pub fn setPosition(self: *Window, position: Position) void {
        self.backend.setPosition(position);
    }

    pub fn setSize(self: *Window, size: Size) void {
        self.backend.setSize(size);
    }

    /// Only functional on Windows and X11.
    pub fn setParent(self: *Window, parent: usize) void {
        self.backend.setParent(parent);
    }

    pub fn setCursor(self: *Window, cursor: Cursor) void {
        self.backend.setCursor(cursor);
    }

    pub fn minimize(self: *Window) void {
        self.backend.minimize();
    }

    pub fn requestAttention(self: *Window) void {
        self.backend.requestAttention();
    }

    pub fn setClipboardText(self: *Window, text: []const u8) void {
        self.backend.setClipboardText(text);
    }

    pub fn getClipboardText(self: *Window, clipboardTextFn: *const fn (?*anyopaque, []const u8) void, clipboard_text_fn_data: ?*anyopaque) void {
        self.backend.getClipboardText(clipboardTextFn, clipboard_text_fn_data);
    }

    pub fn getDropData(self: *Window, allocator: std.mem.Allocator) DropData {
        assertFeature(.drop);
        return self.backend.getDropData(allocator);
    }

    /// **WebAssembly**, **Haiku** - Not available.
    pub fn vkCreateSurface(self: *Window, instance: usize, allocation_callbacks: ?*const anyopaque, surface: *u64) !void {
        assertFeature(.vulkan);
        return switch (self.backend.vkCreateSurface(instance, allocation_callbacks, surface)) {
            0 => void{},
            -1 => error.OutOfHostMemory,
            -2 => error.OutOfDeviceMemory,
            -13 => error.Unknown,
            -1000011001 => error.ValidationFailure,
            -1000000001 => error.NativeWindowInUse,
            else => error.Unexpected,
        };
    }
};

pub const DropData = struct {
    files: []const []const u8,
    text: ?[]const u8,

    pub fn dupe(allocator: std.mem.Allocator, files: []const []const u8, text: ?[]const u8) !DropData {
        const out = try allocator.alloc([]const u8, files.len);
        var n: usize = 0;
        errdefer {
            for (out[0..n]) |f| allocator.free(f);
            allocator.free(out);
        }
        for (files) |f| {
            out[n] = try allocator.dupe(u8, f);
            n += 1;
        }
        return .{ .files = out, .text = if (text) |t| try allocator.dupe(u8, t) else null };
    }

    pub fn free(self: DropData, allocator: std.mem.Allocator) void {
        for (self.files) |f| allocator.free(f);
        allocator.free(self.files);
        if (self.text) |t| allocator.free(t);
    }
};

/// **WebAssembly**, **Haiku** - Not available.
pub fn vkGetInstanceProcAddr(instance: usize, name: [*:0]const u8) ?*const fn () void {
    assertFeature(.vulkan);
    return backend.vkGetInstanceProcAddr(instance, name);
}

/// **WebAssembly**, **Haiku** - Not available.
pub fn getRequiredVulkanInstanceExtensions() []const [*:0]const u8 {
    return backend.getRequiredVulkanInstanceExtensions();
}

pub const JoystickDeviceIterator = struct {
    backend: backend.JoystickDeviceIterator,

    /// Free with `deinit()` before the next iteration of the main loop.
    pub fn init() JoystickDeviceIterator {
        assertFeature(.joystick);
        return .{ .backend = backend.JoystickDeviceIterator.init() };
    }

    pub fn deinit(self: *JoystickDeviceIterator) void {
        self.backend.deinit();
    }

    /// Free with `JoystickDevice.release()`.
    pub fn next(self: *JoystickDeviceIterator) ?JoystickDevice {
        return .{ .backend = self.backend.next() orelse return null };
    }
};

pub const JoystickDevice = struct {
    backend: backend.JoystickDevice,

    pub fn release(self: JoystickDevice) void {
        self.backend.release();
    }

    /// Free with `Joystick.close()`.
    pub fn open(self: JoystickDevice) ?Joystick {
        return .{ .backend = self.backend.open() catch return null };
    }

    /// May not be unique.
    pub fn getId(self: JoystickDevice, allocator: std.mem.Allocator) ?[]u8 {
        return self.backend.getId(allocator) catch null;
    }

    /// Returns "" on error.
    pub fn getName(self: JoystickDevice, allocator: std.mem.Allocator) []u8 {
        return self.backend.getName(allocator) catch "";
    }
};

pub const Joystick = struct {
    backend: @typeInfo(@typeInfo(@TypeOf(backend.JoystickDevice.open)).@"fn".return_type.?).error_union.payload,

    pub fn close(self: *Joystick) void {
        self.backend.close();
    }

    pub fn poll(self: *Joystick) ?JoystickState {
        return self.backend.poll();
    }
};

pub const JoystickState = struct {
    axes: []const u16,
    hats: []const Hat,
    buttons: []const bool,
};

pub const Hat = packed struct {
    up: bool = false,
    right: bool = false,
    down: bool = false,
    left: bool = false,
};

pub const EventQueue = struct {
    events: std.ArrayList(Event),
    head: usize,

    pub const empty: EventQueue = .{
        .events = .empty,
        .head = 0,
    };

    pub fn deinit(self: *EventQueue) void {
        self.events.deinit(internal.allocator);
    }

    pub fn push(self: *EventQueue, event: Event) void {
        if (self.head != 0) {
            self.events.replaceRangeAssumeCapacity(0, self.head, &.{});
            self.head = 0;
        }

        switch (std.meta.activeTag(event)) {
            .draw, .mode, .position, .size_logical, .size_physical => |tag| {
                for (self.events.items, 0..) |item, i| {
                    if (item == tag) {
                        _ = self.events.orderedRemove(i);
                        break;
                    }
                }
            },
            else => {},
        }

        self.events.append(internal.allocator, event) catch {};
    }

    pub fn pop(self: *EventQueue) ?Event {
        if (self.head == self.events.items.len) return null;
        defer self.head += 1;
        return self.events.items[self.head];
    }

    pub fn eventFn(data: ?*anyopaque, event: Event) void {
        const self: *EventQueue = @ptrCast(@alignCast(data));
        self.push(event);
    }
};

pub const Event = union(enum) {
    close: void,
    focused: void,
    unfocused: void,
    draw: void,

    /// On change, sent before `position` or `size_logical`.
    mode: WindowMode,
    /// Relative to an unspecified origin.
    position: Position,
    /// Window size as used by mouse and touch events.
    size_logical: Size,
    /// Window size in pixels.
    size_physical: Size,
    /// Suggested render scale.
    ///
    /// Depending on the platform, this may be equal to `size_physical / size_logical`,
    /// or a configured scale factor.
    scale: f32,

    modifiers: Modifiers,

    /// Only sent when `Window.enableTextInput` has been called.
    char: u21,
    /// Discard the composition string.
    ///
    /// Only sent when `Window.enableTextInput` has been called.
    preview_reset: void,
    /// Append a character to the composition string.
    ///
    /// Only sent when `Window.enableTextInput` has been called.
    preview_char: u21,
    /// If the values are equal an I-beam should be displayed at that point in
    /// the composition string, otherwise characters within the range should
    /// be underlined.
    ///
    /// The values are codepoint indices into the composition string.
    ///
    /// Only sent when `Window.enableTextInput` has been called.
    preview_cursor: [2]u16,

    button_press: Button,
    button_repeat: Button,
    button_release: Button,

    /// Relative to the top-left corner of the window.
    mouse: Position,
    /// Relative to the last mouse position.
    ///
    /// Only sent when `Window.enableRelativeMouse` has been called.
    mouse_relative: Position,
    mouse_leave: void,
    scroll_vertical: f32,
    scroll_horizontal: f32,

    touch: Touch,
    touch_end: TouchEnd,

    gesture_zoom: f32,
    /// Delta in degrees.
    gesture_rotate: f32,
    /// If true, gestures since the last `.gesture_ignore = false` should not affect the program.
    gesture_ignore: bool,

    drop_begin: void,
    drop_position: Position,
    drop_complete: void,

    pub const Touch = struct {
        id: u8,
        x: i16,
        y: i16,
    };

    pub const TouchEnd = struct {
        id: u8,
        /// If true, the touch was processed by the system and should not affect the program.
        ignore: bool,
    };
};

pub const EventType = @typeInfo(Event).@"union".tag_type.?;

pub const WindowMode = enum {
    normal,
    maximized,
    fullscreen,
};

pub const Modifiers = struct {
    control: bool = false,
    shift: bool = false,
    alt: bool = false,
    gui: bool = false,
};

pub const TextInputOptions = struct {
    cursor: ?Position = null,
};

pub const RelativeMouseOptions = struct {
    unaccelerated: bool,
};

/// See https://drafts.csswg.org/css-ui-4/#predefined-cursors
pub const Cursor = enum {
    default,
    none,
    context_menu,
    help,
    pointer,
    progress,
    wait,
    cell,
    crosshair,
    text,
    vertical_text,
    alias,
    copy,
    move,
    no_drop,
    not_allowed,
    grab,
    grabbing,
    e_resize,
    n_resize,
    ne_resize,
    nw_resize,
    s_resize,
    se_resize,
    sw_resize,
    w_resize,
    ew_resize,
    ns_resize,
    nesw_resize,
    nwse_resize,
    col_resize,
    row_resize,
    all_scroll,
    zoom_in,
    zoom_out,
};

/// See https://www.usb.org/sites/default/files/hut1_7.pdf
pub const Button = enum {
    mouse_left,
    mouse_right,
    mouse_middle,
    mouse_back,
    mouse_forward,
    a,
    b,
    c,
    d,
    e,
    f,
    g,
    h,
    i,
    j,
    k,
    l,
    m,
    n,
    o,
    p,
    q,
    r,
    s,
    t,
    u,
    v,
    w,
    x,
    y,
    z,
    @"1",
    @"2",
    @"3",
    @"4",
    @"5",
    @"6",
    @"7",
    @"8",
    @"9",
    @"0",
    enter,
    escape,
    backspace,
    tab,
    space,
    minus,
    equals,
    left_bracket,
    right_bracket,
    backslash,
    semicolon,
    apostrophe,
    grave,
    comma,
    dot,
    slash,
    caps_lock,
    f1,
    f2,
    f3,
    f4,
    f5,
    f6,
    f7,
    f8,
    f9,
    f10,
    f11,
    f12,
    print_screen,
    scroll_lock,
    pause,
    insert,
    home,
    page_up,
    delete,
    end,
    page_down,
    right,
    left,
    down,
    up,
    num_lock,
    kp_slash,
    kp_star,
    kp_minus,
    kp_plus,
    kp_enter,
    kp_1,
    kp_2,
    kp_3,
    kp_4,
    kp_5,
    kp_6,
    kp_7,
    kp_8,
    kp_9,
    kp_0,
    kp_dot,
    iso_backslash,
    application,
    kp_equals,
    f13,
    f14,
    f15,
    f16,
    f17,
    f18,
    f19,
    f20,
    f21,
    f22,
    f23,
    f24,
    kp_comma,
    international1,
    international2,
    international3,
    international4,
    international5,
    lang1,
    lang2,
    left_control,
    left_shift,
    left_alt,
    left_gui,
    right_control,
    right_shift,
    right_alt,
    right_gui,
};

fn assertFeature(feature: anytype) void {
    if (!@field(build_options, @tagName(feature))) {
        @compileError("feature '" ++ @tagName(feature) ++ "' is disabled");
    }
}
