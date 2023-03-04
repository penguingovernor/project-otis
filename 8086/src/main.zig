const std = @import("std");

const ParseError = error{
    FailedToRead,
    UnknownOpCode,
    NonSupportedFunction,
};

pub fn main() !void {
    // Setup allocations.
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Read from stdin and write to stdout.
    var stdin = std.io.getStdIn();
    var rd = std.io.bufferedReader(stdin.reader());
    var stdout = std.io.getStdOut();
    var wt = std.io.bufferedWriter(stdout.writer());

    // Write the header.
    _ = try wt.write("bits 16\n\n");

    // Read in 2 byte at a time.
    var command_buffer: [2]u8 = undefined;

    // Some constants to make our life easier.
    const mv_op: u8 = 0b100010;
    const reg_to_reg = 0b011;
    const reg_table = [2][8]*const [2:0]u8{
        [8]*const [2:0]u8{ "al", "cl", "dl", "bl", "ah", "ch", "dh", "bh" },
        [8]*const [2:0]u8{ "ax", "cx", "dx", "bx", "sp", "bp", "si", "di" },
    };

    while (true) {
        // Try to read 2 bytes, give up if we couldn't read them.
        const bytes_read = try rd.read(&command_buffer);
        if (bytes_read == 0) {
            break;
        }
        if (bytes_read != 2) {
            std.log.err(
                "failed to read exactly 2 bytes, got {d} bytes instead\n",
                .{bytes_read},
            );
            return ParseError.FailedToRead;
        }

        // Decode the MOV opcode.
        const opcode = (command_buffer[0] >> 2) & (0x3F);
        const d = (command_buffer[0] >> 1) & 0x01;
        _ = d;
        const w = (command_buffer[0]) & 0x01;
        const mod = (command_buffer[1] >> 6) & 0x03;
        const reg = (command_buffer[1] >> 3) & 0x07;
        const rM = (command_buffer[1]) & 0x07;

        // Assert only MOV.
        if (opcode != mv_op) {
            std.log.err("unknown opcode {x}\n", .{opcode});
            return ParseError.UnknownOpCode;
        }
        // Assert only reg to reg.
        if (mod != reg_to_reg) {
            std.log.err("parser does not support non reg to reg operations\n", .{});
            std.log.err("got {x} wanted {x}\n", .{ mod, reg_to_reg });
            return ParseError.NonSupportedFunction;
        }

        // RM field is dest
        // Reg field is source
        const dest = reg_table[w][rM];
        const src = reg_table[w][reg];

        // Write data out.
        const str = try std.fmt.allocPrint(allocator, "mov {s},{s}\n", .{ dest, src });
        _ = try wt.write(str);
    }
    _ = try wt.flush();
}
