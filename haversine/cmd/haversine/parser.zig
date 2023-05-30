const std = @import("std");

pub const Coordinate = struct {
    x: f64,
    y: f64,
};

const ParseResult = struct {
    parsed: f64,
    characterParsed: usize,
};

// Parses `buf` into an f64.
// The equivalent regex is: `:\s*([^\s,}]+)[\s,}]`
fn parseF64(buf: []const u8) !ParseResult {
    // Find the ':'
    var begin: usize = 0;
    while (buf[begin] != ':') : (begin += 1) {}
    if (begin == buf.len) {
        return error.NoColonFound;
    }
    begin += 1;

    // Discard white space.
    while (std.ascii.isWhitespace(buf[begin])) : (begin += 1) {}

    // Find the end.
    var end: usize = begin;
    while (!std.ascii.isWhitespace(buf[end]) and buf[end] != ',' and buf[end] != '}') : (end += 1) {}

    return ParseResult{
        .characterParsed = end + 1,
        .parsed = try std.fmt.parseFloat(f64, buf[begin..end]),
    };
}

pub fn Reader(comptime ReaderType: type) type {
    return struct {
        const This = @This();

        rd: std.io.BufferedReader(4096, ReaderType),
        digit_buffer: [256]u8,

        pub fn init(reader: ReaderType) This {
            return This{
                .rd = std.io.bufferedReader(reader),
                .digit_buffer = undefined,
            };
        }

        pub fn next(self: *This) !?[2]Coordinate {
            const rd = self.rd.reader();

            // NOTE(jorge): Not the best way to do this, but it's *a* way.
            const dont_care_or_err = rd.readUntilDelimiter(&self.digit_buffer, 'x');
            if (dont_care_or_err) |_| {} else |err| {
                if (err == error.EndOfStream) {
                    return null;
                }
                return err;
            }

            var search_buf = try rd.readUntilDelimiter(&self.digit_buffer, '}');

            // `readUntilDelimiter` doesn't put the delimiter in the returned
            // slice but we can work around that here.
            search_buf = self.digit_buffer[0 .. search_buf.len + 1];

            const x0_res = try parseF64(search_buf);
            search_buf = search_buf[x0_res.characterParsed..];

            const y0_res = try parseF64(search_buf);
            search_buf = search_buf[y0_res.characterParsed..];

            const x1_res = try parseF64(search_buf);
            search_buf = search_buf[x1_res.characterParsed..];

            const y1_res = try parseF64(search_buf);
            search_buf = search_buf[y1_res.characterParsed..];

            return [_]Coordinate{
                Coordinate{ .x = x0_res.parsed, .y = y0_res.parsed },
                Coordinate{ .x = x1_res.parsed, .y = y1_res.parsed },
            };
        }
    };
}
