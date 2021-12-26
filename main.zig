const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var alloc = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!alloc.deinit());
    var gpa = &alloc.allocator;

    const host = std.os.getenv("NOSMTP_HOST") orelse "0.0.0.0";
    const port = std.fmt.parseInt(u16, std.os.getenv("NOSMTP_PORT") orelse "2525", 10) catch |err| {
        print("Can't parse port: {}\n", .{err});
        std.os.exit(1);
    };
    const message = std.os.getenv("NOSMTP_MESSAGE") orelse "556 Domain does not accept mail";

    const msg = try std.fmt.allocPrint(gpa, "{s}\r\n", .{message});
    defer gpa.free(msg);

    var server = std.net.StreamServer.init(.{});
    defer server.deinit();

    const addr = try std.net.Address.parseIp(host, port);
    server.listen(addr) catch |err| {
        print("Failed to bind: {}\n", .{err});
        std.os.exit(1);
    };

    print("Listening!\n", .{});

    while (true) {
        var conn = server.accept() catch |err| {
            print("Failed to accept: {}\n", .{err});
            continue;
        };
        print("Connection from {}\n", .{conn.address});
        _ = async handle(conn, msg);
    }
}

fn handle(conn: std.net.StreamServer.Connection, message: []const u8) void {
    _ = conn.stream.write(message) catch 0;
    conn.stream.close();
}
