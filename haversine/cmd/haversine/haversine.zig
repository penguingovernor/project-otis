const std = @import("std");
const yyjson = @import("yyjson.zig");

fn havDegrees(theta: anytype) @TypeOf(theta) {
    const sin_theta_by_two = @sin(
        std.math.degreesToRadians(@TypeOf(theta), theta / 2.0),
    );
    return sin_theta_by_two * sin_theta_by_two;
}

fn centralAngleBetweenLatLongCoordinates(
    comptime T: type,
    lat_0: T,
    long_0: T,
    lat_1: T,
    long_1: T,
) T {
    return havDegrees(lat_1 - lat_0) +
        @cos(std.math.degreesToRadians(T, lat_1)) *
        @cos(std.math.degreesToRadians(T, lat_0)) *
        havDegrees(long_1 - long_0);
}

fn greatCircleDistance(
    comptime T: type,
    lat_0: T,
    long_0: T,
    lat_1: T,
    long_1: T,
    radius: T,
) T {
    return 2.0 * radius * std.math.asin(@sqrt(
        centralAngleBetweenLatLongCoordinates(
            T,
            lat_0,
            long_0,
            lat_1,
            long_1,
        ),
    ));
}

pub fn LatLongPair(comptime T: type) type {
    return struct { x0: T, y0: T, x1: T, y1: T };
}

pub fn jsonPoints(comptime T: type) type {
    return struct {
        pairs: []LatLongPair(T),
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    const filename = args[1];

    var timer = try std.time.Timer.start();

    const doc = try yyjson.getDoc(filename);
    defer yyjson.freeDoc(doc);
    var midtime = timer.lap();

    var iter = try yyjson.getEntryIter(allocator, doc);

    const earth_radius_km = 6371;
    var sum: f64 = 0;
    var count: usize = 0;

    while (try iter.next()) |entry| {
        sum += greatCircleDistance(
            f64,
            entry.x0,
            entry.y0,
            entry.x1,
            entry.y1,
            earth_radius_km,
        );
        count += 1;
    }

    var average = sum / @intToFloat(f64, count);
    const end = timer.lap();

    std.debug.print("Result: {d} km\n", .{average});
    std.debug.print("Input = {d} ms\n", .{@intToFloat(f64, midtime) / @intToFloat(f64, std.time.ns_per_ms)});
    std.debug.print("Math = {d} ms\n", .{@intToFloat(f64, end) / @intToFloat(f64, std.time.ns_per_ms)});
    std.debug.print("Total = {d} ms\n", .{@intToFloat(f64, end + midtime) / @intToFloat(f64, std.time.ns_per_ms)});
    std.debug.print("Throughput = {e} haversines/second\n", .{@intToFloat(f64, count) /
        (@intToFloat(f64, end + midtime) / @intToFloat(f64, std.time.ns_per_s))});
}
