const std = @import("std");
const Io = std.Io;
const print = std.debug.print;

const types = @import("types.zig");
const ValidationError = types.ValidationError;

const Client = @This();

stream: std.net.Stream,


pub fn init(name: []const u8) !Client {
    const address = try std.net.Address.parseIpAndPort(name);
    const stream = std.net.tcpConnectToAddress(address) catch |err| {
        std.log.err("Failed to connect to {s}: {s}", .{ name, @errorName(err) });
        return err;
    };
    return Client{ .stream = stream };
}

inline fn parse_key_length(key: []const u8) ValidationError!u16 {
    if (key.len > std.math.maxInt(u16)) {
        return ValidationError.KeyTooLong;
    }
    return @as(u16, @intCast(key.len));
}

inline fn parse_value_length(value: []const u8) ValidationError!u32 {
    if (value.len > std.math.maxInt(u32)) {
        return ValidationError.ValueTooLarge;
    }
    return @as(u32, @intCast(value.len));
}

pub fn set(self: *Client, key: []const u8, value: []const u8) !void {
    var buffer: [1024]u8 = undefined;
    var writer = self.stream.writer(&buffer);
    var output = &writer.interface;

    const key_length = try parse_key_length(key);
    const value_length = try parse_value_length(value);


    const request = types.Request{
        .magic = types.Magic.request,
        .opcode = types.Opcode.set,
        .key_length = key_length,
        .extras_length = @sizeOf(types.RequestExtras),
        .data_type = 0,
        .vbucket_id = 0,
        .body_length = key_length + value_length + @sizeOf(types.RequestExtras),
        .reserved = 0,
        .cas = 0,
    };
    const extras = types.RequestExtras {
        .flags = 0xdeadbeef,
        .expiration = 0xdeadbeef,
    };

    try output.writeStruct(request, std.builtin.Endian.big);
    try output.writeStruct(extras, std.builtin.Endian.big);
    try output.writeAll(key);
    try output.writeAll(value);

    try output.flush();

    var reader = self.stream.reader(&buffer);
    var input: *std.Io.Reader = reader.interface();

    try input.fill(@sizeOf(types.Response));
    const response = try input.takeStruct(types.Response, std.builtin.Endian.big);

    try response.status.ensure_status_is_ok();
}

pub fn get(self: *Client, key: []const u8, output: []u8) !usize {
    var buffer: [1024]u8 = undefined;
    var writer = self.stream.writer(&buffer);
    var output_interface = &writer.interface;

    const key_length = try parse_key_length(key);

    const request = types.Request{
        .magic = types.Magic.request,
        .opcode = types.Opcode.get,
        .key_length = key_length,
        .extras_length = 0,
        .data_type = 0,
        .vbucket_id = 0,
        .body_length = key_length,
        .reserved = 0,
        .cas = 0,
    };

    try output_interface.writeStruct(request, std.builtin.Endian.big);
    try output_interface.writeAll(key);

    try output_interface.flush();

    var reader = self.stream.reader(&buffer);
    var interface: *std.Io.Reader = reader.interface();
    try interface.fill(@sizeOf(types.Response));

    const response = try interface.takeStruct(types.Response, std.builtin.Endian.big);
    try response.status.ensure_status_is_ok();

    try interface.fill(@sizeOf(types.ResponseExtras));
    _ = try interface.takeStruct(types.ResponseExtras, std.builtin.Endian.big);

    const remaining = response.body_length - response.extras_length - response.key_length;
    return try interface.readSliceShort(output[0..remaining]);
}

test "get" {
    var client = try init("127.0.0.1:11211");
    try client.set("key", "value");
    var buffer: [1024]u8 = undefined;
    const size = try client.get("key", &buffer);
    try std.testing.expectEqualStrings("value", buffer[0..size]);
}
