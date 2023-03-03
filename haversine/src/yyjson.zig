const yyjson = @cImport({
    @cInclude("yyjson.h");
});
const std = @import("std");

const JsonValue = [*c]yyjson.yyjson_val;

pub const JsonError = error{
    ReadFileError,
    IterInitFailed,
    NoSuchKey,
};

fn getFloatFromObject(obj: JsonValue, key: [:0]const u8) !f64 {
    const num: JsonValue = yyjson.yyjson_obj_get(obj, key);
    if (num == 0) {
        std.log.err("No such key: \"{s}\"\n", .{key});
        return JsonError.NoSuchKey;
    }
    return yyjson.yyjson_get_real(num.?);
}

pub const LatLongIter = struct {
    const buffer_size = 256;
    const Entry = struct { x0: f64, y0: f64, x1: f64, y1: f64 };
    buffer: std.ArrayList(Entry),
    array_iter: yyjson.yyjson_arr_iter,

    fn fillBuffer(self: *LatLongIter) !usize {
        var total: usize = 0;
        while (self.buffer.items.len < LatLongIter.buffer_size) {
            const entry: JsonValue = yyjson.yyjson_arr_iter_next(&self.array_iter);
            if (entry == 0) {
                break;
            }
            self.buffer.appendAssumeCapacity(Entry{
                .x0 = try getFloatFromObject(entry.?, "x0"),
                .y0 = try getFloatFromObject(entry.?, "y0"),
                .x1 = try getFloatFromObject(entry.?, "x1"),
                .y1 = try getFloatFromObject(entry.?, "y1"),
            });
            total += 1;
        }
        return total;
    }

    fn init(allocator: std.mem.Allocator, arr: [*c]yyjson.yyjson_val) !LatLongIter {
        var v: LatLongIter = undefined;
        v.buffer = try std.ArrayList(Entry).initCapacity(allocator, LatLongIter.buffer_size);
        if (!yyjson.yyjson_arr_iter_init(arr, &v.array_iter)) {
            return JsonError.IterInitFailed;
        }
        return v;
    }

    pub fn next(self: *LatLongIter) !?Entry {
        if (self.buffer.items.len == 0) {
            const n = try self.fillBuffer();
            if (n == 0) {
                return null;
            }
        }
        return self.buffer.pop();
    }
};

pub fn getDoc(filename: [:0]const u8) ![*c]yyjson.yyjson_doc {
    // Setup reading the json.
    const flags: yyjson.yyjson_read_flag = yyjson.YYJSON_READ_NOFLAG;
    var err: yyjson.yyjson_read_err = undefined;

    // Read the file.
    var doc = yyjson.yyjson_read_file(
        filename,
        flags,
        null, // =allocator
        &err,
    );

    // Check for errors.
    if (doc == 0) {
        std.log.err("read error ({d}): {s} at position: {d}\n", .{ err.code, err.msg, err.pos });
        return JsonError.ReadFileError;
    }

    return doc.?;
}

pub fn getEntryIter(allocator: std.mem.Allocator, doc: [*c]yyjson.yyjson_doc) !LatLongIter {
    const root = yyjson.yyjson_doc_get_root(doc);
    const pairs: [*c]yyjson.yyjson_val = yyjson.yyjson_obj_get(root, "pairs");
    if (pairs == 0) {
        std.log.err("No such key \"{s}\" was found in JSON root\n", .{"pairs"});
        return JsonError.NoSuchKey;
    }
    return LatLongIter.init(allocator, pairs.?);
}

pub fn freeDoc(doc: [*c]yyjson.yyjson_doc) void {
    yyjson.yyjson_doc_free(doc);
}
