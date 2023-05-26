const std = @import("std");
const coor = @import("coordinate.zig");

pub fn main() !u8 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const args = try std.process.argsAlloc(arena.allocator());
    const min_args: usize = 3;
    const stderr = std.io.getStdErr();
    if (args.len < min_args + 1) {
        try std.fmt.format(stderr.writer(), "USAGE: {s} {{N_PAIRS}} {{SEED}} {{uniform|cluster}}\n", .{args[0]});
        return 1;
    }

    const n_pairs = try std.fmt.parseUnsigned(usize, args[1], 0);
    const seed = try std.fmt.parseUnsigned(u64, args[2], 0);
    const method = blk: {
        var m: coor.GenerationMethod = undefined;
        if (std.mem.eql(u8, args[3], "uniform")) {
            m = coor.GenerationMethod.uniform;
        } else if (std.mem.eql(u8, args[3], "cluster")) {
            m = coor.GenerationMethod.clustered;
        } else {
            try std.fmt.format(stderr.writer(), "ERROR: Unknown method {s}\n", .{args[3]});
            try std.fmt.format(stderr.writer(), "USAGE: {s} {{N_PAIRS}} {{SEED}} {{uniform|cluster}}\n", .{args[0]});
            return 1;
        }
        break :blk m;
    };

    const stdout = std.io.getStdOut();
    var bw = std.io.bufferedWriter(stdout.writer());
    try generateJson(n_pairs, seed, bw.writer(), method);
    try bw.flush();
    return 0;
}

pub fn generateJson(n_pairs: usize, seed: u64, json_writer: anytype, method: coor.GenerationMethod) !void {
    var rng = std.rand.DefaultPrng.init(seed);
    const random = rng.random();
    var generator = coor.Generator.init(method, random);
    _ = try json_writer.write(
        \\{"pairs":[
    );
    var coordinates: [1024]coor.Coordinate = undefined;

    var pairs_generated: usize = 0;
    while (pairs_generated < n_pairs) {
        generator.fill(random, &coordinates);
        var i: usize = 0;
        while (i < coordinates.len / 2 and pairs_generated < n_pairs) : (i += 2) {
            const pairA = &coordinates[i];
            const pairB = &coordinates[i + 1];
            try std.fmt.format(json_writer, "{{\"x0\":{d},\"y0\": {d},\"x1\":{d},\"y1\": {d}}}", .{
                pairA.lat,
                pairA.long,
                pairB.lat,
                pairB.long,
            });
            if (pairs_generated + 1 != n_pairs) {
                _ = try json_writer.write(",");
            }
            pairs_generated += 1;
        }
    }
    _ = try json_writer.write(
        \\]}
        \\
    );
}
