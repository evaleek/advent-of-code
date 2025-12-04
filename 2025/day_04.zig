pub const part1 = part1Double;

test part1 {
    const example_input =
        \\..@@.@@@@.
        \\@@@.@.@.@@
        \\@@@@@.@.@@
        \\@.@@@@..@.
        \\@@.@@@@.@@
        \\.@@@@@@@.@
        \\.@.@.@.@@@
        \\@.@@@.@@@@
        \\.@@@@@@@@.
        \\@.@.@@@.@.
        \\
    ;
    const example_answer = 13;
    try testing.expectEqual(example_answer, part1(example_input));
}

pub fn part1Double(input: []const u8) !u16 {
    const init_adjacency: i8 = 4;
    // Input is runtime-known, but we don't want to do heap allocations
    var adjacency_buffer: [32768]i8 = @splat(init_adjacency);
    if (input.len > adjacency_buffer.len) return error.InputOverflow;

    const adjacencies: []i8 = adjacency_buffer[0..input.len];
    assert(input[0] != '\n');
    const line_diff = ( mem.findScalarPos(u8, input, 0, '\n')
        orelse return error.InputInvalid ) + 1;

    for (input, 0..) |input_char, index| { switch (input_char) {
        else => {
            // Now this cell's adjacency count will never make it into the total,
            // and we don't have to check for it later.
            adjacencies[index] = -1;
        },

        '@' => {
            // Decrement the previous and next cells of this line.
            if (index != 0) adjacencies[index-1] -= 1;
            adjacencies[index+1] -= 1;

            // If this is not the first line,
            // decrement the three cells of the previous line.
            if (math.sub(usize, index, line_diff)) |index_prev_line| {
                if (index_prev_line != 0) adjacencies[index_prev_line-1] -= 1;
                adjacencies[index_prev_line] -= 1;
                adjacencies[index_prev_line+1] -= 1;
            } else |_| {}

            // Do the same for the next line, if this is not the last.
            const index_next_line = index + line_diff;
            if (index_next_line < input.len) {
                adjacencies[index_next_line-1] -= 1;
                adjacencies[index_next_line] -= 1;
                adjacencies[index_next_line+1] -= 1;
            }
        },
    }}

    var total: u16 = 0;
    for (adjacencies) |adjacency| total += @intFromBool( adjacency > 0 );

    return total;
}

test "line diff is line length plus one" {
    const example =
        \\fou
        \\bar
        \\
    ;

    const line_len = 3;
    const line_diff = line_len + 1;

    const a_index = mem.findScalarPos(u8, example, 0, 'a') orelse return error.IndexNotFound;
    const o_index = mem.findScalarPos(u8, example, 0, 'o') orelse return error.IndexNotFound;
    const f_index = mem.findScalarPos(u8, example, 0, 'f') orelse return error.IndexNotFound;

    try testing.expectEqual(o_index, a_index - line_diff);
    try testing.expectEqual(f_index, a_index - line_diff - 1);
    try testing.expectEqual(a_index, o_index + line_diff);
}

const assert = std.debug.assert;
const testing = std.testing;
const math = std.math;
const mem = std.mem;
const std = @import("std");
