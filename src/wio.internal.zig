const std = @import("std");
const builtin = @import("builtin");
const wio = @import("wio.zig");
const log = std.log.scoped(.wio);

pub var allocator: std.mem.Allocator = undefined;
pub var io: std.Io = undefined;
pub var eventFn: *const fn (?*anyopaque, wio.Event) void = undefined;

pub fn sendEvent(data: ?*anyopaque, event: wio.Event) void {
    eventFn(data, event);
}

pub fn logUnexpected(name: []const u8) error{Unexpected} {
    log.err("{s} failed", .{name});
    return error.Unexpected;
}
