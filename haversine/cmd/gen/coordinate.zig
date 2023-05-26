const std = @import("std");

pub const Coordinate = struct {
    lat: f64,
    long: f64,
};

pub const GenerationMethod = enum {
    clustered,
    uniform,
};

pub const Generator = union(GenerationMethod) {
    uniform: void,
    clustered: CoordinateClusters,
    pub fn init(method: GenerationMethod, rand: std.rand.Random) Generator {
        return switch (method) {
            GenerationMethod.uniform => Generator{ .uniform = undefined },
            GenerationMethod.clustered => Generator{ .clustered = CoordinateClusters.init(rand) },
        };
    }
    pub fn generateCoordinate(self: *const Generator, rand: std.rand.Random) Coordinate {
        return switch (self.*) {
            GenerationMethod.uniform => makeUniformCoordinate(rand),
            GenerationMethod.clustered => |*clusters| clusters.makeClusteredCoordinate(rand),
        };
    }
    pub fn fill(self: *const Generator, rand: std.rand.Random, coordinates: []Coordinate) void {
        for (coordinates) |*coordinate| {
            coordinate.* = self.generateCoordinate(rand);
        }
    }
};

fn f64AtMost(random: std.rand.Random, atLeast: f64, atMost: f64) f64 {
    return atLeast + random.float(f64) * (atMost - atLeast);
}

fn makeUniformCoordinate(random: std.rand.Random) Coordinate {
    return Coordinate{
        .lat = f64AtMost(random, @as(f64, -180), @as(f64, 180)),
        .long = f64AtMost(random, @as(f64, -90), @as(f64, 90)),
    };
}

// CoordinateClusters represents 64 clusters of coordinate-pairs.
// The first index is the min, and the second is the max.
const CoordinateClusters = struct {
    lats: [64][2]f64,
    longs: [64][2]f64,

    fn init(rand: std.rand.Random) CoordinateClusters {
        var c: CoordinateClusters = undefined;
        var i: usize = 0;
        while (i < 64) : (i += 1) {
            const a = makeUniformCoordinate(rand);
            var attempts: usize = 0;
            while (attempts < 100) : (attempts += 1) {
                const b = makeUniformCoordinate(rand);
                if (a.lat > b.lat) {
                    c.lats[i][0] = b.lat;
                    c.lats[i][1] = a.lat;
                } else if (a.lat < b.lat) {
                    c.lats[i][0] = a.lat;
                    c.lats[i][1] = b.lat;
                } else {
                    continue;
                }
                if (a.long > b.long) {
                    c.longs[i][0] = b.long;
                    c.longs[i][1] = a.long;
                } else if (a.long < b.long) {
                    c.longs[i][0] = a.long;
                    c.longs[i][1] = b.long;
                } else {
                    continue;
                }
                break;
            }
            std.debug.assert(attempts < 100);
        }
        return c;
    }

    fn makeClusteredCoordinate(self: *const CoordinateClusters, rand: std.rand.Random) Coordinate {
        const cluster_no = rand.uintAtMost(usize, 63);
        return Coordinate{
            .lat = f64AtMost(rand, self.lats[cluster_no][0], self.lats[cluster_no][1]),
            .long = f64AtMost(rand, self.longs[cluster_no][0], self.longs[cluster_no][1]),
        };
    }
};
