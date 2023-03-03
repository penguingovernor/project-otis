const std = @import("std");

pub fn randFloatRange(
    comptime T: type,
    min: T,
    max: T,
    rng: *std.rand.Xoshiro256,
) T {
    const scale: T = @intToFloat(T, rng.next()) / std.math.maxInt(u64);
    const num = min + scale * (max - min);
    return @floor(10000.0 * num) / 10000.0;
}

pub fn randomLatitude(comptime T: type, rng: *std.rand.Xoshiro256) T {
    return randFloatRange(T, -90, 90, rng);
}

pub fn randomLongitude(comptime T: type, rng: *std.rand.Xoshiro256) T {
    return randFloatRange(T, -180, 180, rng);
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
    var allocator = arena.allocator();
    defer arena.deinit();

    var seed_str = std.os.getenv("COORGEN_SEED") orelse "0xDEADBEEF";
    var seed = try std.fmt.parseUnsigned(u64, seed_str, 0);

    var rng = std.rand.Xoshiro256.init(seed);

    var number_of_pairs: usize = 10_000_000;
    const args = try std.process.argsAlloc(allocator);
    if (args.len > 1) {
        number_of_pairs = try std.fmt.parseUnsigned(u64, args[1], 0);
    }

    var pairs = try allocator.alloc(LatLongPair(f64), number_of_pairs);
    for (0..number_of_pairs) |i| {
        pairs[i].x0 = randomLatitude(f64, &rng);
        pairs[i].y0 = randomLongitude(f64, &rng);
        pairs[i].x1 = randomLatitude(f64, &rng);
        pairs[i].y1 = randomLongitude(f64, &rng);
    }

    const serialize_me = jsonPoints(f64){
        .pairs = pairs,
    };

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    try std.json.stringify(&serialize_me, .{}, stdout);
    try bw.flush();
}
