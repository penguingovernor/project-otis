const std = @import("std");
const bitvector = @import("bitvector");

// Node is a Huffman node with an optional symbol.
// It contains how often that symbol was seen along with
// indexes to its left and right children.
pub const Node = struct {
    symbol: u8,
    frequency_count: usize,
    left_right_indexes: struct {
        left: i16,
        right: i16,
    },
    pub const null_idx = -1;
    pub const interior_node_symbol = '*';
};

// Tree represents a Huffman tree. It contains the nodes in a continuous
// chunk of memory. It also specifies which index is the root.
pub const Tree = struct {
    nodes: std.MultiArrayList(Node),
    root_idx: i16,
};

// createTree returns a Huffman tree or an allocation error.
// The allocator is used only to allocate space for the tree.
//
// The histogram is an array where the index is the byte value and its value is
// its frequency count.
pub fn createTree(
    allocator: std.mem.Allocator,
    histogram: *[256]u32,
) !Tree {
    // Create the tree.
    var tree = Tree{
        .nodes = std.MultiArrayList(Node){},
        .root_idx = undefined,
    };

    // Populate the storage with all the leaf symbols.
    // Add the leaves to the heap.
    var total_nodes: usize = 0;
    for (histogram) |count| {
        if (count == 0) {
            continue;
        }
        total_nodes += 1;
    }
    try tree.nodes.setCapacity(allocator, 2 * total_nodes - 1);
    for (histogram) |count, symbol| {
        if (count == 0) {
            continue;
        }
        tree.nodes.appendAssumeCapacity(Node{
            .symbol = @intCast(u8, symbol),
            .frequency_count = count,
            .left_right_indexes = .{
                .left = Node.null_idx,
                .right = Node.null_idx,
            },
        });
    }

    // Create the priority queue.
    // A Huffman tree will have 2N-1 node, where N is the possible number of
    // symbols. If we consider N=256, for all possible byte values, then the max
    // amount of nodes is 511. Since we only have store indexes (i16 == 2 bytes)
    // then 511*2= 1022 bytes. This should fit on the stack.
    var queue_buffer: [1022]u8 = undefined;
    var queue_buffer_fba = std.heap.FixedBufferAllocator.init(&queue_buffer);
    var queue_buffer_allocator = queue_buffer_fba.allocator();
    var heap = std.PriorityQueue(
        i16,
        HeapContext,
        HeapCompareFn,
    ).init(queue_buffer_allocator, HeapContext{
        .storage = &tree.nodes,
    });
    try heap.ensureTotalCapacity(2 * tree.nodes.len - 1);
    var i: i16 = 0;
    while (i < @intCast(i16, tree.nodes.len)) : (i += 1) {
        try heap.add(i);
    }

    // Pop two nodes off the heap and join them until only 1 node remains.
    // The remaining node is the root node.
    //
    // Add newly created interior nodes to the tree's storage.
    while (heap.len != 1) {
        const left = heap.remove();
        const right = heap.remove();
        var counts = tree.nodes.items(.frequency_count);
        tree.nodes.appendAssumeCapacity(Node{
            .left_right_indexes = .{
                .left = left,
                .right = right,
            },
            .symbol = Node.interior_node_symbol,
            .frequency_count = counts[@intCast(usize, left)] + counts[@intCast(usize, right)],
        });
        try heap.add(@intCast(i16, tree.nodes.len - 1));
    }
    tree.root_idx = heap.remove();
    return tree;
}

const HeapContext = struct { storage: *std.MultiArrayList(Node) };
fn HeapCompareFn(context: HeapContext, a: i16, b: i16) std.math.Order {
    const frequency_counts = context.storage.items(.frequency_count);
    return std.math.order(frequency_counts[@intCast(usize, a)], frequency_counts[@intCast(usize, b)]);
}

pub fn make_codes(
    tree: *const Tree,
    codes: *std.AutoArrayHashMap(u8, bitvector.BitVector),
) !void {
    var bv_buffer: [60]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&bv_buffer);
    var bv = bitvector.BitVector.init(fba.allocator());
    try make_codes_recursive(tree, tree.root_idx, codes, &bv);
}

fn make_codes_recursive(
    tree: *const Tree,
    root: i16,
    codes: *std.AutoArrayHashMap(u8, bitvector.BitVector),
    bv: *bitvector.BitVector,
) !void {
    // Base case.
    if (root == Node.null_idx) {
        return;
    }

    var node = tree.nodes.get(@intCast(usize, root));

    // Left
    try bv.appendBit(false);
    try make_codes_recursive(tree, node.left_right_indexes.left, codes, bv);
    _ = bv.pop();

    // Right
    try bv.appendBit(true);
    try make_codes_recursive(tree, node.left_right_indexes.right, codes, bv);
    _ = bv.pop();

    // Self.
    if (node.left_right_indexes.left == Node.null_idx and node.left_right_indexes.right == Node.null_idx) {
        var cloned = try bv.clone(codes.allocator);
        try codes.put(node.symbol, cloned);
    }
}
