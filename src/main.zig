const std = @import("std");
const bmemcached = @import("bmemcached");

pub fn main() !void {
    var client = try bmemcached.init("127.0.0.1:11211");
    try client.set("Hello", "World");
    var buffer: [5]u8 = undefined;
    const size = try client.get("Hello", &buffer);
    std.debug.print("Result of key Hello is '{s}'", .{buffer[0..size]});
}
