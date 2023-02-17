const std = @import("std");
const huffman = @import("huffman");
const bitvector = @import("bitvector");

const kb = (1 << 10);

pub fn main() !void {
    // TODO(Jorge Henriquez): Figure out how to read from stdin.
    const compress_me =
        \\ This is a test string.
        \\ It has multiple lines and should contain multiple lines of text.
        \\ Since Zig's encoding is UTF-8, it should support emojis!
        \\ Here's one now: (🦎)
        \\ If you can't see the above, it's an iguana!
        \\
        \\ Fun fact: Zig programmer's are Ziguanas!
    ;
    // Get an allocator.
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var gpa_alloc = gpa.allocator();
    var mem = try gpa_alloc.alloc(u8, 18 * kb);
    defer gpa_alloc.free(mem);
    var fba = std.heap.FixedBufferAllocator.init(mem);
    var allocator = fba.allocator();

    // Create a histogram.
    var histogram = [_]u32{0} ** 256;
    for (compress_me) |char| {
        histogram[char] += 1;
    }
    const tree = try huffman.createTree(allocator, &histogram);
    var codes = std.AutoArrayHashMap(u8, bitvector.BitVector).init(allocator);
    try huffman.make_codes(&tree, &codes);

    var total_bits: usize = 0;
    for (compress_me) |c| {
        const bv = codes.getPtr(c).?;
        total_bits += bv.len();
    }
}
