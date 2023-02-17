const std = @import("std");

pub const BitVector = struct {
    bits: std.ArrayList(u8),
    bits_in_last_byte: u8,
    pub fn init(allocator: std.mem.Allocator) BitVector {
        return BitVector{
            .bits = std.ArrayList(u8).init(allocator),
            .bits_in_last_byte = 0,
        };
    }
    pub fn deinit(self: *BitVector) void {
        self.bits.deinit();
    }
    pub fn len(self: *const BitVector) usize {
        if (self.bits.items.len == 0) {
            return 0;
        }
        return (self.bits.items.len - 1) * 8 + (self.bits_in_last_byte);
    }
    pub fn getBit(self: *const BitVector, bit_position: usize) bool {
        const bit_index = @intCast(u3, bit_position % 8);
        const byte_index = @intCast(usize, bit_position / 8);
        return (self.bits.items[byte_index] & (@intCast(u8, 1) << bit_index)) != 0;
    }
    pub fn pop(self: *BitVector) bool {
        const ret = getBit(self, self.len() - 1);
        self.bits_in_last_byte -= 1;
        if (self.bits_in_last_byte == 0) {
            _ = self.bits.pop();
            self.bits_in_last_byte = 8;
        }
        return ret;
    }
    pub fn appendBit(self: *BitVector, bit: bool) !void {
        if (self.bits.items.len == 0 or self.bits_in_last_byte == 8) {
            try self.bits.append(0);
            self.bits_in_last_byte = 0;
        }
        if (bit) {
            self.bits.items[self.bits.items.len - 1] |= (@intCast(u8, 1) << @intCast(u3, self.bits_in_last_byte));
        } else {
            self.bits.items[self.bits.items.len - 1] &= ~(@intCast(u8, 1) << @intCast(u3, self.bits_in_last_byte));
        }
        self.bits_in_last_byte += 1;
    }
    pub fn clone(self: *const BitVector, allocator: std.mem.Allocator) !BitVector {
        var cloned = try std.ArrayList(u8).initCapacity(allocator, self.bits.capacity);
        cloned.appendSliceAssumeCapacity(self.bits.items);
        return BitVector{
            .bits_in_last_byte = self.bits_in_last_byte,
            .bits = cloned,
        };
    }
    pub fn reset(self: *BitVector) void {
        self.bits.shrinkAndFree(0);
        self.bits_in_last_byte = 0;
    }
    pub fn string(self: *const BitVector, allocator: std.mem.Allocator) ![]u8 {
        const n = self.len();
        var str = try allocator.alloc(u8, n + 2); // + 2 for the 0b prefix.
        str[0] = '0';
        str[1] = 'b';
        var i: usize = 0;
        while (i < n) : (i += 1) {
            str[i + 2] = if (self.getBit(i)) '1' else '0';
        }
        return str;
    }
};

test "Appending Onto Vector" {
    var alloc = std.testing.allocator;
    var vec = BitVector.init(alloc);
    defer vec.deinit();
    try vec.appendBit(true);
    try vec.appendBit(true);
    try vec.appendBit(true);
    try vec.appendBit(true);
    try vec.appendBit(false);
    try vec.appendBit(false);
    try vec.appendBit(false);
    try vec.appendBit(false);
    const str = try vec.string(alloc);
    defer alloc.free(str);
    try std.testing.expectEqualStrings("0b11110000", str);
    vec.reset();
    try vec.appendBit(true);
    try vec.appendBit(true);
    try vec.appendBit(true);
    try vec.appendBit(true);
    try vec.appendBit(true);
    try vec.appendBit(true);
    try vec.appendBit(true);
    try vec.appendBit(true);
    const str2 = try vec.string(alloc);
    defer alloc.free(str2);
    try std.testing.expectEqualStrings("0b11111111", str2);
}

test "Popping a vector" {
    var alloc = std.testing.allocator;
    var vec = BitVector.init(alloc);
    defer vec.deinit();
    try vec.appendBit(true);
    try vec.appendBit(true);
    try vec.appendBit(true);
    try vec.appendBit(true);
    try vec.appendBit(false);
    try vec.appendBit(false);
    try vec.appendBit(false);
    try vec.appendBit(false);
    try std.testing.expectEqual(false, vec.pop());
    try std.testing.expectEqual(false, vec.pop());
    try std.testing.expectEqual(false, vec.pop());
    try std.testing.expectEqual(false, vec.pop());
    const str = try vec.string(alloc);
    defer alloc.free(str);
    try std.testing.expectEqualStrings("0b1111", str);
    try std.testing.expectEqual(true, vec.pop());
    try std.testing.expectEqual(true, vec.pop());
    try std.testing.expectEqual(true, vec.pop());
    try std.testing.expectEqual(true, vec.pop());
    const str2 = try vec.string(alloc);
    defer alloc.free(str2);
    try std.testing.expectEqualStrings("0b", str2);
}
