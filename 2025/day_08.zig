test part1 {
    const example =
        \\162,817,812
        \\57,618,57
        \\906,360,560
        \\592,479,940
        \\352,342,300
        \\466,668,158
        \\542,29,236
        \\431,825,988
        \\739,650,466
        \\52,470,668
        \\216,146,977
        \\819,987,18
        \\117,168,530
        \\805,96,715
        \\346,949,466
        \\970,615,88
        \\941,993,340
        \\862,61,35
        \\984,92,344
        \\425,690,689
        \\
    ;
    const answer = 40;
    try testing.expectEqual(answer, try part1(example));
}


pub fn part1(input: []const u8) !usize {
    const pairs: []Pair = try pairsFromInput(input, &positions_buffer, &pairs_buffer);
    // We grow a list of pairs unordered, and sort them all at once at the end.
    std.mem.sort(Pair, pairs, {}, Pair.lessThanDistance);
    // Now, we can take the first *N* to have the *N* shortest pairs.

    // The example problem and actual problem
    // want a different number of connections.
    const connections_count = if (@import("builtin").is_test) 10 else 1000;
    const circuits: []Circuit = mergeToCircuits(pairs[0..connections_count], &circuit_buffer);

    // Get the largest circuits.
    std.mem.sort(Circuit, circuits, {}, struct {
        fn lessThanDesc(_: void, a: Circuit, b: Circuit) bool {
            // Sorts from greatest->least
            return a.count() > b.count();
        }
    }.lessThanDesc);

    return circuits[0].count() * circuits[1].count() * circuits[2].count();
}

const max_junctions = 1024;
var positions_buffer: [max_junctions]Position = undefined;
// I'm not really satisfied with this solution, but
// I cannot think of anything performant that does not incur the O(n^2) size complexity.
// We need to know all distances before we can identify the least distances.
// This is still only about 8 MB.
var pairs_buffer: [max_junctions*max_junctions]Pair = undefined;
// Finally, after sorting by distance over the pairs,
// we need to construct a dynamic list of index sets which represent the circuits.
// This is decently big, but not much additional to the pairs buffer.
var circuit_buffer: [max_junctions]Circuit = undefined;

/// Parse and grow the list of all possible connections.
fn pairsFromInput(input: []const u8, pos_buf: []Position, pair_buf: []Pair) ![]Pair {
    @memset(pos_buf, undefined);
    @memset(pair_buf, undefined);
    var positions_list: std.ArrayList(Position) = .{
        .items = pos_buf[0..0],
        .capacity = pos_buf.len,
    };
    var pairs_list: std.ArrayList(Pair) = .{
        .items = pair_buf[0..0],
        .capacity = pair_buf.len,
    };
    var line_iter = mem.splitScalar(u8, input, '\n');
    var positions_count: u10 = 0;
    while (line_iter.next()) |line| {
        if (line.len == 0) continue;
        const position = positionFromString(line) catch |err| {
            if (debug_build)
                std.log.err("{t} while parsing line: \"{s}\"", .{ err, line });
            return error.ParseFailure;
        };
        var i: u10 = 0; // because zig for with idx always uses usize
        const new_i: u10 = positions_count;
        for (positions_list.items) |prev_position| {
            // The distances buffer is exactly the square size of the positions buffer,
            // so this will always fit.
            pairs_list.appendAssumeCapacity(.{
                .distance = squareDistance(position, prev_position),
                .junctions = .{ i, new_i },
            });
            i += 1;
        }
        try positions_list.appendBounded(position);
        positions_count += 1; // because zig slice len is always usize
    }
    return pairs_list.items;
}

/// There are much more optimal ways to merge lists of sets
/// (this is worst case O(n^3), I think)
/// but I'm out of time for today.
fn mergeToCircuits(connections: []const Pair, circuit_buf: []Circuit) []Circuit {
    @memset(circuit_buf, undefined);
    assert(circuit_buf.len >= connections.len);
    var circuit_list: std.ArrayList(Circuit) = .{
        .items = circuit_buf[0..connections.len],
        .capacity = circuit_buf.len,
    };

    const empty: Circuit = .initEmpty();

    // Initialize the list with each junction being its own circuit.
    for (circuit_list.items, connections) |*circuit, connection| {
        circuit.* = empty;
        circuit.setValue(connection.junctions[0], true);
        circuit.setValue(connection.junctions[1], true);
    }

    // Reverse iteration
    var i: usize = circuit_list.items.len;
    outer: while (i != 0) {
        i -= 1;
        var j: usize = circuit_list.items.len;
        while (j != 0) {
            j -= 1;
            // If circuit *i* shares junctions with other circuit *j*
            if (j!=i and !Circuit.eql(empty, Circuit.intersectWith(
                circuit_list.items[i],
                circuit_list.items[j],
            ))) {
                // Merge *j* into *i*, and start again from the top
                circuit_list.items[i].setUnion(circuit_list.items[j]);
                _ = circuit_list.swapRemove(j);
                i = circuit_list.items.len-1;
                continue :outer;
            }
        }
    }
    // We iterated through without seeing any possible merges

    return circuit_list.items;
}

/// Sum square difference of position is the same ordering as
/// square root of sum square difference of position (Euclidean distance).
/// Square roots are expensive and not necessary.
fn squareDistance(a: Position, b: Position) f32 {
    const d = b-a;
    return @reduce(.Add, d*d);
}

fn positionFromString(coord: []const u8) !Position {
    const first, const tail = mem.cutScalar(u8, coord, ',') orelse return error.MissingDelimiter;
    const second, const third = mem.cutScalar(u8, tail, ',') orelse return error.MissingDelimiter;
    return @floatFromInt(@Vector(3, u32){
        try fmt.parseUnsigned(u32, first, 10),
        try fmt.parseUnsigned(u32, second, 10),
        try fmt.parseUnsigned(u32, third, 10),
    });
}

const Position = @Vector(3, f32);
/// What is actually needed from each possible junction pair is
/// its distance for ordering, which we can keep as a scalar,
/// and the original indices of the junctions for circuit identification.
const Pair = struct {
    distance: f32,
    junctions: [2]Index,
    const Index = u10;
    // Assert that this index pair is not overflowed by the buffer size
    comptime { assert(math.maxInt(Index)+1 >= max_junctions); }

    pub fn lessThanDistance(_: void, a: Pair, b: Pair) bool {
        return a.distance < b.distance;
    }
};
const Circuit = std.bit_set.ArrayBitSet(usize, max_junctions);

const debug_build = @import("builtin").mode==.Debug;
const assert = std.debug.assert;
const testing = std.testing;
const math = std.math;
const fmt = std.fmt;
const mem = std.mem;
const std = @import("std");
