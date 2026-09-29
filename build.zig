const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const module = b.addModule("wio", .{
        .root_source_file = b.path("src/wio.zig"),
        .target = target,
        .optimize = optimize,
    });

    const enable_drop = b.option(bool, "enable_drop", "Enable drag-and-drop support (default: false)") orelse false;
    const enable_vulkan = b.option(bool, "enable_vulkan", "Enable Vulkan support (default: false)") orelse false;
    const enable_joystick = b.option(bool, "enable_joystick", "Enable joystick support (default: false)") orelse false;

    var enable_x11 = false;
    var enable_wayland = false;

    const unix_backends = b.option([]const u8, "unix_backends", "List of enabled backends (default: x11,wayland)") orelse "x11,wayland";
    var backend_iter = std.mem.tokenizeScalar(u8, unix_backends, ',');
    while (backend_iter.next()) |backend| {
        if (std.mem.eql(u8, backend, "x11")) {
            enable_x11 = true;
        } else if (std.mem.eql(u8, backend, "wayland")) {
            enable_wayland = true;
        } else {
            @panic("option 'unix_backends' is invalid");
        }
    }

    const system_integration = b.systemIntegrationOption("wio", .{});
    const options = b.addOptions();
    options.addOption(bool, "drop", enable_drop);
    options.addOption(bool, "vulkan", enable_vulkan);
    options.addOption(bool, "joystick", enable_joystick);
    options.addOption(bool, "x11", enable_x11);
    options.addOption(bool, "wayland", enable_wayland);
    options.addOption(bool, "system_integration", system_integration);
    module.addOptions("build_options", options);

    if (enable_drop) module.addCMacro("WIO_DROP", "");
    if (enable_vulkan) module.addCMacro("WIO_VULKAN", "");
    if (enable_joystick) module.addCMacro("WIO_JOYSTICK", "");

    if (b.option(bool, "win32_manifest", "Embed application manifest (default: true)") orelse true) {
        module.addWin32ResourceFile(.{ .file = b.path("src/win32.rc") });
    }

    switch (target.result.os.tag) {
        .windows => {
            if (b.lazyDependency("win32", .{ .target = target, .optimize = optimize })) |win32| {
                module.addImport("win32", win32.module("win32"));
            }

            module.linkSystemLibrary("user32", .{});
            module.linkSystemLibrary("shell32", .{});
            if (enable_drop) {
                module.linkSystemLibrary("ole32", .{});
            }
            if (enable_joystick) {
                module.linkSystemLibrary("hid", .{});
                module.linkSystemLibrary(if (target.result.cpu.arch.isX86()) "xinput9_1_0" else "xinput1_4", .{});
            }
        },
        .linux, .openbsd, .netbsd, .freebsd, .dragonfly, .illumos => |tag| {
            var cimport: std.ArrayList(u8) = .empty;
            if (enable_x11) {
                try cimport.appendSlice(b.allocator,
                    \\#include <X11/Xlib.h>
                    \\#include <X11/Xatom.h>
                    \\#include <X11/XKBlib.h>
                    \\#include <X11/extensions/Xrandr.h>
                    \\#include <X11/Xcursor/Xcursor.h>
                    \\#include <GL/glx.h>
                    \\
                );
            }
            if (enable_wayland) {
                if (!system_integration) {
                    try cimport.appendSlice(b.allocator,
                        \\#include <wayland-client-core.h>
                        \\extern uint32_t (*wio_wl_proxy_get_version)(struct wl_proxy *);
                        \\extern struct wl_proxy *(*wio_wl_proxy_marshal_flags)(struct wl_proxy *, uint32_t, const struct wl_interface *, uint32_t, uint32_t, ...);
                        \\extern int (*wio_wl_proxy_add_listener)(struct wl_proxy *, void (**)(void), void *);
                        \\extern void (*wio_wl_proxy_destroy)(struct wl_proxy *);
                        \\extern void (*wio_wl_proxy_set_user_data)(struct wl_proxy *, void *);
                        \\extern void *(*wio_wl_proxy_get_user_data)(struct wl_proxy *);
                        \\#define wl_proxy_get_version wio_wl_proxy_get_version
                        \\#define wl_proxy_marshal_flags wio_wl_proxy_marshal_flags
                        \\#define wl_proxy_add_listener wio_wl_proxy_add_listener
                        \\#define wl_proxy_destroy wio_wl_proxy_destroy
                        \\#define wl_proxy_set_user_data wio_wl_proxy_set_user_data
                        \\#define wl_proxy_get_user_data wio_wl_proxy_get_user_data
                        \\#include <wayland-protocol.c>
                        \\
                    );
                }
                try cimport.appendSlice(b.allocator,
                    \\#include <viewporter-protocol.c>
                    \\#include <fractional-scale-v1-protocol.c>
                    \\#include <text-input-unstable-v3-protocol.c>
                    \\#include <tablet-v2-protocol.c>
                    \\#include <cursor-shape-v1-protocol.c>
                    \\#include <pointer-constraints-unstable-v1-protocol.c>
                    \\#include <relative-pointer-unstable-v1-protocol.c>
                    \\#include <pointer-gestures-unstable-v1-protocol.c>
                    \\#include <xdg-activation-v1-protocol.c>
                    \\#include <wayland-client-protocol.h>
                    \\#include <viewporter-client-protocol.h>
                    \\#include <fractional-scale-v1-client-protocol.h>
                    \\#include <text-input-unstable-v3-client-protocol.h>
                    \\#include <cursor-shape-v1-client-protocol.h>
                    \\#include <pointer-constraints-unstable-v1-client-protocol.h>
                    \\#include <relative-pointer-unstable-v1-client-protocol.h>
                    \\#include <pointer-gestures-unstable-v1-client-protocol.h>
                    \\#include <xdg-activation-v1-client-protocol.h>
                    \\#include <xkbcommon/xkbcommon.h>
                    \\#include <xkbcommon/xkbcommon-compose.h>
                    \\#include <libdecor.h>
                    \\#include <wayland-egl.h>
                    \\#include <EGL/egl.h>
                    \\
                );
            }
            switch (tag) {
                .linux => {
                    if (enable_joystick) {
                        try cimport.appendSlice(b.allocator,
                            \\#include <linux/input.h>
                            \\#include <libudev.h>
                            \\
                        );
                    }
                },
                else => {},
            }

            const translate_c = b.addTranslateC(.{
                .root_source_file = b.addWriteFiles().add("cimport.c", cimport.items),
                .target = target,
                .optimize = optimize,
            });
            if (b.lazyDependency("wio_unix_headers", .{})) |unix_headers| {
                translate_c.addIncludePath(unix_headers.path("include"));
            }
            module.addImport("c", translate_c.createModule());

            if (system_integration) {
                if (enable_x11) {
                    module.linkSystemLibrary("x11", .{});
                    module.linkSystemLibrary("xrandr", .{});
                    module.linkSystemLibrary("xcursor", .{});
                    if (enable_vulkan) {
                        module.linkSystemLibrary("xext", .{});
                    }
                }
                if (enable_wayland) {
                    module.linkSystemLibrary("wayland-client", .{});
                    module.linkSystemLibrary("xkbcommon", .{});
                    module.linkSystemLibrary("libdecor-0", .{});
                }
                if (enable_vulkan) {
                    module.linkSystemLibrary("vulkan", .{});
                }
                switch (tag) {
                    .linux => {
                        if (enable_joystick) {
                            module.linkSystemLibrary("libudev", .{});
                        }
                    },
                    else => {},
                }
            }
        },
        else => {},
    }
}
